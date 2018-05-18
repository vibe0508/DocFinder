//
//  OperationStep.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 05/06/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class OperationStep<In, Out, Operation: StepOperation<In, Out>>: FlowStep {

    typealias Input = In
    typealias Output = Out
    
    typealias ResultGetter = (Output?) -> ()
    typealias InputBlock = (@escaping (Input?) -> ()) -> ()

    private let operationQueue = OperationQueue()
    private let dispatchQueue = DispatchQueue(label: "")
    private let fillingQueue = DispatchQueue(label: "")

    private var dataProvider: InputBlock!
    private var resultConsumer: ((Output) -> ())?

    private var buffer: [Output] = []
    private var operationsCount = 0
    private var enquedGetters: [ResultGetter] = []
    private var isFinished = false

    init() {
        operationQueue.underlyingQueue = .global(qos: .background)
        operationQueue.maxConcurrentOperationCount = 3
    }

    func start() {
        iterateRequestMore()
    }

    func then<NextStep: FlowStep>(_ nextStep: NextStep) -> NextStep where Out == NextStep.Input {
        return nextStep.start(with: self)
    }

    func start<T: DataProvider>(with dataProvider: T) -> Self where T.Output == Input {
        self.dataProvider = dataProvider.pickData
        start()
        return self
    }

    func stop() {
        dispatchQueue.async {
            self.finish()
        }
    }

    func consumeResults(_ consumeBlock: @escaping (Out) -> ()) {
        dispatchQueue.async {
            self.resultConsumer = consumeBlock
        }
    }

    private func requestMoreInput() {
        guard buffer.count + operationsCount < 5 else {
            return
        }
        fillingQueue.async {
            self.iterateRequestMore()
        }
    }

    private func iterateRequestMore() {
        let (bufferLength, operationsCount) = dispatchQueue.sync { (buffer.count, self.operationsCount) }

        guard bufferLength + operationsCount < 5 else {
            return
        }

        let group = DispatchGroup()
        group.enter()
        dataProvider { input in
            self.dispatchQueue.sync {
                if let input = input {
                    self.addOperation(with: input)
                } else {
                    self.finish()
                }
            }
            group.leave()
        }

        group.wait()
        iterateRequestMore()
    }

    private func addOperation(with input: Input) {
        operationsCount += 1
        let operation = Operation(input: input, outputQueue: dispatchQueue) { [unowned self] (output) in
            self.buffer.append(output)
            self.resultConsumer?(output)
            self.operationsCount -= 1
            self.fullfillEnquedGetters()
            self.requestMoreInput()
        }
        operationQueue.addOperation(operation)
    }

    private func fullfillEnquedGetters() {
        while let getter = enquedGetters.last, let outputItem = buffer.last {
            getter(outputItem)
            _ = enquedGetters.popLast()
            _ = buffer.popLast()
        }
    }

    private func finish() {
        guard !isFinished else {
            return
        }

        isFinished = true
        enquedGetters.forEach { $0(nil) }
        enquedGetters = []
    }

    private func getFromBuffer(_ getter: @escaping ResultGetter) {
        if let existingValue = buffer.popLast() {
            getter(existingValue)
            return
        }

        guard !isFinished else {
            getter(nil)
            return
        }

        enquedGetters.append(getter)
    }
}

extension OperationStep: DataProvider {
    func pickData(_ callback: @escaping (Output?) -> ()) {
        getFromBuffer(callback)
    }
}

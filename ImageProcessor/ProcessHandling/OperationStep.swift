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
    private var dataProviderIsEmpty = false

    init() {
        operationQueue.underlyingQueue = .global(qos: .background)
        operationQueue.maxConcurrentOperationCount = 3
    }

    func start() {
        requestMoreInput()
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

        guard !dispatchQueue.sync(execute: { dataProviderIsEmpty }) else {
            return
        }

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
                    self.dataProviderIsEmpty = true
                }
            }
            group.leave()
        }

        group.wait()

        if dispatchQueue.sync(execute: { !isFinished }) {
            fillingQueue.async(execute: iterateRequestMore)
        }
    }

    private func addOperation(with input: Input) {
        operationsCount += 1
        let operation = Operation(input: input, outputQueue: dispatchQueue, outputHandler: { [weak self] (output) in
            self?.handleOperation(output)
        }, errorHandler: { [weak self] error in
            self?.handleOperation(error)
        })
        operationQueue.addOperation(operation)
    }

    private func fullfillEnquedGetters() {
        while let getter = enquedGetters.last, let outputItem = buffer.last {
            getter(outputItem)
            _ = enquedGetters.popLast()
            _ = buffer.popLast()
        }
    }

    private func handleOperation(_ result: Output) {
        operationsCount -= 1

        if let resultConsumer = resultConsumer {
            resultConsumer(result)
        } else {
            buffer.append(result)
            fullfillEnquedGetters()
        }

        if !dataProviderIsEmpty {
            requestMoreInput()
        } else if operationsCount <= 0 {
            finish()
        }
    }

    private func handleOperation(_ error: Error?) {
        operationsCount -= 1
        fullfillEnquedGetters()

        if !dataProviderIsEmpty {
            requestMoreInput()
        } else if operationsCount <= 0 {
            finish()
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

//
//  MappingStep.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 05/06/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class MappingStep<In, Out>: FlowStep {

    typealias Input = In
    typealias Output = Out

    private let converter: (Input) -> Output
    private let queue = DispatchQueue(label: "")
    private var isStopped = false
    private var buffer: [Output] = []
    private var queuedCallbacks: [(Output?) -> ()] = []
    private var resultConsumer: ((Output) -> ())?

    init(_ converter: @escaping (Input) -> Output) {
        self.converter = converter
    }

    func start<T: DataProvider>(with dataProvider: T) -> Self where Input == T.Output {
        pickData(from: dataProvider)
        return self
    }

    func consumeResults(_ consumeBlock: @escaping (Output) -> ()) {
        queue.async {
            self.resultConsumer = consumeBlock
        }
    }

    func stop() {
        isStopped = true
    }

    func then<NextStep: FlowStep>(_ nextStep: NextStep) -> NextStep where NextStep.Input == Output {
        return nextStep.start(with: self)
    }

    private func pickData<T: DataProvider>(from dataProvider: T) where Input == T.Output {
        dataProvider.pickData { [weak self] in
            guard let input = $0 else {
                self?.queue.async { self?.stop() }
                return
            }
            self?.queue.async { self?.convert(input) }
        }
    }

    private func convert(_ input: Input) {
        let output = converter(input)

        if let callback = queuedCallbacks.popLast() {
            callback(output)
        } else {
            buffer.append(output)
        }
    }
}

extension MappingStep {
    func pickData(_ callback: @escaping (Output?) -> ()) {
        queue.async {
            guard !self.isStopped else {
                callback(nil)
                return
            }
            if let buffredResult = self.buffer.popLast() {
                callback(buffredResult)
            } else {
                self.queuedCallbacks.append(callback)
            }
        }
    }
}

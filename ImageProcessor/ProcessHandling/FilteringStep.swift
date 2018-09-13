//
//  FilteringStep.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 06/06/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class FilteringStep<T>: FlowStep {

    typealias Input = T
    typealias Output = T

    private let filter: (T) -> Bool
    private let queue = DispatchQueue(label: "")
    private var isStopped = false
    private var buffer: [Output] = []
    private var queuedCallbacks: [(Output?) -> ()] = []
    private var resultConsumer: ((Output) -> ())?

    init(_ filter: @escaping (T) -> Bool) {
        self.filter = filter
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
            self?.queue.async {
                self?.process(input)
                if self?.isStopped == false {
                    self?.pickData(from: dataProvider)
                }
            }
        }
    }

    private func process(_ input: Input) {
        guard filter(input) else {
            return
        }

        resultConsumer?(input)
        if let resultConsumer = resultConsumer {
            resultConsumer(input)
        } else if let callback = queuedCallbacks.popLast() {
            callback(input)
        } else {
            buffer.append(input)
        }
    }
}

extension FilteringStep {
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


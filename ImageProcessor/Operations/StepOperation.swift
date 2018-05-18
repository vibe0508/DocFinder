//
//  StepOperation.swift
//  ImageProcessor
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class StepOperation<Input, Output>: Operation {

    typealias OutputHandler = (Output) -> ()

    private var _isFinished = false {
        didSet {
            didChangeValue(for: \StepOperation.isFinished)
        }
        willSet {
            willChangeValue(for: \StepOperation.isFinished)
        }
    }
    private var _isExecuting = false {
        didSet {
            didChangeValue(for: \StepOperation.isExecuting)
        }
        willSet {
            willChangeValue(for: \StepOperation.isExecuting)
        }
    }

    private let outputHandler: OutputHandler
    private let outputHandlingQueue: DispatchQueue

    var input: Input

    override var isAsynchronous: Bool {
        return true
    }
    override var isFinished: Bool {
        set {
            _isFinished = newValue
        }
        get {
            return _isFinished
        }
    }
    override var isExecuting: Bool {
        set {
            _isExecuting = newValue
        }
        get {
            return _isExecuting
        }
    }

    required init(input: Input, outputQueue: DispatchQueue, outputHandler: @escaping OutputHandler) {
        self.input = input
        self.outputHandlingQueue = outputQueue
        self.outputHandler = outputHandler
    }

    func finish(with result: Output) {
        outputHandlingQueue.sync {
            outputHandler(result)
        }
        isExecuting = false
        isFinished = true
    }
}

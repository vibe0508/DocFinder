//
//  StepOperation.swift
//  ImageProcessor
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

public class StepOperation<Input, Output>: Operation {

    public typealias OutputHandler = (Output) -> ()
    public typealias ErrorHandler = (Error?) -> ()

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
    private let errorHandler: ErrorHandler
    private let outputHandlingQueue: DispatchQueue

    var input: Input

    override public  var isAsynchronous: Bool {
        return true
    }
    override public  var isFinished: Bool {
        set {
            _isFinished = newValue
        }
        get {
            return _isFinished
        }
    }
    override public  var isExecuting: Bool {
        set {
            _isExecuting = newValue
        }
        get {
            return _isExecuting
        }
    }

    required init(input: Input, outputQueue: DispatchQueue,
                  outputHandler: @escaping OutputHandler, errorHandler: @escaping ErrorHandler) {
        self.input = input
        self.outputHandlingQueue = outputQueue
        self.outputHandler = outputHandler
        self.errorHandler = errorHandler
    }

    public func finish(with result: Output) {
        outputHandlingQueue.sync {
            outputHandler(result)
        }
        isExecuting = false
        isFinished = true
    }

    public func fail(with error: Error?) {
        outputHandlingQueue.sync {
            errorHandler(error)
        }
        isExecuting = false
        isFinished = true
    }
}

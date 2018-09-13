//
//  ViewController.swift
//  DocFinder
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import UIKit
import Vision
import CoreML
import ImageProcessor
import Photos


let lock = NSRecursiveLock()
var _n: Int = 0

var n: Int {
    set {
        lock.lock()
        _n = newValue
        lock.unlock()
    }
    get {
        return _n
    }
}

class ProcessOperation: Operation {

    let asset: PHAsset
    let successHandler: (PHAsset) -> ()
    let manager: PHImageManager

    private var _isFinished = false {
        didSet {
            didChangeValue(for: \ProcessOperation.isFinished)
        }
        willSet {
            willChangeValue(for: \ProcessOperation.isFinished)
        }
    }
    private var _isExecuting = false {
        didSet {
            didChangeValue(for: \ProcessOperation.isExecuting)
        }
        willSet {
            willChangeValue(for: \ProcessOperation.isExecuting)
        }
    }

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

    init(asset: PHAsset, manager: PHImageManager, successHandler: @escaping (PHAsset) -> ()) {
        self.asset = asset
        self.successHandler = successHandler
        self.manager = manager
    }

    override func start() {
        _isExecuting = true
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false
        manager.requestImage(for: asset, targetSize: CGSize(width: 299, height: 299),
                             contentMode: .aspectFill,
                             options: options) { [weak self] (image, _) in
                                if let image = image.flatMap({ CIImage(image: $0) }) {
                                    self?.processImage(image)
                                } else {
                                    self?.finish()
                                }
        }
    }

    private func processImage(_ image: CIImage) {
        do {
            let request = try prepareRequest()
            let handler = VNImageRequestHandler(ciImage: image,
                                                orientation: .up)
            try handler.perform([request])
        } catch {
            print(error)
            finish()
        }
    }

    private func prepareRequest() throws -> VNCoreMLRequest {
        let model = try VNCoreMLModel(for: ImageClassifier().model)

        let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            return
        }
        print(results.first(where: { $0.identifier == "passport_rf_home" })?.confidence ?? 0)
        if results.contains(where: { $0.identifier == "passport_rf_home" && $0.confidence > 0.8 }) {
            successHandler(asset)
        }
        finish()
    }

    private func finish() {
        n += 1
        print("Operation finished \(n)")
        _isExecuting = false
        _isFinished = true
    }
}

class ViewController: UIViewController {

    var processor: FinderSession!

    let manager = PHImageManager()
    let assetsRetriever = AssetsRetriever()
    let operationQueue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        operationQueue.underlyingQueue = .global(qos: .userInitiated)
        operationQueue.maxConcurrentOperationCount = 5

        assetsRetriever.retrieveAssetsList(success: { [manager, operationQueue] (assets) in
            operationQueue.addOperations(assets.map {
                ProcessOperation(asset: $0, manager: manager, successHandler: { _ in print("Ura!!!")})
            }, waitUntilFinished: false)
        }, failure: { _ in

        })


        
//        processor = FinderSession(model: ImageClassifier().model,
//                                  searchClass: "passport_rf_home",
//                                  resultCallback: { print($0) },
//                                  finishedCallback: { print("finished") })
//        processor.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


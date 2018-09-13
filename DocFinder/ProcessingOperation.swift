//
//  ProcessingOperation.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos
import CoreML
import Vision

class ProcessingOperation: Operation {

    let asset: PHAsset
    let imageManager: PHImageManager
    let model: MLModel
    private let successHandler: (PHAsset) -> ()

    private var _isFinished = false {
        didSet {
            didChangeValue(for: \ProcessingOperation.isFinished)
        }
        willSet {
            willChangeValue(for: \ProcessingOperation.isFinished)
        }
    }
    private var _isExecuting = false {
        didSet {
            didChangeValue(for: \ProcessingOperation.isExecuting)
        }
        willSet {
            willChangeValue(for: \ProcessingOperation.isExecuting)
        }
    }

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

    init(asset: PHAsset, model: MLModel, imageManager: PHImageManager, successHandler: @escaping (PHAsset) -> ()) {
        self.asset = asset
        self.model = model
        self.successHandler = successHandler
        self.imageManager = imageManager
    }

    override func start() {
        _isExecuting = true
        fetchImage()
    }

    private func fetchImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false
        imageManager.requestImage(for: asset, targetSize: CGSize(width: 299, height: 299),
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

    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            return
        }
        if results.contains(where: { $0.identifier == "passport_rf_home" && $0.confidence > 0.8 }) {
            successHandler(asset)
        }
        finish()
    }

    private func finish() {
        _isExecuting = false
        _isFinished = true
    }
}

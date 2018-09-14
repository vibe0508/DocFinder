//
//  ProcessingOperation.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos
import Vision

class ProcessingOperation: Operation {

    let docType: DocumentType
    let asset: PHAsset
    let imageManager: PHImageManager
    let model: VNCoreMLModel
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

    init(docType: DocumentType, asset: PHAsset, model: VNCoreMLModel, imageManager: PHImageManager, successHandler: @escaping (PHAsset) -> ()) {
        self.docType = docType
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
                                    DispatchQueue.global(qos: .background).async {
                                        self?.processImage(image)
                                    }
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
        if results
            .contains(where: {
                $0.identifier == docType.classIdentifier
                    && $0.confidence > docType.acceptableConfidence
            }) {
            successHandler(asset)
        }
        finish()
    }

    private func finish() {
        _isExecuting = false
        _isFinished = true
    }
}

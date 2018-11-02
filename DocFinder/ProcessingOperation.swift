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

extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        }
    }
}

class ProcessingOperation: Operation {

    private struct State: OptionSet {

        var rawValue: Int

        typealias RawValue = Int

        static let detectionCompleted = State(rawValue: 2)
        static let classificationCompleted = State(rawValue: 4)
        static let error = State(rawValue: 8)
        static let empty = State(rawValue: 0)
    }

    let docType: DocumentType
    let asset: PHAsset
    let imageManager: PHImageManager
    let detectionModel: VNCoreMLModel
    let classificationModel: VNCoreMLModel
    private let successHandler: (PHAsset) -> ()

    private var detectionSucceed = false
    private var classificationSucceed = false
    private var state: State = .empty {
        didSet {
            if (state.contains(.detectionCompleted) && state.contains(.classificationCompleted))
                || state.contains(.error) {
                if detectionSucceed && classificationSucceed { successHandler(asset) }
                finish()
            }
        }
    }

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

    init(docType: DocumentType, asset: PHAsset, detectionModel: VNCoreMLModel, classificationModel: VNCoreMLModel, imageManager: PHImageManager, successHandler: @escaping (PHAsset) -> ()) {
        self.docType = docType
        self.asset = asset
        self.detectionModel = detectionModel
        self.classificationModel = classificationModel
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
                                if let ciImage = image.flatMap({ CIImage(image: $0) }),
                                    let orientation = image?.cgOrientation {
                                    DispatchQueue.global(qos: .background).async {
                                        self?.detectFaceIfNeeded(on: ciImage,
                                                                 orientation: orientation)
                                    }
                                } else {
                                    self?.finish()
                                }
        }
    }

    private func detectFaceIfNeeded(on image: CIImage, orientation: CGImagePropertyOrientation) {
        guard docType.needsFace else {
            processImage(image, orientation: orientation)
            return
        }
        let request = VNDetectFaceRectanglesRequest { [weak self] (request, _) in
            if request.results?.first(where: { $0 is VNFaceObservation }) != nil {
                self?.processImage(image, orientation: orientation)
            } else {
                self?.finish()
            }
        }
        do {
            let handler = VNImageRequestHandler(ciImage: image,
                                                orientation: orientation)
            try handler.perform([request])
        } catch {
            print(error)
            state.insert(.error)
        }
    }

    private func processImage(_ image: CIImage, orientation: CGImagePropertyOrientation) {
        do {
            let classification = try prepareClassificationRequest()
            let detection = try prepareDetectionRequest()
            let handler = VNImageRequestHandler(ciImage: image,
                                                orientation: orientation)
            try handler.perform([classification, detection])
        } catch {
            print(error)
            finish()
        }
    }

    private func prepareClassificationRequest() throws -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: classificationModel, completionHandler: { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    private func prepareDetectionRequest() throws -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: detectionModel, completionHandler: { [weak self] request, error in
            self?.processDetection(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            state.insert(.error)
            return
        }
        classificationSucceed = results
            .contains(where: {
                $0.identifier == docType.classIdentifier
                    && $0.confidence > docType.acceptableConfidence
            })
        print(results.map { "\($0.identifier) - \($0.confidence)" })
        state.insert(.classificationCompleted)
    }

    private func processDetection(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            state.insert(.error)
            return
        }
        detectionSucceed = results
            .contains(where: {
                $0.identifier == "doc"
                    && $0.confidence > 0.85
            })
        print(results.map { "\($0.identifier) - \($0.confidence)" })
        state.insert(.detectionCompleted)
    }

    private func finish() {
        _isExecuting = false
        _isFinished = true
    }
}

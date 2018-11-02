//
//  FinderSession.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos
import ImageProcessor
import Vision

class FinderSession {

    let docType: DocumentType

    private let assetHandler: (PHAsset) -> ()
    private let completionHandler: () -> ()

    private let operationQueue = OperationQueue()
    private let assetsRetriever = AssetsRetriever()

    private let classificationModel = try! VNCoreMLModel(for: DocsClassifier().model)
    private let detectionModel = try! VNCoreMLModel(for: DocDetector().model)
    private let imageManager = PHCachingImageManager()

    init(docType: DocumentType, assetHandler: @escaping (PHAsset) -> (), completionHandler: @escaping () -> ()) {

        self.assetHandler = assetHandler
        self.completionHandler = completionHandler
        self.docType = docType

        operationQueue.maxConcurrentOperationCount = 5
        operationQueue.underlyingQueue = .global(qos: .background)
    }

    func start() {
        assetsRetriever.retrieveAssetsList(success: { [weak self] (assets) in
            self?.process(assets)
        }, failure: { _ in
        })
    }

    private func process(_ assets: [PHAsset]) {
        let completionOperation = BlockOperation(block: completionHandler)
        assets.forEach {
            let operation = ProcessingOperation(docType: docType,
                                                asset: $0,
                                                detectionModel: detectionModel,
                                                classificationModel: classificationModel,
                                                imageManager: imageManager,
                                                successHandler: assetHandler)
            completionOperation.addDependency(operation)
            operationQueue.addOperation(operation)
        }
        operationQueue.addOperation(completionOperation)
    }
}

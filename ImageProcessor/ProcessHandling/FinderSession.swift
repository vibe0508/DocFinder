//
//  FinderSession.swift
//  ImageProcessor
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos

private typealias LoadStep = OperationStep<PHAsset, Data, LoadOperation>
private typealias PrepareStep = OperationStep<Data, Data, PrepareOperation>
private typealias ProcessStep = OperationStep<ProcessingInput, ProcessingOutput, ProcessingOperation>

public class FinderSession {
    public typealias ResultCallback = (SearchResultPiece) -> ()
    public typealias FinishedCallback = () -> ()
    
    private let resultCallback: ResultCallback
    private let finishedCallback: FinishedCallback
    private let searchClass: String
    
    private let assetsRetriever: AssetsRetrieverProtocol = AssetsRetriever()

    public init(searchClass: String,
                resultCallback: @escaping ResultCallback,
                finishedCallback: @escaping FinishedCallback) {
        self.resultCallback = resultCallback
        self.finishedCallback = finishedCallback
        self.searchClass = searchClass
    }

    public func start() {
        assetsRetriever.retrieveAssetsList(success: { [weak self] (assets) in
            self?.handle(assets)
        }, failure: {
            print($0)
        })
    }
    
    public func stop() {
        
    }

    private func handle(_ assets: [PHAsset]) {
        let dataProvider = ArrayDataProvider(assets)
        let imageGetStep = LoadStep()
        let prepareStep = PrepareStep()
        let processStep = ProcessStep()
        imageGetStep.start(with: dataProvider).then(prepareStep).then(MappingStep {
            ProcessingInput(imageData: $0, modelName: "")
        }).then(processStep).then(FilteringStep { [searchClass] in
            $0.predictions.contains(where: { $0.0 == searchClass && $0.1 > 0.85 })
        }).consumeResults {
            print($0)
        }
    }
    
    
}

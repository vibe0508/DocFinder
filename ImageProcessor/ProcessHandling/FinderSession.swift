//
//  FinderSession.swift
//  ImageProcessor
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos
import CoreML

private typealias LoadStep = OperationStep<PHAsset, Data, LoadOperation>
private typealias PrepareStep = OperationStep<Data, Data, PrepareOperation>
private typealias ProcessStep = OperationStep<ProcessingInput, ProcessingOutput, ProcessingOperation>

//var global: (Int, Int, Int) = (0, 0, 0)

public class FinderSession {
    public typealias ResultCallback = (SearchResultPiece) -> ()
    public typealias FinishedCallback = () -> ()
    
    private let resultCallback: ResultCallback
    private let finishedCallback: FinishedCallback
    private let searchClass: String
    private let model: MLModel

    private var resultingStep: Any?//FilteringStep<ProcessingOutput>?
    
    private let assetsRetriever: AssetsRetrieverProtocol = AssetsRetriever()

    public init(model: MLModel,
                searchClass: String,
                resultCallback: @escaping ResultCallback,
                finishedCallback: @escaping FinishedCallback) {
        self.resultCallback = resultCallback
        self.finishedCallback = finishedCallback
        self.searchClass = searchClass
        self.model = model
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

        var i = 0
        var j = 0

        let filteringStep = imageGetStep.then(prepareStep).then(MappingStep { [model] in
            j += 1
            print("j: \(j)")
            return ProcessingInput(imageData: $0, model: model)
        }).then(processStep).then(FilteringStep { [searchClass] in
            i += 1
            print("i: \(i)")
            return $0.predictions.contains(where: { $0.0 == searchClass && $0.1 > 0.85 })
        })

        filteringStep.consumeResults {
            print($0)
        }
        imageGetStep.start(with: dataProvider)
/*imageGetStep.start(with: dataProvider)/*.then(prepareStep)*/.then(MappingStep { [model] in
            ProcessingInput(imageData: $0, model: model)
        }).then(processStep).then(FilteringStep { [searchClass] in
            $0.predictions.contains(where: { $0.0 == searchClass && $0.1 > 0.85 })
        })*/


        resultingStep = [filteringStep, imageGetStep]
    }
    
    
}

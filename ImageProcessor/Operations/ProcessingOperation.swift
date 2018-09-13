//
//  ProcessingOperation.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Vision

class ProcessingOperation: StepOperation<ProcessingInput, ProcessingOutput> {

    override func start() {
        do {
            let request = try prepareRequest()
            let handler = VNImageRequestHandler(ciImage: CIImage(data: input.imageData)!,
                                                orientation: .up)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }

    private func prepareRequest() throws -> VNCoreMLRequest {
        let model = try VNCoreMLModel(for: input.model)

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
        finish(with: ProcessingOutput(imageData: input.imageData,
                                      predictions: results.map { ($0.identifier, Double($0.confidence)) }))
    }
}

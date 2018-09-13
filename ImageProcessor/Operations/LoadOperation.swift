//
//  LoadOperation.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Photos

class LoadOperation: StepOperation<PHAsset, Data> {

    let imageManager: PHImageManager = PHCachingImageManager()

    override func start() {
        isExecuting = true
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        imageManager.requestImageData(for: input, options: options) { [weak self] (data, _, _, _) in
            if let data = data {
                self?.finish(with: data)
            } else {
                self?.fail(with: nil)
            }
        }
    }

}

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
        imageManager.requestImageData(for: input, options: PHImageRequestOptions()) { [weak self] (data, _, _, _) in
            self?.finish(with: data!)
        }
    }

}

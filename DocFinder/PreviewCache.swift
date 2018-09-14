//
//  PreviewCache.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import UIKit
import Photos

class PreviewCache {

    let targetSize: CGSize

    private let imageManager = PHImageManager()

    private var cache: [PHAsset: UIImage] = [:]
    private var subscriptionKey: Any?

    init(targetSize: CGSize) {
        self.targetSize = targetSize
        subscriptionKey = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                                                 object: nil,
                                                                 queue: .main) { [weak self] _ in
                                                                    self?.cache = [:]
        }
    }

    deinit {
        if let subscriptionKey = subscriptionKey {
            NotificationCenter.default.removeObserver(subscriptionKey)
        }
    }

    func getPreview(for asset: PHAsset, completionHandler: @escaping (UIImage) -> ()) {
        if let preview = cache[asset] {
            completionHandler(preview)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] (image, _) in
            guard let image = image else {
                return
            }
            completionHandler(image)
            self?.cache[asset] = image
        }
    }

}

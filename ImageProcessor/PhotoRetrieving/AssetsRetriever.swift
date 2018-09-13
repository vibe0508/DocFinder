//
//  AssetsRetriever.swift
//  ImageProcessor
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Photos

public protocol AssetsRetrieverProtocol {
    func retrieveAssetsList(success: @escaping ([PHAsset]) -> (), failure: @escaping (Error) -> ())
}

public class AssetsRetriever: AssetsRetrieverProtocol {

    public init() {
    }

    public func retrieveAssetsList(success: @escaping ([PHAsset]) -> (), failure: @escaping (Error) -> ()) {
        requestPermissions(success: {
            self.retrieveAssetsListWhenAuthorized(success: success, failure: failure)
        }, failure: failure)
    }
    
    private func requestPermissions(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            return success()
        }
        
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                success()
            }
        }
    }
    
    private func retrieveAssetsListWhenAuthorized(success: @escaping ([PHAsset]) -> (), failure: @escaping (Error) -> ()) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        let assetsArray = (0..<fetchResult.count).map { fetchResult[$0] }
        
        success(assetsArray)
    }
}

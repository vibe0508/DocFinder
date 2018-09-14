//
//  FinderViewController.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import UIKit
import Photos

private func calculateItemSize() -> CGSize {
    let screenWidth = UIScreen.main.bounds.width
    let itemsPreRow = ceil((screenWidth / 80))
    let side = (screenWidth - (itemsPreRow + 1) * 8) / itemsPreRow
    return CGSize(width: side, height: side)
}

class FinderViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!

    var docType: DocumentType!

    private var session: FinderSession?
    private let previewCache = PreviewCache(targetSize: calculateItemSize())

    private var assets: [PHAsset] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        session = FinderSession(docType: docType, assetHandler: { [weak self] (asset) in
            DispatchQueue.main.async {
                self?.assets.append(asset)
            }
        }, completionHandler: {
            print("Done")
        })
        session?.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension FinderViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "asset", for: indexPath) as! FinderResultCell
        cell.imageView.image = nil

        let tag = Int.random(in: Int.min...Int.max)
        cell.tag = tag

        previewCache.getPreview(for: assets[indexPath.row]) { [weak cell] (image) in
            guard cell?.tag == tag else {
                return
            }
            cell?.imageView.image = image
        }

        return cell
    }
}

extension FinderViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return previewCache.targetSize
    }
}

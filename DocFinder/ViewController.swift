//
//  ViewController.swift
//  DocFinder
//
//  Created by Vyacheslav Beltyukov on 5/18/18.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import UIKit
import Vision
import CoreML
import ImageProcessor
import Photos

class ViewController: UIViewController {

    var session: FinderSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        session = FinderSession(assetHandler: { (asset) in
            print(asset)
        }, completionHandler: {
            print("Done")
        })
        session?.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


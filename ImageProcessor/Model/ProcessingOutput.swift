//
//  ProcessingOutput.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 06/06/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

struct ProcessingOutput {
    let imageData: Data
    let predictions: [(String, Double)]
}

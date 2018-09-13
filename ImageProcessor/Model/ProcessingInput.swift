//
//  ProcessingInput.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation
import Vision

struct ProcessingInput {
    let imageData: Data
    let model: MLModel
}

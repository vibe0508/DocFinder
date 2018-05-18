//
//  PrepareOperation.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class PrepareOperation: StepOperation<Data, Data> {
    override func start() {
        isExecuting = true
        finish(with: input)
    }
}

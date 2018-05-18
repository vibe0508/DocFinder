//
//  DataProvider.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol DataProvider {
    associatedtype Output
    func pickData(_ callback: @escaping (Output?) -> ())
}

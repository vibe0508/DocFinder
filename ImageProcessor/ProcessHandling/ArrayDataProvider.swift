//
//  ArrayDataProvider.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

class ArrayDataProvider<T>: DataProvider {

    typealias Output = T

    private var array: [T]

    init(_ array: [T]) {
        self.array = array
    }

    func pickData(_ callback: @escaping (T?) -> ()) {
        callback(array.popLast())
    }

}

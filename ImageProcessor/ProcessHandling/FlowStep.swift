//
//  FlowStep.swift
//  ImageProcessor
//
//  Created by Вячеслав Бельтюков on 20/05/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

protocol FlowStep: DataProvider {
    associatedtype Input

    func start<T: DataProvider>(with dataProvider: T) -> Self where T.Output == Input
    func then<NextStep: FlowStep>(_ nextStep: NextStep) -> NextStep where NextStep.Input == Output
    func consumeResults(_ consumeBlock: @escaping (Output) -> ())
    func stop()
}

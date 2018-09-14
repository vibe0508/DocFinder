//
//  DocumentType.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 13/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import Foundation

enum DocumentType: String, CaseIterable {
    case passportHome = "passport_rf_home"
    case driverLicense = "driver_license_rf"
    case passportForeign = "passport_rf_foreign"
    case other = "other_doc"

    var classIdentifier: String {
        return rawValue
    }

    var uiName: String {
        switch self {
        case .passportHome:
            return "Общегражданский паспорт"
        case .passportForeign:
            return "Заграничный паспорт"
        case .driverLicense:
            return "Водительское удостоверение"
        case .other:
            return "Иной документ"
        }
    }

    var acceptableConfidence: Float {
        return 0.97
    }
}

//
//  ParametersViewController.swift
//  DocFinder
//
//  Created by Вячеслав Бельтюков on 14/09/2018.
//  Copyright © 2018 Vyacheslav Beltyukov. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController {

    let availableDocs = DocumentType.allCases
    var selectedDocType = DocumentType.passportHome {
        didSet {
            updateDocType()
        }
    }

    @IBOutlet private weak var docTypeButton: UIButton!
    private lazy var hiddenTextField: UITextField = {
        let textField = UITextField()
        textField.isHidden = true
        textField.inputView = pickerView
        return textField
    }()
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.selectRow(availableDocs.firstIndex(of: selectedDocType)!,
                         inComponent: 0, animated: false)
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(hiddenTextField)
        updateDocType()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let finderViewController = segue.destination as? FinderViewController else {
            return
        }
        finderViewController.docType = selectedDocType
    }

    @IBAction private func onDocumentButtonTap() {
        hiddenTextField.becomeFirstResponder()
    }

    @IBAction private func onViewTap() {
        hiddenTextField.resignFirstResponder()
    }

    private func updateDocType() {
        docTypeButton.setTitle(selectedDocType.uiName, for: .normal)
    }
}

extension ParametersViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableDocs.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return availableDocs[row].uiName
    }
}

extension ParametersViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDocType = availableDocs[row]
    }
}

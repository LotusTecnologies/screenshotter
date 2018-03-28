//
//  FormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FormViewController: BaseViewController {
    fileprivate let form: Form
    
    // MARK: View
    
    fileprivate var formView: FormView {
        return view as! FormView
    }
    
    fileprivate var tableView: UITableView {
        return formView.tableView
    }
    
    override func loadView() {
        view = FormView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with form: Form) {
        form.sections?.forEach({ section in
            for index in (section.rows?.startIndex ?? 0)...(section.rows?.endIndex ?? 0) {
                if let selectionRow = section.rows?[index] as? FormRow.Selection {
                    let selectionPickerRow = FormRow.SelectionPicker(with: selectionRow)
                    section.rows?.insert(selectionPickerRow, at: index + 1)
                }
            }
        })
        
        self.form = form
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func tableViewRegister(_ classType: AnyClass, for identifierType: AnyClass) {
            tableView.register(classType, forCellReuseIdentifier: String(describing: identifierType))
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableViewRegister(FormCardTableViewCell.self, for: FormRow.Card.self)
        tableViewRegister(FormDateTableViewCell.self, for: FormRow.Date.self)
        tableViewRegister(FormEmailTableViewCell.self, for: FormRow.Email.self)
        tableViewRegister(FormNumberTableViewCell.self, for: FormRow.Number.self)
        tableViewRegister(FormPhoneTableViewCell.self, for: FormRow.Phone.self)
        tableViewRegister(FormSelectionTableViewCell.self, for: FormRow.Selection.self)
        tableViewRegister(FormSelectionPickerTableViewCell.self, for: FormRow.SelectionPicker.self)
        tableViewRegister(FormTextTableViewCell.self, for: FormRow.Text.self)
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
}

extension FormViewController: UITableViewDataSource {
    fileprivate func formSection(at index: Int) -> FormSection? {
        return form.sections?[index]
    }
    
    fileprivate func formRow(at indexPath: IndexPath) -> FormRow? {
        return formSection(at: indexPath.section)?.rows?[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formSection(at: section)?.rows?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectionPickerRow = formRow(at: indexPath) as? FormRow.SelectionPicker {
            return selectionPickerRow.cellHeight
        }
        else {
            return tableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = formRow(at: indexPath) else {
            return UITableViewCell()
        }
        
        let identifier = String(describing: type(of: row))
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? FormTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        cell.textLabel?.text = row.placeholder
        
        if let cell = cell as? FormTextTableViewCell {
            
        }
        else if let row = row as? FormRow.Selection {
            cell.detailTextLabel?.text = row.value
        }
        else if let cell = cell as? FormSelectionPickerTableViewCell {
            cell.pickerView.dataSource = self
            cell.pickerView.delegate = self
        }
        else {
            
        }
        
//        switch row {
//        case is Form.Card:
//            break
//        case is Form.Date:
//            break
//        case is Form.Email:
//            break
//        case is Form.Number:
//            break
//        case is Form.Phone:
//            break
//        case is Form.Selection:
//            break
//        case is Form.Text:
//            break
//        default:
//            break
//        }
        
        return cell
    }
}

extension FormViewController: UITableViewDelegate {
    fileprivate func didSelectFormSelectionRow(_ selectionRow: FormRow.Selection, at indexPath: IndexPath) {
        let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        
        guard let selectionPickerRow = formRow(at: nextIndexPath) as? FormRow.SelectionPicker else {
            return
        }
        
        selectionPickerRow.cellHeight = (selectionPickerRow.cellHeight > 0) ? 0 : 200
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let formSelectionRow = formRow(at: indexPath) as? FormRow.Selection {
            tableView.deselectRow(at: indexPath, animated: true)
            
            didSelectFormSelectionRow(formSelectionRow, at: indexPath)
        }
        else {
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            
            if let cell = cell as? FormTextTableViewCell {
                cell.becomeFirstResponder()
            }
        }
    }
}

extension FormViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    private func indexPath(for pickerView: UIPickerView) -> IndexPath? {
        var cell: UITableViewCell?
        var superview = pickerView.superview
        
        while cell == nil || superview == nil {
            if let superviewCell = superview as? UITableViewCell {
                cell = superviewCell
            }
            else {
                superview = superview?.superview
            }
        }
        
        if let cell = cell {
            return tableView.indexPath(for: cell)
        }
        else {
            return nil
        }
    }
    
    private func selectionPickerRow(for pickerView: UIPickerView) -> FormRow.SelectionPicker? {
        if let indexPath = indexPath(for: pickerView), let row = formRow(at: indexPath) as? FormRow.SelectionPicker {
            return row
        }
        else {
            return nil
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let selectionPickerRow = selectionPickerRow(for: pickerView) {
            return selectionPickerRow.selectionRow.options?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let options = selectionPickerRow(for: pickerView)?.selectionRow.options {
            return options[row]
        }
        else {
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let selectionPickerRow = selectionPickerRow(for: pickerView),
            let options = selectionPickerRow.selectionRow.options else {
                return
        }
        
        selectionPickerRow.selectionRow.value = options[row]
        
        if let indexPath = form.indexPath(for: selectionPickerRow.selectionRow) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension FormRow {
    class SelectionPicker: FormRow {
        let selectionRow: Selection
        var cellHeight: CGFloat = 0
        
        init(with selectionRow: Selection) {
            self.selectionRow = selectionRow
            super.init()
        }
    }
}

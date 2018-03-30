//
//  FormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil
    
    static var current: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func findFirstResponder() {
        UIResponder._currentFirstResponder = self
    }
}

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
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
        NotificationCenter.default.removeObserver(self)
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let textField = UIResponder.current as? UITextField
            else {
                return
        }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height, right: 0)
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
        
        var scrollToRect = view.frame
        scrollToRect.size.height -= contentInsets.bottom
        
        if !scrollToRect.contains(textField.frame.origin) {
            tableView.scrollRectToVisible(textField.frame, animated: true)
        }
    }
}

extension FormViewController: UITableViewDataSource {
    fileprivate func formSection(at index: Int) -> FormSection? {
        return form.sections?[index]
    }
    
    fileprivate func formRow(at indexPath: IndexPath) -> FormRow? {
        return formSection(at: indexPath.section)?.rows?[indexPath.row]
    }
    
    fileprivate func tableViewCellOwning(_ view: UIView) -> UITableViewCell? {
        var cell: UITableViewCell?
        var superview = view.superview
        
        while cell == nil || superview == nil {
            if let superviewCell = superview as? UITableViewCell {
                cell = superviewCell
            }
            else {
                superview = superview?.superview
            }
        }
        
        return cell
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
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
//        cell.selectionStyle = .none
        cell.textLabel?.text = row.placeholder
        
        if let cell = cell as? FormTextTableViewCell, let row = row as? FormRow.Text {
            let isLastCell = (indexPath.row > tableView.numberOfRows(inSection: indexPath.section) - 1)
            
            cell.textField.delegate = self
            cell.textField.text = row.value
            cell.textField.returnKeyType = isLastCell ? .done : .next
        }
        else if let cell = cell as? FormSelectionTableViewCell, let row = row as? FormRow.Selection {
            cell.detailTextLabel?.text = row.value
        }
        else if let cell = cell as? FormSelectionPickerTableViewCell {
            cell.pickerView.dataSource = self
            cell.pickerView.delegate = self
        }
        else {
            
        }
        
        return cell
    }
}

extension FormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        _ = cell.isFirstResponder ? cell.resignFirstResponder() : cell.becomeFirstResponder()
        
        // Must come after first responder
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FormViewController: UITextFieldDelegate {
    private func indexPath(for textField: UITextField) -> IndexPath? {
        if let cell = tableViewCellOwning(textField) {
            return tableView.indexPath(for: cell)
        }
        else {
            return nil
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next, let indexPath = indexPath(for: textField) {
            let total = tableView.numberOfRows(inSection: indexPath.section)
            let start = indexPath.row + 1
            
            if total > start {
                for next in start...total {
                    let nextIndexPath = IndexPath(row: next, section: indexPath.section)
                    
                    if let cell = tableView.cellForRow(at: nextIndexPath), cell.canBecomeFirstResponder {
                        if cell.becomeFirstResponder() {
                            return true
                        }
                    }
                }
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
}

extension FormViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    private func indexPath(for pickerView: UIPickerView) -> IndexPath? {
        if let cell = tableViewCellOwning(pickerView) {
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
        
        if let indexPath = form.indexPath(for: selectionPickerRow.selectionRow),
            let cell = tableViewCellOwning(pickerView) as? FormSelectionTableViewCell
        {
            cell.canResignFirstResponderOverride = false
            tableView.reloadRows(at: [indexPath], with: .none)
            cell.canResignFirstResponderOverride = nil
        }
    }
}

extension FormRow {
    class SelectionPicker: FormRow {
        let selectionRow: Selection
        
        fileprivate var cellHeight: CGFloat = 0
        fileprivate var isCellVisible: Bool {
            return cellHeight > 0
        }
        
        init(with selectionRow: Selection) {
            self.selectionRow = selectionRow
            super.init()
        }
    }
}

extension FormViewTableView {
    func toggleSelectionPickerVisibility(for indexPath: IndexPath) {
        let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        
        guard let viewController = superview?.next as? FormViewController,
            let selectionPickerRow = viewController.formRow(at: nextIndexPath) as? FormRow.SelectionPicker
            else {
                return
        }
        
        selectionPickerRow.cellHeight = (selectionPickerRow.cellHeight > 0) ? 0 : 200
        
        beginUpdates()
        endUpdates()
    }
}

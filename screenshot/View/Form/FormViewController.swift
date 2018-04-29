//
//  FormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CreditCardValidator

class FormViewController: BaseViewController {
    let form: Form
    
    fileprivate var previousAttachedVisibileIndexPath: IndexPath?
    fileprivate var activePickerIndexPath: IndexPath?
    fileprivate var needsToSyncTableViewAnimation = false
    
    private var preservedContentInset: UIEdgeInsets?
    private var preservedScrollIndicatorInsets: UIEdgeInsets?
    
    fileprivate var errorIndexPaths: [IndexPath]?
    
    // MARK: View
    
    fileprivate var formView: FormView {
        return view as! FormView
    }
    
    var tableView: UITableView {
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
            let startIndex = section.rows?.startIndex ?? 0
            let endIndex = section.rows?.endIndex ?? 0
            
            for index in startIndex..<endIndex {
                if let selectionRow = section.rows?[index] as? FormRow.Selection {
                    let selectionPickerRow = FormRow.SelectionPicker(with: selectionRow)
                    section.rows?.insert(selectionPickerRow, at: index + 1)
                }
                else if let expirationRow = section.rows?[index] as? FormRow.Expiration {
                    let expirationPickerRow = FormRow.ExpirationPicker(with: expirationRow)
                    section.rows?.insert(expirationPickerRow, at: index + 1)
                }
            }
        })
        
        self.form = form
        
        super.init(nibName: nil, bundle: nil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func tableViewRegister(_ classType: AnyClass, for identifierType: AnyClass) {
            tableView.register(classType, forCellReuseIdentifier: String(describing: identifierType))
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = view.backgroundColor
        tableViewRegister(FormCardTableViewCell.self, for: FormRow.Card.self)
        tableViewRegister(FormCheckboxTableViewCell.self, for: FormRow.Checkbox.self)
        tableViewRegister(FormCVVTableViewCell.self, for: FormRow.CVV.self)
        tableViewRegister(FormEmailTableViewCell.self, for: FormRow.Email.self)
        tableViewRegister(FormExpirationTableViewCell.self, for: FormRow.Expiration.self)
        tableViewRegister(FormExpirationPickerTableViewCell.self, for: FormRow.ExpirationPicker.self)
        tableViewRegister(FormNumberTableViewCell.self, for: FormRow.Number.self)
        tableViewRegister(FormPhoneTableViewCell.self, for: FormRow.Phone.self)
        tableViewRegister(FormSelectionTableViewCell.self, for: FormRow.Selection.self)
        tableViewRegister(FormSelectionPickerTableViewCell.self, for: FormRow.SelectionPicker.self)
        tableViewRegister(FormTextTableViewCell.self, for: FormRow.Text.self)
        tableViewRegister(FormZipTableViewCell.self, for: FormRow.Zip.self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Keyboard
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if preservedContentInset == nil {
            preservedContentInset = tableView.contentInset
            preservedScrollIndicatorInsets = tableView.scrollIndicatorInsets
        }
        
        let bottom = keyboardRect.height
        let contentInsets: UIEdgeInsets
        let scrollIndicatorInsets: UIEdgeInsets
        
        if bottom > 0 && view.bounds.height > keyboardRect.origin.y {
            var _contentInset: UIEdgeInsets = .zero
            _contentInset.top = preservedContentInset?.top ?? 0
            _contentInset.bottom = bottom + (preservedContentInset?.bottom ?? 0)
            contentInsets = _contentInset
            
            var _scrollIndicatorInsets: UIEdgeInsets = .zero
            _scrollIndicatorInsets.top = preservedScrollIndicatorInsets?.top ?? 0
            _scrollIndicatorInsets.bottom = bottom + (preservedScrollIndicatorInsets?.bottom ?? 0)
            scrollIndicatorInsets = _scrollIndicatorInsets
        }
        else {
            contentInsets = preservedContentInset ?? .zero
            scrollIndicatorInsets = preservedScrollIndicatorInsets ?? .zero
            
            preservedContentInset = nil
            preservedScrollIndicatorInsets = nil
        }
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = scrollIndicatorInsets
        
        var scrollToRect = view.frame
        scrollToRect.size.height -= contentInsets.bottom
        
        if let textField = UIResponder.current as? UITextField, !scrollToRect.contains(textField.frame.origin) {
            tableView.scrollRectToVisible(textField.frame, animated: true)
        }
    }
    
    // MARK: Error Handling
    
    func highlightErrorFields() {
        var errorIndexPaths = [IndexPath]()
        
        form.sections?.enumerated().forEach({ (i: Int, section: FormSection) in
            section.rows?.enumerated().forEach({ (j: Int, row: FormRow) in
                if row.isRequired && !row.isValid {
                    errorIndexPaths.append(IndexPath(row: j, section: i))
                }
            })
        })
        
        if let firstIndexPath = errorIndexPaths.first {
            self.errorIndexPaths = errorIndexPaths
            tableView.reloadData()
            tableView.scrollToRow(at: firstIndexPath, at: .top, animated: true)
            
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    fileprivate func removeErrorField(at indexPath: IndexPath, with cell: UITableViewCell) {
        if let index = errorIndexPaths?.index(of: indexPath) {
            errorIndexPaths?.remove(at: index)
            syncError(for: cell, at: indexPath)
        }
    }
}

extension FormViewController: UITableViewDataSource {
    fileprivate func formSectionAt(_ index: Int) -> FormSection? {
        return form.sections?[index]
    }
    
    fileprivate func formRowAt(_ indexPath: IndexPath) -> FormRow? {
        return formSectionAt(indexPath.section)?.rows?[indexPath.row]
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return form.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formSectionAt(section)?.rows?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return formSectionAt(section)?.title
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let formRow = formRowAt(indexPath)
        
        if formRow?.isVisible ?? true {
            if formRow is FormRow.Picker {
                return 200
            }
            else {
                return tableView.rowHeight
            }
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let formRow = formRowAt(indexPath) else {
            return UITableViewCell()
        }
        
        let identifier = String(describing: type(of: formRow))
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        if let cell = cell as? FormExpirationPickerTableViewCell {
            cell.pickerView.dataSource = self
            cell.pickerView.delegate = self
            cell.pickerView.tag = FormRow.ExpirationPicker.tag
        }
        else if let cell = cell as? FormSelectionPickerTableViewCell {
            cell.pickerView.dataSource = self
            cell.pickerView.delegate = self
            cell.pickerView.tag = FormRow.SelectionPicker.tag
        }
        else if let cell = cell as? FormTextTableViewCell {
            let isLastCell = (indexPath.row > tableView.numberOfRows(inSection: indexPath.section) - 1)
            
            cell.textField.delegate = self
            cell.textField.returnKeyType = isLastCell ? .done : .next
        }
        
        syncError(for: cell, at: indexPath)
        syncValues(for: cell, at: indexPath)
        syncConditionedCell(at: indexPath)
        
        return cell
    }
    
    fileprivate func syncValues(forCellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            syncValues(for: cell, at: indexPath)
        }
    }
    
    fileprivate func syncValues(for cell: UITableViewCell, at indexPath: IndexPath) {
        guard let formRow = formRowAt(indexPath) else {
            return
        }
        
        cell.textLabel?.text = formRow.placeholder
        
        if let cell = cell as? FormCheckboxTableViewCell {
            cell.isChecked = FormRow.Checkbox.bool(for: formRow.value)
        }
        else if let cell = cell as? FormSelectionTableViewCell {
            cell.detailTextLabel?.text = formRow.value
        }
        else if let cell = cell as? FormCardTableViewCell {
            cell.textField.placeholder = formRow.value
        }
        else if let cell = cell as? FormTextTableViewCell {
            cell.textField.text = formRow.value
        }
    }
    
    fileprivate func syncConditionedCell(at indexPath: IndexPath) {
        guard let formRow = formRowAt(indexPath) else {
            return
        }
        
        if !formRow.linkedConditions.isEmpty {
            formRow.linkedConditions.forEach({ linkCondition in
                let isVisible = linkCondition.formRow.isVisible
                let willBeVisible = linkCondition.value == formRow.value
                
                if isVisible != willBeVisible {
                    linkCondition.formRow.isVisible = willBeVisible
                    
                    if let aIndexPath = form.indexPath(for: linkCondition.formRow) {
                        tableView.reloadRows(at: [aIndexPath], with: willBeVisible ? .bottom : .top)
                    }
                }
            })
        }
    }
    
    fileprivate func syncError(for cell: UITableViewCell, at indexPath: IndexPath) {
        if var cell = cell as? FormErrorTableViewCellProtocol {
            if let errorIndexPaths = errorIndexPaths, errorIndexPaths.contains(indexPath) {
                cell.hasInvalidValue = true
            }
            else {
                cell.hasInvalidValue = false
            }
        }
    }
}

extension FormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FormTextTableViewCell, let formRow = formRowAt(indexPath) as? FormRow.Text {
            formRow.value = cell.textField.text?.trimmingCharacters(in: .whitespaces)
        }
        
    
        // TODO: when scrolling a picker cell off screen there are issues with the first responder
        // the below code does not work. a cell which is first responder does not call this delete function.
        // figure out the best way to resign first responder without doing it on immediate scroll.
        
        
//        if tableView.isTracking {
//            tableView.endEditing(true)
//        }
        
//        if let previousAttachedVisibileIndexPath = previousAttachedVisibileIndexPath {
//            let previousIndexPath = IndexPath(row: indexPath.row - 2, section: indexPath.section)
//            let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
//
//            if (previousAttachedVisibileIndexPath == previousIndexPath || previousAttachedVisibileIndexPath == nextIndexPath),
//                let selectionCell = tableView.cellForRow(at: previousAttachedVisibileIndexPath),
//                selectionCell.isFirstResponder
//            {
//                tableView.endEditing(true)
////                selectionCell.resignFirstResponder()
//            }
//        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let formRow = formRowAt(indexPath)
        
        func didSelectAttachedIndexPath(yes: ()->(), no: ()->()) {
            if let formRow = formRow {
                switch formRow {
                case is FormRow.Expiration, is FormRow.Selection:
                    yes()
                default:
                    no()
                }
            }
        }
        
        if previousAttachedVisibileIndexPath != nil && previousAttachedVisibileIndexPath != indexPath {
            didSelectAttachedIndexPath(yes: {
                needsToSyncTableViewAnimation = true
            }, no: {
                needsToSyncTableViewAnimation = false
            })
        }
        
        _ = cell.isFirstResponder ? cell.resignFirstResponder() : cell.becomeFirstResponder()
        
        // Must come after first responder
        tableView.deselectRow(at: indexPath, animated: true)
        
        removeErrorField(at: indexPath, with: cell)
        
        didSelectAttachedIndexPath(yes: {
            if cell.isFirstResponder {
                previousAttachedVisibileIndexPath = indexPath
            }
            else {
                previousAttachedVisibileIndexPath = nil
            }
        }, no: {
            previousAttachedVisibileIndexPath = nil
        })
        
        if let formRow = formRow as? FormRow.Checkbox {
            let isChecked = FormRow.Checkbox.bool(for: formRow.value)
            formRow.value = FormRow.Checkbox.value(for: !isChecked)
            syncValues(for: cell, at: indexPath)
        }
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let indexPath = indexPath(for: textField),
            let cell = tableView.cellForRow(at: indexPath) as? FormTextTableViewCell
        {
            removeErrorField(at: indexPath, with: cell)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let indexPath = indexPath(for: textField) {
            if let cell = tableView.cellForRow(at: indexPath) as? FormTextTableViewCell {
                return cell.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
            }
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next, let indexPath = indexPath(for: textField) {
            let total = tableView.numberOfRows(inSection: indexPath.section)
            let start = indexPath.row + 1
            
            if total > start {
                for next in start..<total {
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let indexPath = indexPath(for: textField) else {
            return
        }
        
        if let formRow = formRowAt(indexPath) as? FormRow.Text {
            formRow.value = textField.text?.trimmingCharacters(in: .whitespaces)
        }
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
        if let indexPath = indexPath(for: pickerView), let formRow = formRowAt(indexPath) as? FormRow.SelectionPicker {
            return formRow
        }
        else {
            return nil
        }
    }
    
    private func expirationPickerRow(for pickerView: UIPickerView) -> FormRow.ExpirationPicker? {
        if let indexPath = indexPath(for: pickerView), let formRow = formRowAt(indexPath) as? FormRow.ExpirationPicker {
            return formRow
        }
        else {
            return nil
        }
    }
    
    private func expirationValue(forRow row: Int, inComponent component: Int) -> Int? {
        if let dateComponent = FormExpirationPickerTableViewCell.DateComponent(rawValue: component) {
            return FormExpirationPickerTableViewCell.dateMap[dateComponent]?[row]
        }
        else {
            return nil
        }
    }
    
    private func expirationValue(forValue value: Int, inComponent component: Int) -> String? {
        var month = 0
        var year = 0
        
        if component == FormExpirationPickerTableViewCell.DateComponent.month.rawValue {
            month = value
        }
        else {
            year = value
        }
        
        let date = FormRow.Expiration.Date(month: month, year: year)
        return FormRow.Expiration.value(for: date)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch pickerView.tag {
        case FormRow.SelectionPicker.tag:
            return 1
        case FormRow.ExpirationPicker.tag:
            return 2
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case FormRow.SelectionPicker.tag:
            if let selectionPickerRow = selectionPickerRow(for: pickerView) {
                return selectionPickerRow.attachedRow.options?.count ?? 0
            }
        case FormRow.ExpirationPicker.tag:
            if let dateComponent = FormExpirationPickerTableViewCell.DateComponent(rawValue: component) {
                return FormExpirationPickerTableViewCell.dateMap[dateComponent]?.count ?? 0
            }
        default:
            break
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case FormRow.SelectionPicker.tag:
            if let options = selectionPickerRow(for: pickerView)?.attachedRow.options {
                return options[row]
            }
        case FormRow.ExpirationPicker.tag:
            if let value = expirationValue(forRow: row, inComponent: component) {
                return expirationValue(forValue: value, inComponent: component)
            }
        default:
            break
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case FormRow.SelectionPicker.tag:
            guard let selectionPickerRow = selectionPickerRow(for: pickerView),
                let options = selectionPickerRow.attachedRow.options
                else {
                    return
            }
            
            selectionPickerRow.attachedRow.value = options[row]
            syncPickerRow(selectionPickerRow)
            
        case FormRow.ExpirationPicker.tag:
            guard let expirationPickerRow = expirationPickerRow(for: pickerView),
                let value = expirationValue(forRow: row, inComponent: component)
                else {
                    return
            }
            
            func setFormRowValue(with date: FormRow.Expiration.Date) {
                var date = date
                
                if component == FormExpirationPickerTableViewCell.DateComponent.month.rawValue {
                    date.month = value
                }
                else {
                    date.year = value
                }
                
                expirationPickerRow.attachedRow.value = FormRow.Expiration.value(for: date)
            }
            
            if let date = FormRow.Expiration.date(for: expirationPickerRow.attachedRow.value) {
                setFormRowValue(with: date)
            }
            else if let currentValueString = expirationPickerRow.attachedRow.value,
                let currentValue = Int(currentValueString)
            {
                var date = FormRow.Expiration.Date(month: 0, year: 0)
                
                if FormRow.Expiration.isYear(currentValue) {
                    date.year = currentValue
                }
                else {
                    date.month = currentValue
                }
                
                setFormRowValue(with: date)
            }
            else {
                expirationPickerRow.attachedRow.value = expirationValue(forValue: value, inComponent: component)
            }
            
            syncPickerRow(expirationPickerRow)
            
        default:
            break
        }
    }
    
    private func syncPickerRow<T: FormPickerRowProtocol>(_ pickerRow: T) {
        if let indexPath = form.indexPath(for: pickerRow.attachedRow),
            let cell = tableView.cellForRow(at: indexPath)
        {
            syncValues(for: cell, at: indexPath)
            syncConditionedCell(at: indexPath)
        }
    }
}

protocol FormPickerRowProtocol {
    static var tag: Int { get }
    
    associatedtype T: FormRow
    var attachedRow: T { get }
}

extension FormRow {
    class Picker: FormRow {
        override init() {
            super.init()
            isVisible = false
            isRequired = false
        }
    }
    
    class SelectionPicker: Picker, FormPickerRowProtocol {
        static let tag = 1
        
        let attachedRow: Selection
        
        init(with selectionRow: Selection) {
            self.attachedRow = selectionRow
            super.init()
        }
    }
    
    class ExpirationPicker: Picker, FormPickerRowProtocol {
        static let tag = 2
        
        let attachedRow: Expiration
        
        init(with selectionRow: Expiration) {
            self.attachedRow = selectionRow
            super.init()
        }
    }
}

extension FormViewTableView {
    func changePicker(visibility: Bool, forAttached indexPath: IndexPath) {
        let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        
        guard let viewController = superview?.next as? FormViewController,
            let pickerRow = viewController.formRowAt(nextIndexPath) as? FormRow.Picker,
            pickerRow.isVisible != visibility
            else {
                return
        }
        
        pickerRow.isVisible = visibility
        
        if viewController.needsToSyncTableViewAnimation {
            viewController.needsToSyncTableViewAnimation = false
        }
        else {
            beginUpdates()
            endUpdates()
        }
    }
}

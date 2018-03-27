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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = formRow(at: indexPath) else {
            return UITableViewCell()
        }
        
        let identifier = String(describing: type(of: row))
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.selectionStyle = .none
        
        if let cell = cell as? FormTextTableViewCell {
            cell.textField.placeholder = row.placeholder
        }
        else {
            cell.textLabel?.text = row.placeholder
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        if let cell = cell as? FormTextTableViewCell {
            cell.becomeFirstResponder()
        }
        else if cell is FormSelectionTableViewCell {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let lastRowIndex = tableView.numberOfRows(inSection: indexPath.section) - 1
            let isLastRow = indexPath.row == lastRowIndex
            let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            let shouldInsertPicker: Bool = {
                if !isLastRow, let row = formRow(at: IndexPath(row: nextIndexPath.row, section: indexPath.section)) {
                    return type(of: row) != FormRow.SelectionPicker.self
                }
                else {
                    return false
                }
            }()
            
            if isLastRow || shouldInsertPicker {
                let row = FormRow.SelectionPicker()
                formSection(at: indexPath.section)?.rows?.insert(row, at: nextIndexPath.row)
                tableView.insertRows(at: [nextIndexPath], with: .top)
            }
            else {
                formSection(at: indexPath.section)?.rows?.remove(at: nextIndexPath.row)
                tableView.deleteRows(at: [nextIndexPath], with: .top)
            }
        }
    }
}

extension FormRow {
    class SelectionPicker: FormRow {
        
    }
}

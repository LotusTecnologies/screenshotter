//
//  DataSource.swift
//  screenshot
//
//  Created by Corey Werner on 7/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

/// The section enum must maintain its order.
class DataSource<S: RawRepresentable & Hashable, R: RawRepresentable> where S.RawValue == Int, R.RawValue == Int {
    private var data: [(section: S, rows: [R])] = []
    
    var count: Int {
        return data.count
    }
    
    init(data: [S: [R]]) {
        data.forEach { (section, rows) in
            addSection(section, rows: rows)
        }
    }
    
    func addSection(_ section: S, rows: [R]) {
        guard !data.contains(where: { $0.section == section }) else {
            return
        }
        data.insert((section, rows), at: 0)
        data.sort(by: { $0.section.rawValue < $1.section.rawValue })
    }
    
    func removeSection(_ section: S) {
        let index = data.index { (_section, rows) -> Bool in
            return _section == section
        }
        if let index = index {
            data.remove(at: index)
        }
    }
    
    func indexPath(row: R, section: S) -> IndexPath? {
        guard let sectionIndex = data.index(where: { $0.section == section }),
            let rowIndex = data[sectionIndex].rows.index(where: { $0 == row })
            else {
                return nil
        }
        return IndexPath(row: rowIndex, section: sectionIndex)
    }
    
    func section(_ sectionIndex: Int) -> S? {
        guard data.count > sectionIndex else {
            return nil
        }
        return data[sectionIndex].section
    }
    
    func rows(_ sectionIndex: Int) -> [R]? {
        guard data.count > sectionIndex else {
            return nil
        }
        return data[sectionIndex].rows
    }
    
    func row(_ indexPath: IndexPath) -> R? {
        guard data.count > indexPath.section else {
            return nil
        }
        let rows = data[indexPath.section].rows
        guard rows.count > indexPath.row else {
            return nil
        }
        return rows[indexPath.row]
    }
}

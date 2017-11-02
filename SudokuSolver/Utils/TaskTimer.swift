//
//  TaskTimer.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation

class TaskTimer {
    
    private var begin: Date
    
    init() {
        begin = Date()
    }
    
    func stop() -> Double {
        return Date().timeIntervalSince(begin) * 1000
    }
    
}

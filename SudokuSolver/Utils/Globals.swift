//
//  Globals.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation

let __debug = true

func debug(_ message: String) {
    if __debug {
        print("DEBUG: \(message)")
    }
}

extension Int {
    
    static func random(lower: Int , upper: Int) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
    }
    
}

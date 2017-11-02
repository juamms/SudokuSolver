//
//  Matrix.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation

class Matrix: CustomStringConvertible {
    
    private(set) var size: Int
    
    var grid: [Int]
    
    var filteredGrid: [Int] {
        return grid.filter({ $0 > 0 })
    }
    
    var isFilled: Bool {
        return grid.count == filteredGrid.count
    }
    
    var positions: [Position] {
        var positions = [Position]()
        
        for r in 0..<size {
            for c in 0..<size {
                positions.append(Position(row: r, column: c))
            }
        }
        
        return positions
    }
    
    var isComplete: Bool {
        return grid.filter({ $0 == 0 }).count == 0
    }
    
    var isEmpty: Bool {
        return filteredGrid.count == 0
    }
    
    private var _squared: Int {
        return size * size
    }
    
    var description: String {
        var str = ""
        
        for i in 0..<_squared {
            str += "\(grid[i])"
            
            if (i + 1) % size == 0 {
                str += "\n"
            }
        }
        
        return str
    }
    
    init?(size: Int) {
        guard size > 0 else {
            return nil
        }
        self.size = size
        grid = Array(repeating: 0, count: size * size)
    }
    
    private func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < size && column >= 0 && column < size
    }
    
    subscript(row: Int, column: Int) -> Int {
        get {
            guard indexIsValid(row: row, column: column) else {
                return -1
            }
            
            return grid[(row * size) + column]
        }
        set {
            guard indexIsValid(row: row, column: column) else {
                return
            }
            grid[(row * size) + column] = newValue
        }
    }
    
    func fill(with array: [Int]) {
        let max = array.count > _squared ? _squared : array.count
        
        for i in 0..<max {
            grid[i] = array[i]
        }
    }
    
    func rowIndices(_ row: Int) -> [Int] {
        let begin = row * size
        let end = begin + size
        
        return grid.indices.filter({ $0 >= begin && $0 < end })
    }
    
    func row(_ row: Int) -> [Int] {
        return rowIndices(row).map({ grid[$0] })
    }
    
    func filteredRow(_ row: Int) -> [Int] {
        return self.row(row).filter({ $0 > 0 })
    }
    
    func columnIndices(_ column: Int) -> [Int] {
        guard column >= 0 && column < size else {
            return []
        }
        return grid.indices.filter({ ($0 - column) % size == 0 })
    }
    
    func column(_ column: Int) -> [Int] {
        return columnIndices(column).map({ grid[$0] })
    }
    
    func filteredColumn(_ column: Int) -> [Int] {
        return self.column(column).filter({ $0 > 0 })
    }
    
    func gridIndex(of position: Position) -> Int {
        return (position.row * size) + position.column
    }
    
    func position(of index: Int) -> Position {
        let column = index % size
        let row = Int(index / size)
        
        return Position(row: row, column: column)
    }
    
}

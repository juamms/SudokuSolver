//
//  SudokuBoard.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation
import Cocoa

struct Position: Hashable {

    var row: Int
    var column: Int
    
    var hashValue: Int {
        return Int("\(row)\(column)")!
    }
    
    static func ==(lhs: Position, rhs: Position) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
}

class SudokuBoard: Matrix {
    
    var quadrantSize: Int {
        return Int(sqrt(Double(size)))
    }
    
    var exchangeFormat: String {
        return "\(size)|\(grid.map({ "\($0)" }).joined(separator: ","))"
    }
    
    override var description: String {
        var str = ""
        
        for i in grid.indices {
            str += "\(grid[i]) "
            
            let j = i + 1
            if j % size == 0 {
                str.removeLast()
                str += "\n"
            } else if j % quadrantSize == 0 {
                str += " "
            }
            
            if j % (size * quadrantSize) == 0 {
                str += "\n"
            }
        }
        
        str.removeLast(2)
        
        return str
    }
    
    override init?(size: Int = 9) {
        guard size > 1 && sqrt(Double(size)).truncatingRemainder(dividingBy: 1) == 0 else {
            return nil
        }
        super.init(size: size)
    }
    
    init?(from string: String) {
        guard string.characters.count > 0, let size = Int(string.components(separatedBy: "|").first!), size > 1 && sqrt(Double(size)).truncatingRemainder(dividingBy: 1) == 0 else {
            return nil
        }
        super.init(size: size)
        
        let aux = string.components(separatedBy: "|")
        
        if aux.count == 2 {
            let arr = aux[1].components(separatedBy: ",").flatMap({ Int($0) ?? 0 }).filter({ $0 >= 0 && $0 <= size})
            fill(with: arr)
        }
    }
    
    func quadrantOffset(_ quadrant: Int) -> Position {
        guard quadrant >= 0 && quadrant < size else {
            return Position(row: 0, column: 0)
        }
        
        let row = quadrant / quadrantSize
        let column = quadrant % quadrantSize
        
        return Position(row: row, column: column)
    }
    
    func quadrant(_ quadrant: Int) -> Matrix? {
        guard quadrant >= 0 && quadrant < size else {
            return nil
        }
        
        let position = quadrantOffset(quadrant)
        
        return self.quadrant(position)
    }
    
    private func quadrant(_ position: Position) -> Matrix? {
        let (row, column) = (position.row, position.column)
        guard row >= 0 && row < quadrantSize && column >= 0 && column < quadrantSize else {
            return nil
        }
        
        var arr: [Int] = []
        for i in 0..<quadrantSize {
            let quadrantRow = i + (row * quadrantSize)
            let quadrantColumn = column * quadrantSize
            let columnRange = quadrantColumn..<(quadrantColumn + quadrantSize)
            
            arr.append(contentsOf: self.row(quadrantRow)[columnRange])
        }
        
        let m = Matrix(size: quadrantSize)!
        m.fill(with: arr)
        
        return m
    }
    
    func quadrant(containing boardPosition: Position) -> Matrix? {
        let max = quadrantSize - 1
        let positionZero = Position(row: 0, column: 0)
        let positionMax = Position(row: max, column: max)
        let (row, column) = (boardPosition.row, boardPosition.column)
        
        return (0..<size).filter({ (quadrantIndex) -> Bool in
            let quadrantBegin = position(for: positionZero, in: quadrantIndex)
            let quadrantEnd = position(for: positionMax, in: quadrantIndex)
            
            let beginIsHigher = row >= quadrantBegin.row && column >= quadrantBegin.column
            let endIsLower = row <= quadrantEnd.row && column <= quadrantEnd.column
            
            return beginIsHigher && endIsLower
        }).map({ quadrant($0)! }).first
    }
    
    func position(for position: Position, in quadrant: Int) -> Position {
        let offset = quadrantOffset(quadrant)
        let rowOffset = offset.row * quadrantSize
        let columnOffset = offset.column * quadrantSize
        
        return Position(row: position.row + rowOffset, column: position.column + columnOffset)
    }
    
    func representation(with dupes: [Dupe]) -> NSAttributedString {
        var attributedArray = grid.map({ NSMutableAttributedString(string: String($0) + " ") })
        let red = NSColor(red: 240/255, green: 0, blue: 50/255, alpha: 1)
        let dupeHighlight: [NSAttributedStringKey: Any] = [
            .foregroundColor: NSColor.white,
            .backgroundColor: red
        ]
        
        let backgroundHighlight: [NSAttributedStringKey: Any] = [
            .backgroundColor: red
        ]
        
        let quadrantHighlight: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]
        
        // Highlight dupes
        let indices = dupes.map({ gridIndex(of: $0.position) })
        
        attributedArray.indices
            .filter({ indices.contains($0) })
            .map({ attributedArray[$0] })
            .forEach({ $0.addAttributes(dupeHighlight, range: NSRange(location: 0, length: $0.length - 1))})
        
        // Highlight columns
        let columns = dupes.filter({ $0.type == .column }).map({ $0.position.column })
        
        columns.forEach { (column) in
            let indices = columnIndices(column)
            attributedArray.indices
                .filter({ indices.contains($0) })
                .map({ attributedArray[$0] })
                .forEach({ $0.addAttributes(backgroundHighlight, range: NSRange(location: 0, length: $0.length - 1))})
        }
        
        // Highlight rows
        let rows = dupes.filter({ $0.type == .row }).map({ $0.position.row })
        
        rows.forEach { (row) in
            let indices = rowIndices(row)
            attributedArray.indices
                .filter({ indices.contains($0) })
                .map({ attributedArray[$0] })
                .forEach({ $0.addAttributes(backgroundHighlight, range: NSRange(location: 0, length: $0.length - 1))})
        }
        
        // Highlight quadrant dupes
        dupes
            .filter({ $0.type == .quadrant })
            .map({ attributedArray[gridIndex(of: $0.position)] })
            .forEach({ $0.addAttributes(quadrantHighlight, range: NSRange(location: 0, length: $0.length - 1))})
        
        let str = NSMutableAttributedString()
        
        let newLine = NSMutableAttributedString(string: "\n")
        let space = NSMutableAttributedString(string: " ")
        
        for i in attributedArray.indices {
            str.append(attributedArray[i])
            
            let j = i + 1
            if j % size == 0 {
                str.deleteCharacters(in: NSRange(location: str.length - 1, length: 1))
                str.append(newLine)
            } else if j % quadrantSize == 0 {
                str.append(space)
            }
            
            if j % (size * quadrantSize) == 0 {
                str.append(newLine)
            }
        }
        
        str.deleteCharacters(in: NSRange(location: str.length - 2, length: 2))
        
        return str
    }
    
}

//
//  Checker.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation

enum BoardStatus: String {
    case valid, incomplete, dupes
}

enum DupeType: String {
    case quadrant, row, column
}

typealias Dupe = (type: DupeType, position: Position)

class Checker {
    
    private var board: SudokuBoard
    private var dupes = [Dupe]()
    
    private let checkerGroup = DispatchGroup()
    private let workerQueue = DispatchQueue.global(qos: .userInitiated)
    private let writeQueue = DispatchQueue(label: "com.jsilva.SudokuSolver.checker.write")
    
    private var rowCache: [Int: [Int]] = [:]
    private var columnCache: [Int: [Int]] = [:]
    
    init(for board: SudokuBoard) {
        self.board = board
        
        for i in 0..<board.size {
            rowCache[i] = board.filteredRow(i)
            columnCache[i] = board.filteredColumn(i)
        }
    }
    
    func startChecking(in group: DispatchGroup?, completion: @escaping (BoardStatus, [Dupe]) -> ()) {
        group?.enter()
        for q in 0..<board.size {
            checkerGroup.enter()
            workerQueue.async {
                debug("Starting check worker for quadrant \(q)")
                self.check(q)
                self.checkerGroup.leave()
            }
        }
        
        checkerGroup.wait()
        
        if dupes.count > 0 {
            completion(.dupes, dupes)
        } else if board.isComplete {
            completion(.valid, [])
        } else {
            completion(.incomplete, [])
        }
        
        group?.leave()
    }
    
    func startChecking(completion: @escaping (BoardStatus, [Dupe]) -> ()) {
        startChecking(in: nil, completion: completion)
    }
    
    private func check(_ quadrant: Int) {
        let q = board.quadrant(quadrant)!
        let listed = q.filteredGrid.filter({ $0 > 0 })
        let size = q.size
        
        for r in 0..<size {
            for c in 0..<size {
                let num = q[r, c]
                let boardPosition = board.position(for: Position(row: r, column: c), in: quadrant)
                
                let row = rowCache[boardPosition.row]!
                let column = columnCache[boardPosition.column]!
                
                let inQuadrant = listed.filter({ $0 == num }).count
                let inRow = row.filter({ $0 == num }).count
                let inColumn = column.filter({ $0 == num }).count
                
                let hasDupes = inQuadrant > 1 || inRow > 1 || inColumn > 1
                
                if hasDupes {
                    var _dupes = [Dupe]()
                    
                    if inQuadrant > 1 {
                        _dupes.append(Dupe(type: .quadrant, position: boardPosition))
                    }
                    
                    if inRow > 1 {
                        _dupes.append(Dupe(type: .row, position: boardPosition))
                    }
                    
                    if inColumn > 1 {
                        _dupes.append(Dupe(type: .column, position: boardPosition))
                    }
                    
                    writeQueue.sync {
                        self.dupes.append(contentsOf: _dupes)
                    }
                }
            }
        }
    }
}

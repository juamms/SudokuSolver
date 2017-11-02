//
//  Solver.swift
//  SudokuSolver
//
//  Created by Joao Silva on 22/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Foundation

enum SolverResult {
    case complete, empty, impossible, error
}

class Solver {
    
    private var checker: Checker
    private var board: SudokuBoard
    private var fixedIndices: [Int] = []
    
    private var workerGroup = DispatchGroup()
    private var workerQueue = DispatchQueue.global(qos: .userInitiated)
    private var writeQueue = DispatchQueue(label: "com.jsilva.SudokuSolver.solver.write")
    
    private var passes = 0
    private var hasMultipleNumbers = false
    
    private var previousMultiplePositions = [Position]()
    private var multiplePositions: [Position]!
    private var previousValidNumbers = [Position: Set<Int>]()
    private var validNumbers = [Position: Set<Int>]()
    private var usedNumber: (position: Position, value: Int)?
    
    init(for board: SudokuBoard) {
        self.board = board
        self.checker = Checker(for: board)
        
        let indices = board.grid.indices.filter({ board.grid[$0] > 0 })
        self.fixedIndices.append(contentsOf: indices)
    }
    
    func solve(completion: @escaping (SolverResult, Int) -> ()) {
        var isValid = false, canSolve = false
        let checkerGroup = DispatchGroup()
        
        debug("Board before solving:\n\(board)")
        debug("Starting initial check...")
        
        checker.startChecking(in: checkerGroup) { (boardStatus, _) in
            debug("Initial check complete.")
            switch boardStatus {
            case .dupes:
                completion(.impossible, 0)
            case .valid:
                completion(.complete, 0)
            default:
                if self.board.isEmpty {
                    completion(.empty, 0)
                } else {
                    debug("Board is incomplete. Will begin solving.")
                    canSolve = true
                }
            }
        }
        
        checkerGroup.wait()
        
        if !canSolve {
            return
        }
        
        var prevState = board.filteredGrid
        
        while !isValid {
            hasMultipleNumbers = false
            passes += 1
            debug("Starting pass \(passes).")
            for q in 0..<board.size {
                workerGroup.enter()
                workerQueue.async {
                    self.startWorker(for: q)
                    self.workerGroup.leave()
                }
            }
            
            workerGroup.wait()
            
            debug("Workers finished.")
            debug("Board after pass \(passes):\n\(board)")
            
            if board.isFilled {
                debug("Board is filled, will start checking...")
                
                checker.startChecking(in: checkerGroup) { (boardStatus, dupes) in
                    debug("Check finished. Board status is \(boardStatus).")
                    
                    if boardStatus == .dupes {
                        debug("Dupes found! Removing...")
                        
                        dupes.map({ self.board.gridIndex(of: $0.position) }).forEach({ (index) in
                            if !self.fixedIndices.contains(index) {
                                self.board.grid[index] = 0
                            }
                        })
                    }
                    
                    isValid = boardStatus == .valid
                }
                
                checkerGroup.wait()
            } else {
                let newState = board.filteredGrid
                if hasMultipleNumbers || prevState == newState {
                    debug("Multiple possible numbers were found. Will try to guess correct one.")
                    multiplePositions = board.grid.indices.filter({ board.grid[$0] == 0 }).map({ board.position(of: $0) })
                    multiplePositions.forEach({ (position) in
                        validNumbers[position] = validNumbers(for: position)
                    })
                    
                    if validNumbers.filter({ $0.value.count == 0 }).count > 0 {
                        debug("Previous attempt was invalid.")
                        if previousMultiplePositions.isEmpty {
                            // Board is impossible
                            debug("No other options are available. Board is impossible.")
                            completion(.impossible, passes)
                            return
                        }
                        
                        if let number = usedNumber {
                            debug("Removing number \(number.value) from \(number.position) and influenced numbers.")
                            previousMultiplePositions.forEach({ board[$0.row, $0.column] = 0 })
                            previousValidNumbers[number.position]!.remove(number.value)
                            
                            let newNumber = previousValidNumbers.filter({ $0.value.count > 0 }).map({ ($0.key, $0.value.first! )}).first
                            
                            if let newNumber = newNumber {
                                debug("Will try new number: \(newNumber.1) in \(newNumber.0)")
                                usedNumber = newNumber
                                board[newNumber.0.row, newNumber.0.column] = newNumber.1
                            } else {
                                // board is impossible
                                debug("No new numbers available. Board is impossible.")
                                completion(.impossible, passes)
                                return
                            }
                        } else {
                            // some error occured
                            debug("ERROR: No previous numbers were tried. Exiting.")
                            completion(.error, -1)
                            return
                        }
                    } else {
                        previousValidNumbers.removeAll()
                        previousMultiplePositions.removeAll()
                        validNumbers.removeAll()
                        
                        multiplePositions = board.grid.indices.filter({ board.grid[$0] == 0 }).map({ board.position(of: $0) })
                        multiplePositions.forEach({ (position) in
                            validNumbers[position] = validNumbers(for: position)
                        })
                        
                        let number = validNumbers.filter({ $0.value.count > 0 }).map({ ($0.key, $0.value.first! )}).first
                        
                        if let number = number {
                            usedNumber = number
                            
                            let position = number.0
                            board[position.row, position.column] = number.1
                            previousMultiplePositions = multiplePositions
                            previousValidNumbers = validNumbers
                            
                            debug("Will try number \(number.1) in \(number.0)")
                        } else {
                            // board is impossible
                            debug("No new numbers available. Board is impossible.")
                            completion(.impossible, passes)
                            return
                        }
                        
                    }
                } else {
                    prevState = newState
                }
            }
        }
        
        completion(.complete, passes)
    }
    
    private func startWorker(for quadrant: Int) {
        debug("Starting worker for quadrant \(quadrant).")
        
        var didWork: Bool
        
        repeat {
            didWork = false
            hasMultipleNumbers = false
            
            let emptyPositions = board.quadrant(quadrant)!.positions
                .map({ board.position(for: $0, in: quadrant)})
                .filter({ board[$0.row, $0.column] == 0})
            
            emptyPositions.forEach { (position) in
                let numbers = validNumbers(for: position)
                
                let number: Int
                if numbers.count == 1 {
                    number = numbers.first!
                } else {
                    if numbers.count > 0 {
                        writeQueue.sync {
                            hasMultipleNumbers = true
                        }
                    }
                    number = 0
                }
                
                if number > 0 {
                    didWork = true
                    writeQueue.sync {
                        board[position.row, position.column] = number
                    }
                }
            }
        } while didWork
    }
    
    private func validNumbers(for position: Position) -> Set<Int> {
        var presentNumbers = Set<Int>()
        
        presentNumbers.formUnion(board.row(position.row))
        presentNumbers.formUnion(board.column(position.column))
        presentNumbers.formUnion(board.quadrant(containing: position)!.grid)
        
        return Set(1...board.size).subtracting(presentNumbers)
    }
}

//
//  ViewController.swift
//  SudokuSolver
//
//  Created by Joao Silva on 17/07/2017.
//  Copyright © 2017 Joao Silva. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var exchangeFormatTextField: NSTextField!
    @IBOutlet weak var boardLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    
    var board: SudokuBoard!
    var checker: Checker!
    var solver: Solver!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        exchangeFormatTextField.target = self
        exchangeFormatTextField.action = #selector(parse(_:))
        
        board = SudokuBoard(size: 9)
        checker = Checker(for: board)
        solver = Solver(for: board)
        
        updateUI()
    }
    
    @IBAction func parse(_ sender: Any) {
        if let board = SudokuBoard(from: exchangeFormatTextField.stringValue) {
            self.board = board
            checker = Checker(for: board)
            solver = Solver(for: board)
            
            updateUI()
            messageLabel.stringValue = "Board parsed successfully."
        } else {
            let alert = NSAlert()
            alert.messageText = "Invalid board exchange format."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: view.window!, completionHandler: nil)
        }
    }
    
    @IBAction func check(_ sender: NSButton) {        
        let timer = TaskTimer()
        checker.startChecking { (boardStatus, dupes) in
            let time = timer.stop()
            self.messageLabel.stringValue = String(format: "Board checked in %.2f ms", time)
            
            if boardStatus == .dupes {
                DispatchQueue.global().async {
                    let str = self.board.representation(with: dupes)
                    
                    DispatchQueue.main.async {
                        self.boardLabel.attributedStringValue = str
                    }
                }
            } else {
                self.messageLabel.stringValue = String(format: "Board is \(boardStatus). Checked in %.2f ms", time)
            }
            
        }
    }
    
    @IBAction func solve(_ sender: NSButton) {
        let timer = TaskTimer()
        solver.solve { (status, passes) in
            let time = timer.stop()
            
            let str: String
            switch status {
            case .empty:
                str = "Cannot solve an empty board."
            case .impossible:
                str = String(format: "Board is impossible to solve. Passes: \(passes) (%.2f ms)", time)
            case .error:
                str = String(format: "ERROR: Could not solve board. Passes: \(passes) (%.2f ms)", time)
            default:
                str = String(format: "Finished solving in \(passes) passes (%.2f ms).", time)
            }
            
            self.messageLabel.stringValue = str
            self.updateUI()
        }
    }
    
    func updateUI() {
        boardLabel.stringValue = "\(board!)"
        exchangeFormatTextField.stringValue = board.exchangeFormat
    }
}


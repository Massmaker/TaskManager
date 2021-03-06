//
//  ViewController.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Eureka

class BoardEditViewController: FormViewController {
    
    private var editingType:BoardEditingType = .CreateNew{
        didSet{
            switch editingType
            {
                case .CreateNew:
                    populateTableViewWithBoard(nil)
                case .EditCurrent(let board):
                    populateTableViewWithBoard(board)
            }
        }
    }
    private weak var boardCloudHandler:BoardCloudHandler?
    private var currentBoard:TaskBoardInfo?
    private var initialTitle = ""
    private var initialDetails = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setEditingType(type:BoardEditingType)
    {
        self.editingType = type
    }
    
    func setEditingHandler(handler:BoardCloudHandler?)
    {
        self.boardCloudHandler = handler
    }
    
    private func populateTableViewWithBoard(board:TaskBoardInfo?)
    {
        let titleSectionTitle = "board title"
        let detailsSectionTitle = "board details"
        guard let editableBoard = board else
        {
            form +++
                Section(titleSectionTitle)
                <<< TextAreaRow(){ $0.placeholder = "Enter board title"}.onChange(){ [unowned self](row) -> () in
                        if let title = row.value
                        {
                            if let _ = self.currentBoard //update board title
                            {
                                self.currentBoard?.title = title
                                self.checkSaveButtonEnabled()
                            }
                            else //create new board with board title set
                            {
                                let newBoard = TaskBoardInfo(title:title)
                                self.currentBoard = newBoard
                                self.checkSaveButtonEnabled()
                            }
                        }
                    }//onChange end
                +++ Section(detailsSectionTitle)
                <<< TextAreaRow(){ $0.placeholder = "Enter board description"}.onChange(){[unowned self] (row) -> () in
                        if let details = row.value
                        {
                            if let _ = self.currentBoard //update board details
                            {
                                self.currentBoard?.details = details
                                self.checkSaveButtonEnabled()
                            }
                            else //create new board with boardDetails set
                            {
                                let newBoard = TaskBoardInfo(details: details)
                                self.currentBoard = newBoard
                                self.checkSaveButtonEnabled()
                            }
                            
                        }
                    }//onChange end
            return
        }
        
        setupInitialValuesWithBoard(editableBoard)
        self.currentBoard = editableBoard
        
        form +++
            Section(titleSectionTitle)
            <<< TextAreaRow(){$0.value = editableBoard.title}.onChange(){[unowned self] (textAreaRow) -> () in
                    if let titleText = textAreaRow.value
                    {
                        self.currentBoard?.title = titleText
                        self.checkSaveButtonEnabled()
                    }
                }
            +++
            Section(detailsSectionTitle)
            <<< TextAreaRow(){$0.value = editableBoard.details}.onChange(){ [unowned self](textAreaRow) -> () in
                    if let detailsText = textAreaRow.value
                    {
                        self.currentBoard?.details = detailsText
                    }
                    else
                    {
                        self.currentBoard?.details = ""
                    }
                    self.checkSaveButtonEnabled()
                }
        
    }

    private func setupInitialValuesWithBoard(board:TaskBoardInfo)
    {
        self.initialTitle = board.title
        self.initialDetails = board.details
    }
    
    private func checkSaveButtonEnabled()
    {
        guard let currentBoard = self.currentBoard else
        {
            self.navigationItem.rightBarButtonItem = nil
            return
        }
        
        if initialTitle == currentBoard.title && initialDetails == currentBoard.details
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        else if currentBoard.title == ""
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        else //set SAVE button visible
        {
            if self.navigationItem.rightBarButtonItem == nil
            {
                let saveBarButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveEdits:")
                self.navigationItem.rightBarButtonItem = saveBarButton
            }
        }
    }
    
    @IBAction func cancelBarButtonAction(sender:AnyObject?)
    {
        guard let aHandler = self.boardCloudHandler else
        {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        aHandler.cancelEditingBoard()
    }
    
    func saveEdits(sender:UIBarButtonItem)
    {
        if let board = self.currentBoard{
            switch self.editingType
            {
                case .EditCurrent(  _  ):
                    self.boardCloudHandler?.editBoard(board)
                case .CreateNew:
                    self.boardCloudHandler?.submitBoard(board)
            }
        }
        else
        {
            self.cancelBarButtonAction(nil)
        }
    }
    
    private func setNavigationTitle(text:String?)
    {
        self.navigationItem.title = text
    }
}

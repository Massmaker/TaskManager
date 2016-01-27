//
//  RecordIdIndexable.swift
//  TaskManager
//
//  Created by CloudCraft on 1/21/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit
protocol RecordIdIndexable {
    var recordId:CKRecordID?{get}
}

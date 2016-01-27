//
//  CloudRegisteredUsersOperation.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation


/**
 This operation periodically checks for cancellation status
 if operation is cancelled before the pint to call completion block, the completion block will not be called
*/
class CloudRegisteredUsersRequestOperation: NSOperation {
    
    private let phones:[String]
    private lazy var foundUserPhones = [String]()
    var requestCompletionBlock:((numbersToReturn:[String])->())?
    
    init(phoneNumbers:[String]) {
        self.phones = phoneNumbers
    }
    
//    override func start() {
//        print("CloudRegisteredUsersRequestOperation START called....")
//    }
    
    override func main() {
        
        print("CloudRegisteredUsersRequestOperation MAIN called....")
        
        if self.cancelled
        {
            ("CloudRegisteredUsersRequestOperation is cancelled")
            return
        }
        
        guard let cloudKitHandler = anAppDelegate()?.cloudKitHandler else
        {
            return
        }
        
        let semaphore = dispatch_semaphore_create(0)
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30))
        
        cloudKitHandler.startFetchingForRegisteredUsersByPhoneNumbers(phones) {[weak self] (foundNumbers, error) -> () in
            guard let weakSelf = self where !weakSelf.cancelled else
            {
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            self?.foundUserPhones = foundNumbers
            dispatch_semaphore_signal(semaphore)
        }
        
        let waitingResult = dispatch_semaphore_wait(semaphore, timeout)
        
        if waitingResult != 0
        {
            print(" - CloudRegisteredUsersRequestOperation cancelling after timeout 30 seconds")
            self.cancel()
        }
        
        if self.cancelled
        {
            return
        }
        
        print("sending registered user numbers from CloudRegisteredUsersRequestOperation")
        callCompletionBlock()
        print("CloudRegisteredUsersRequestOperation is finished")
        
    }
    
    private func callCompletionBlock()
    {
        requestCompletionBlock?(numbersToReturn:foundUserPhones)
    }
   
}
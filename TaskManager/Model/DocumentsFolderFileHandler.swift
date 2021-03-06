//
//  DocumentsFolderFIleHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class DocumentsFolderFileHandler: NSObject {

    func documentsDirectoryUrl() -> NSURL
    {
        let path = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        return path
    }
    
    func getAvatarImageFromDocumentsForUserId(userId:String) -> UIImage?
    {
        let imagePath = pathToUserPhotoById(userId)
        guard let data = NSData(contentsOfFile: imagePath), image = UIImage(data: data) else
        {
            return nil
        }
        
        return image
    }
    
    func saveAvatarImageToDocuments(image:UIImage, forUserId:String)
    {
        let dataToSave = UIImagePNGRepresentation(image)
        
        let filePath = pathToUserPhotoById(forUserId)
        
        dataToSave?.writeToFile(filePath, atomically: true)
    }
    
    func deleteAvatarImageForUserId(string:String)
    {
        let pathToDelete = pathToUserPhotoById(string)
        if NSFileManager.defaultManager().fileExistsAtPath(pathToDelete)
        {
            do{
                try NSFileManager.defaultManager().removeItemAtPath(pathToDelete)
            }
            catch let error
            {
                print(" - NSFileManager could not delete AvatarImage at for Id \(string):")
                print(error)
            }
            
        }
    }
    
    private func pathToUserPhotoById(userId:String) -> String
    {
        return documentsFolder().stringByAppendingPathComponent("\(userId).png")
    }
    
    private func documentsFolder() -> NSString
    {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory , NSSearchPathDomainMask.UserDomainMask, true).last! as NSString
    }
}

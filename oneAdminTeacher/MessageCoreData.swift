//
//  MessageCoreData.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/7/24.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class MessageCoreData{
    //Core Data using
    static func SaveCatchData(msg:MessageItem) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = NSPredicate(format: "id=%@", msg.Id)
        
        var needInsert = true
        
        //update
        if let fetchResults = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSManagedObject] {
            if fetchResults.count != 0 {
                
                let managedObject = fetchResults[0]
                
                //被改成已讀的才必須要更新
                if !msg.IsNew{
                    managedObject.setValue(msg.IsNew, forKey: "isNew")
                }
                
                //已經投過票必須要更新
                if msg.Voted{
                    managedObject.setValue(msg.Voted, forKey: "voted")
                }
                
                needInsert = false
            }
        }
        
        //insert
        if needInsert {
            let myEntityDescription = NSEntityDescription.entityForName("Message", inManagedObjectContext: managedObjectContext)
            
            let myObject = NSManagedObject(entity: myEntityDescription!, insertIntoManagedObjectContext: managedObjectContext)
            
            myObject.setValue(msg.Id, forKey: "id")
            myObject.setValue(msg.Date, forKey: "date")
            myObject.setValue(msg.IsNew, forKey: "isNew")
            myObject.setValue(msg.Title, forKey: "title")
            myObject.setValue(msg.Content, forKey: "content")
            myObject.setValue(msg.Redirect, forKey: "redirect")
            myObject.setValue(msg.DsnsName, forKey: "dsnsName")
            myObject.setValue(msg.Name, forKey: "name")
            myObject.setValue(msg.IsSender, forKey: "sender")
            myObject.setValue(msg.IsReceiver, forKey: "receiver")
            myObject.setValue(msg.Type, forKey: "type")
            myObject.setValue(msg.Voted, forKey: "voted")
        }
        
        do {
            try managedObjectContext.save()
        } catch _ {
        }
    }
    
    //Core Data using
    static func LoadCatchData() -> [MessageItem]{
        
        var retVal = [MessageItem]()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Message")
        
        var error: NSError?
        
        let results = (try! managedObjectContext.executeFetchRequest(fetchRequest)) as! [NSManagedObject]
        
        for obj in results {
            let id = obj.valueForKey("id") as! String
            let date = obj.valueForKey("date") as! NSDate
            let isNew = obj.valueForKey("isNew") as! Bool
            let title = (obj.valueForKey("title") as! String)
            let content = obj.valueForKey("content") as! String
            let redirect = obj.valueForKey("redirect") as! String
            let dsnsName = obj.valueForKey("dsnsName") as! String
            let name = obj.valueForKey("name") as! String
            let isSender = obj.valueForKey("sender") as! Bool
            let isReceiver = obj.valueForKey("receiver") as! Bool
            let type = obj.valueForKey("type") as! String
            let voted = obj.valueForKey("voted") as! Bool
            
            retVal.append(MessageItem(id: id, date: date, isNew: isNew, title: title, content: content, redirect: redirect, dsnsName: dsnsName, name: name, isSender: isSender, isReceiver: isReceiver, type: type, voted: voted))
            
            //_studentData.append(Student(Photo: UIImage(data: photo), ClassName : class_name, Name: name, Phone: phone))
        }
        
        retVal.sortInPlace({ $0.Date > $1.Date })
        
        return retVal
    }
    
    //Core Data using
    static func DeleteAll() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Message")
        
        let results = (try! managedObjectContext.executeFetchRequest(fetchRequest)) as! [NSManagedObject]
        
        for obj in results {
            managedObjectContext.deleteObject(obj)
        }
        
        do {
            try managedObjectContext.save()
        } catch _ {
        }
    }
    
    //Core Data using
    static func DeleteMessage(msg:MessageItem) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = NSPredicate(format: "id=%@", msg.Id)
        
        let results = (try! managedObjectContext.executeFetchRequest(fetchRequest)) as! [NSManagedObject]
        
        for obj in results {
            managedObjectContext.deleteObject(obj)
        }
        
        do {
            try managedObjectContext.save()
        } catch _ {
        }
    }
    
    static func GetCount() -> Int{
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Message")
        
        let results = (try! managedObjectContext.executeFetchRequest(fetchRequest)) as! [NSManagedObject]
        
        return results.count
    }
}
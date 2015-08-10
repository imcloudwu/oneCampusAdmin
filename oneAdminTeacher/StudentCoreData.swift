//
//  StudentCoreData.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/7/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class StudentCoreData{
    //Core Data using
    static func SaveCatchData(student:Student) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        
        //let fetchRequest = NSFetchRequest(entityName: "Student")
        //fetchRequest.predicate = NSPredicate(format: "dsns=%@ and id=%@", student.DSNS, student.ID)
        
        //    var needInsert = true
        //
        //    if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
        //        if fetchResults.count != 0 {
        //
        //            var managedObject = fetchResults[0]
        //            //managedObject.setValue(student.Name, forKey: "name")
        //            managedObject.setValue(student.ClassName, forKey: "class_name")
        //            managedObject.setValue(student.ContactPhone, forKey: "phone")
        //            managedObject.setValue(UIImagePNGRepresentation(student.Photo), forKey: "photo")
        //
        //            needInsert = false
        //        }
        //    }
        
        //if needInsert || forceInsert{
        let myEntityDescription = NSEntityDescription.entityForName("Student", inManagedObjectContext: managedObjectContext)
        
        let myObject = NSManagedObject(entity: myEntityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        myObject.setValue(student.DSNS, forKey: "dsns")
        myObject.setValue(student.ID, forKey: "id")
        myObject.setValue(student.Name, forKey: "name")
        //myObject.setValue(UIImagePNGRepresentation(student.Photo), forKey: "photo")
        //}
        
        managedObjectContext.save(nil)
    }
    
    //Core Data using
    static func LoadCatchData() -> [Student]{
        
        var retVal = [Student]()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Student")
        
        var error: NSError?
        
        let results = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]
        
        for obj in results {
            let id = obj.valueForKey("id") as! String
            let dsns = obj.valueForKey("dsns") as! String
            let name = obj.valueForKey("name") as! String
            
            retVal.append(Student(DSNS: dsns,ID: id, ClassID: nil, ClassName: nil, Name: name, SeatNo: nil, StudentNumber: nil, Gender: nil, MailingAddress: nil, PermanentAddress: nil, ContactPhone: nil, PermanentPhone: nil, CustodianName: nil, FatherName: nil, MotherName: nil, Photo: nil))
            
            //_studentData.append(Student(Photo: UIImage(data: photo), ClassName : class_name, Name: name, Phone: phone))
        }
        
        return retVal
    }
    
    //Core Data using
    static func DeleteAll() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Student")
        
        let results = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as![NSManagedObject]
        
        for obj in results {
            managedObjectContext.deleteObject(obj)
        }
        
        managedObjectContext.save(nil)
    }
    
    //Core Data using
    static func DeleteStudent(student:Student) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Student")
        fetchRequest.predicate = NSPredicate(format: "dsns=%@ and id=%@", student.DSNS, student.ID)
        
        let results = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as![NSManagedObject]
        
        for obj in results {
            managedObjectContext.deleteObject(obj)
        }
        
        managedObjectContext.save(nil)
    }
}
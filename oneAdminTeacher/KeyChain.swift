import UIKit
import Security

var kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

class Keychain {
    
    class func save(key: String, data: NSData) -> Bool {
        let query = [
            kSecClassValue : kSecClassGenericPasswordValue,
            kSecAttrAccountValue : key,
            kSecValueDataValue : data ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    class func load(key: String) -> NSData? {
        let query = [
            kSecClassValue       : kSecClassGenericPasswordValue,
            kSecAttrAccountValue : key,
            kSecReturnDataValue  : kCFBooleanTrue,
            kSecMatchLimitValue  : kSecMatchLimitOneValue ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef!.takeRetainedValue() as! NSData)
        } else {
            return nil
        }
    }
    
    class func delete(key: String) -> Bool {
        let query = [
            kSecClassValue       : kSecClassGenericPasswordValue,
            kSecAttrAccountValue : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    
    class func clear() -> Bool {
        let query = [ kSecClassValue : kSecClassGenericPasswordValue ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
}
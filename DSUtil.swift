//
//  Connection.swift
//  OneCampus
//
//  Created by Yao Ming Huang on 2015/6/11.
//  Copyright (c) 2015年 Yao Ming Huang. All rights reserved.
//

import Foundation
//import Bolts

let RawResponseKey: String = "RawResponseKey"

public class Connection {
    
    public static var Service = "DS.Base.Connect"
    
    init() {
    }
    
    public var accessPoint: String!
    
    public var physicalAccessPoint: String!
    
    public var targetContract: String!
    
    public var securityToken: String!
    
    public var sessionID: String!
    
    //    public func connect(accessPoint: String, targetContract: String, securityToken: String) -> BFTask {
    //        var task: BFTaskCompletionSource = BFTaskCompletionSource()
    //
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
    //            var err: DSFault!
    //
    //            self.connect(accessPoint, targetContract, securityToken, &err)
    //
    //            if err != nil {
    //                task.setError(NSError(domain: accessPoint, code: err.code.toInt()!, userInfo: [NSLocalizedDescriptionKey: err.message]))
    //            } else {
    //                task.setResult(self)
    //            }
    //        }
    //
    //        return task.task
    //    }
    
    public func connect(accessPoint: String, targetContract: String, _ securityToken: String,
        success: ((conn: Connection) -> Void)!,
        error: ((conn:Connection, error: DSFault!) ->Void)!) -> Void {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                var err: DSFault!
                
                let succ = self.connect(accessPoint, targetContract, securityToken, &err)
                
                if err != nil {
                    error?(conn: self, error: err)
                } else {
                    success?(conn: self)
                }
            }
            
    }
    
    public func connect(accessPoint: String, targetContract: String, userName: String, password: String, inout _ error: DSFault!) -> Bool{
        return connect(accessPoint, targetContract,
            SecurityToken.createBasicToken(userName, password: password), &error)
    }
    
    public func connect(accessPoint: String, _ targetContract: String, _ securityToken: String, inout _ error: DSFault!) -> Bool {
        var e: DSFault!
        
        self.accessPoint = accessPoint
        self.physicalAccessPoint = AccessPoint.Resolver(accessPoint, err: &e)
        self.targetContract = targetContract
        self.securityToken = securityToken
        
        //當 dsns 打錯時。
        if self.physicalAccessPoint == nil || self.physicalAccessPoint == "" {
            error = DSFault(source: e)
            error.code = AccessPoint.ResolverErrorCode
            error.message = "找不到資料中心的位置(\(accessPoint))。"
            
            return false
        }
        
        var fault: DSFault!
        let request = "<Body><RequestSessionID/></Body>"
        let response = sendRequest(self.securityToken,  Connection.Service, body: request, &fault)
        
        if let f = fault {
            error = f
            return false
        }
        
        //var nserr: NSError?
        let aersp: AEXMLDocument?
        do {
            aersp = try AEXMLDocument(xmlData: response.dataValue)
        } catch let e as NSError{
            aersp = nil
            error = DSFault()
            error.initWithNSError(e)
            return false
        }
        
        //        if nserr != nil {
        //            error = DSFault()
        //            error.initWithNSError(nserr!)
        //            return false
        //        }
        
        sessionID = aersp?.root["SessionID"].stringValue
        
        return true
    }
    
    func sendRequest(targetService: String,bodyContent: String!,inout _ error: DSFault!) -> String!{
        error = nil
        
        var req: String = ""
        
        if bodyContent != nil {
            req = bodyContent
        }
        
        let xml = sendRequestInternal(self.securityToken, targetService, body: "<Body>\(req)</Body>", &error)
        
        return xml?.xmlString
    }
    
    private func sendRequest(securityToken: String,_ targetService: String,body: String!,inout _ err: DSFault!) -> String!{
        err = nil
        
        var req: String = ""
        
        if body != nil {
            req = body
        }
        
        let xml = sendRequestInternal(securityToken, targetService, body: req, &err)
        
        return xml?.xmlString
    }
    
    private func sendRequestInternal(securityToken: String,_ targetService: String,body: String!,inout _ err: DSFault!) -> AEXMLElement!{
        
        var request: String!
        let token = securityToken
        
        if body != nil {
            request = Envelope.createRequest(targetContract, targetService,token,body: body)
        } else {
            request = Envelope.createRequest(targetContract, targetService,token,bodyContent: "")
        }
        
        var e: NSError?
        let rawrsp: NSData?
        do {
            rawrsp = try HttpClient.Post(physicalAccessPoint!, body: request)
        } catch var error as NSError {
            e = error
            rawrsp = nil
        }
        
        //實體位置有錯，或主機當了…
        if e != nil {
            err = DSFault()
            err.initWithNSError(e!)
            err.request = request
            err.url = physicalAccessPoint
            
            return nil
        }
        
        if let rsp = rawrsp {
            e = nil
            let xmldoc: AEXMLDocument?
            do {
                xmldoc = try AEXMLDocument(xmlData: rsp)
            } catch _ {
                xmldoc = nil
            }
            
            if e != nil {
                err = DSFault()
                err.initWithNSError(e!)
                err.request = request
                err.url = physicalAccessPoint
                
                return nil
            } else {
                
                if let envelope = xmldoc {
                    let code = xmldoc?.root["Header"]["Status"]["Code"].stringValue
                    
                    let intCode = Int((code)!)
                    
                    if intCode > 0 {
                        let msg = xmldoc?.root["Header"]["Status"]["Message"].stringValue
                        
                        err = DSFault()
                        err.initWithDSResponse(xmldoc!.root)
                        err.request = request
                        err.response = envelope.xmlString
                        err.url = physicalAccessPoint
                    } else {
                        return xmldoc?.root["Body"]
                    }
                    
                } else {
                    err = DSFault()
                    err.message = "爆炸了，非預期的爆炸。"
                    err.request = request
                    err.url = physicalAccessPoint
                }
                
                return nil
            }
        } else { // response 沒有回來
            err = DSFault()
            err.code = "999"
            err.message = "沒有 Response。"
            err.request = request
            
            return nil
        }
    }
}

public class AccessPoint {
    static var Service: String = "http://dsns.ischool.com.tw/dsns/dsns/DS.NameService.GetDoorwayURL"
    
    static let ResolverErrorCode: String = "601"
    
    public class func Resolver(dsns: String, inout err: DSFault!) -> String! {
        err = nil
        
        let lowdsns = dsns.lowercaseString
        
        //如果已經是 HTTP 就直接回傳，不需要再轉換。
        if(lowdsns.hasPrefix("http")) {
            return dsns
        }
        
        let geturl = "\(Service)?content=%3Ca%3E\(dsns)%3C/a%3E"
        var found: String = "";
        var e: NSError?
        
        let before = CFAbsoluteTimeGetCurrent()
        
        var data: NSData?
        do {
            data = try HttpClient.Get(geturl)
        } catch let error as NSError {
            e = error
            data = nil
        }
        
        let span = CFAbsoluteTimeGetCurrent() - before
        //println("DSNS Resolve Time(\(dsns))：\(span)")
        
        if e != nil {
            err = DSFault();
            err?.initWithNSError(e!)
            return nil
        }
        
        if let rsp = data {
            //let xml = SWXMLHash.parse(rsp)
            let xml: AEXMLDocument?
            do {
                xml = try AEXMLDocument(xmlData: rsp)
            } catch _ {
                xml = nil
            }
            
            if let url = xml?.root["Body"]["DoorwayURL"].stringValue{
                return url
            }
        }
        
        return nil
    }
}

public class Envelope {
    
    public static func createRequest(targetContract: String,_ targetService: String,_ securityToken: String,bodyContent: String) -> String{
        
        let request = "<Envelope><Header><TargetContract>\(targetContract)</TargetContract><TargetService>\(targetService)</TargetService>\(securityToken)</Header><Body>\(bodyContent)</Body></Envelope>"
        
        return request
    }
    
    public static func createRequest(targetContract: String,_ targetService: String,_ securityToken: String,body: String) -> String{
        
        let request = "<Envelope><Header><TargetContract>\(targetContract)</TargetContract><TargetService>\(targetService)</TargetService>\(securityToken)</Header>\(body)</Envelope>"
        
        return request
    }
}

public class SecurityToken {
    
    public class func createBasicToken(userName: String, password: String) -> String {
        let un = userName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let pwd = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        let template = "<SecurityToken Type=\"Basic\"><UserName>\(userName)</UserName><Password><![CDATA[\(password)]]></Password></SecurityToken>"
        
        return template
    }
    
    public class func createSessionToken(sessionId: String) -> String {
        let template = "<SecurityToken Type=\"Session\"><SessionID>\(sessionId)</SessionID></SecurityToken>"
        
        return template
    }
    
    public class func createOAuthToken(accessToken: String) -> String{
        let template = "<SecurityToken Type=\"PassportAccessToken\"><AccessToken>\(accessToken)</AccessToken></SecurityToken>"
        
        return template
    }
}

public class DSFault {
    
    public init() {
    }
    
    public init(source: DSFault?) {
        sourceFault = source
    }
    
    public init(msg: String) {
        message = msg
    }
    
    public func initWithNSError(err: NSError) {
        originNSError = err
        
        message = err.localizedDescription
        
        if err.userInfo.isEmpty {
            return
        }
        
        if let ns = err.userInfo["NSErrorFailingURLKey"] as? NSURL {
            url = "\(ns.absoluteString)"
        }
    }
    
    public func initWithDSResponse(envelope: AEXMLElement) {
        let status = envelope["Header"]["Status"]
        code = status["Code"].stringValue
        message = status["Message"].stringValue
    }
    
    public var url: String!
    
    public var code: String!
    
    public var message: String!
    
    public var request: String!
    
    public var response: String!
    
    public var sourceFault: DSFault!
    
    public var originNSError: NSError?
    
    public func toString() -> String{
        if self.sourceFault == nil {
            return self.message
        } else {
            let child = self.sourceFault.toString()
            return "\(self.message) \n\t \(child)"
        }
    }
}

//
// AEXML.swift
//
// Copyright (c) 2014 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

/**
 This is base class for holding XML structure.
 You can access its structure by using subscript like this:
 `element["foo"]["bar"]` would return `<bar></bar>` element from `<element><foo><bar></bar></foo></element>` XML as an `AEXMLElement` object.
 */
public class AEXMLElement: NSObject {
    
    // MARK: Properties
    
    /// Every `AEXMLElement` should have its parent element instead of `AEXMLDocument` which parent is `nil`.
    public private(set) weak var parent: AEXMLElement?
    
    /// Child XML elements.
    public private(set) var children: [AEXMLElement] = [AEXMLElement]()
    
    /// XML Element name (defaults to empty string).
    public var name: String
    
    /// XML Element value.
    public var value: String?
    
    /// XML Element attributes (defaults to empty dictionary).
    public var attributes: [String : String]
    
    /// String representation of `value` property (if `value` is `nil` this is empty String).
    public var stringValue: String { return value ?? String() }
    
    /// String representation of `value` property with special characters escaped (if `value` is `nil` this is empty String).
    public var escapedStringValue: String {
        // we need to make sure "&" is escaped first. Not doing this may break escaping the other characters
        var escapedString = stringValue.stringByReplacingOccurrencesOfString("&", withString: "&amp;", options: .LiteralSearch)
        
        // replace the other four special characters
        let escapeChars = ["<" : "&lt;", ">" : "&gt;", "'" : "&apos;", "\"" : "&quot;"]
        for (char, echar) in escapeChars {
            escapedString = escapedString.stringByReplacingOccurrencesOfString(char, withString: echar, options: .LiteralSearch)
        }
        
        return escapedString
    }
    
    /// Boolean representation of `value` property (if `value` is "true" or 1 this is `True`, otherwise `False`).
    public var boolValue: Bool { return stringValue.lowercaseString == "true" || Int(stringValue) == 1 ? true : false }
    
    /// Integer representation of `value` property (this is **0** if `value` can't be represented as Integer).
    public var intValue: Int { return Int(stringValue) ?? 0 }
    
    /// Double representation of `value` property (this is **0.00** if `value` can't be represented as Double).
    public var doubleValue: Double { return (stringValue as NSString).doubleValue }
    
    private struct Defaults {
        static let name = String()
        static let attributes = [String : String]()
    }
    
    // MARK: Lifecycle
    
    /**
    Designated initializer - all parameters are optional.
    
    :param: name XML element name.
    :param: value XML element value
    :param: attributes XML element attributes
    
    :returns: An initialized `AEXMLElement` object.
    */
    public init(_ name: String? = nil, value: String? = nil, attributes: [String : String]? = nil) {
        self.name = name ?? Defaults.name
        self.value = value
        self.attributes = attributes ?? Defaults.attributes
    }
    
    // MARK: XML Read
    
    /// This element name is used when unable to find element.
    public static let errorElementName = "AEXMLError"
    
    // The first element with given name **(AEXMLError element if not exists)**.
    public subscript(key: String) -> AEXMLElement {
        if name == AEXMLElement.errorElementName {
            return self
        } else {
            let filtered = children.filter { $0.name == key }
            return filtered.count > 0 ? filtered.first! : AEXMLElement(AEXMLElement.errorElementName, value: "element <\(key)> not found")
        }
    }
    
    /// Returns all of the elements with equal name as `self` **(nil if not exists)**.
    public var all: [AEXMLElement]? { return parent?.children.filter { $0.name == self.name } }
    
    /// Returns the first element with equal name as `self` **(nil if not exists)**.
    public var first: AEXMLElement? { return all?.first }
    
    /// Returns the last element with equal name as `self` **(nil if not exists)**.
    public var last: AEXMLElement? { return all?.last }
    
    /// Returns number of all elements with equal name as `self`.
    public var count: Int { return all?.count ?? 0 }
    
    private func allWithCondition(fulfillCondition: (element: AEXMLElement) -> Bool) -> [AEXMLElement]? {
        var found = [AEXMLElement]()
        if let elements = all {
            for element in elements {
                if fulfillCondition(element: element) {
                    found.append(element)
                }
            }
            return found.count > 0 ? found : nil
        } else {
            return nil
        }
    }
    
    /**
     Returns all elements with given value.
     
     :param: value XML element value.
     
     :returns: Optional Array of found XML elements.
     */
    public func allWithValue(value: String) -> [AEXMLElement]? {
        let found = allWithCondition { (element) -> Bool in
            return element.value == value
        }
        return found
    }
    
    /**
     Returns all elements with given attributes.
     
     :param: attributes Dictionary of Keys and Values of attributes.
     
     :returns: Optional Array of found XML elements.
     */
    public func allWithAttributes(attributes: [String : String]) -> [AEXMLElement]? {
        let found = allWithCondition { (element) -> Bool in
            var countAttributes = 0
            for (key, value) in attributes {
                if element.attributes[key] == value {
                    countAttributes++
                }
            }
            return countAttributes == attributes.count
        }
        return found
    }
    
    // MARK: XML Write
    
    /**
    Adds child XML element to `self`.
    
    :param: child Child XML element to add.
    
    :returns: Child XML element with `self` as `parent`.
    */
    public func addChild(child: AEXMLElement) -> AEXMLElement {
        child.parent = self
        children.append(child)
        return child
    }
    
    /**
     Adds child XML element to `self`.
     
     :param: name Child XML element name.
     :param: value Child XML element value.
     :param: attributes Child XML element attributes.
     
     :returns: Child XML element with `self` as `parent`.
     */
    public func addChild(name name: String, value: String? = nil, attributes: [String : String]? = nil) -> AEXMLElement {
        let child = AEXMLElement(name, value: value, attributes: attributes)
        return addChild(child)
    }
    
    /// Removes `self` from `parent` XML element.
    public func removeFromParent() {
        parent?.removeChild(self)
    }
    
    private func removeChild(child: AEXMLElement) {
        if let childIndex = children.indexOf(child) {
            children.removeAtIndex(childIndex)
        }
    }
    
    private var parentsCount: Int {
        var count = 0
        var element = self
        while let parent = element.parent {
            count++
            element = parent
        }
        return count
    }
    
    private func indentation(var count: Int) -> String {
        var indent = String()
        while count > 0 {
            indent += "\t"
            count--
        }
        return indent
    }
    
    /// Complete hierarchy of `self` and `children` in **XML** escaped and formatted String
    public var xmlString: String {
        var xml = String()
        
        // open element
        xml += indentation(parentsCount - 1)
        xml += "<\(name)"
        
        if attributes.count > 0 {
            // insert attributes
            for (key, value) in attributes {
                xml += " \(key)=\"\(value)\""
            }
        }
        
        if value == nil && children.count == 0 {
            // close element
            xml += " />"
        } else {
            if children.count > 0 {
                // add children
                xml += ">\n"
                for child in children {
                    xml += "\(child.xmlString)\n"
                }
                // add indentation
                xml += indentation(parentsCount - 1)
                xml += "</\(name)>"
            } else {
                // insert string value and close element
                xml += ">\(escapedStringValue)</\(name)>"
            }
        }
        
        return xml
    }
    
}

// MARK: -

/**
This class is inherited from `AEXMLElement` and has a few addons to represent **XML Document**.
XML Parsing is also done with this object.
*/
public class AEXMLDocument: AEXMLElement {
    
    // MARK: Properties
    
    /// This is only used for XML Document header (default value is 1.0).
    public let version: Double
    
    /// This is only used for XML Document header (default value is "utf-8").
    public let encoding: String
    
    /// This is only used for XML Document header (default value is "no").
    public let standalone: String
    
    /// Root (the first child element) element of XML Document **(AEXMLError element if not exists)**.
    public var root: AEXMLElement { return children.count == 1 ? children.first! : AEXMLElement(AEXMLElement.errorElementName, value: "XML Document must have root element.") }
    
    private struct Defaults {
        static let version = 1.0
        static let encoding = "utf-8"
        static let standalone = "no"
        static let documentName = "AEXMLDocument"
    }
    
    // MARK: Lifecycle
    
    /**
    Designated initializer - Creates and returns XML Document object.
    
    :param: version Version value for XML Document header (defaults to 1.0).
    :param: encoding Encoding value for XML Document header (defaults to "utf-8").
    :param: standalone Standalone value for XML Document header (defaults to "no").
    :param: root Root XML element for XML Document (defaults to `nil`).
    
    :returns: An initialized XML Document object.
    */
    public init(version: Double = Defaults.version, encoding: String = Defaults.encoding, standalone: String = Defaults.standalone, root: AEXMLElement? = nil) {
        // set document properties
        self.version = version
        self.encoding = encoding
        self.standalone = standalone
        
        // init super with default name
        super.init(Defaults.documentName)
        
        // document has no parent element
        parent = nil
        
        // add root element to document (if any)
        if let rootElement = root {
            addChild(rootElement)
        }
    }
    
    /**
     Convenience initializer - used for parsing XML data (by calling `loadXMLData:` internally).
     
     :param: version Version value for XML Document header (defaults to 1.0).
     :param: encoding Encoding value for XML Document header (defaults to "utf-8").
     :param: standalone Standalone value for XML Document header (defaults to "no").
     :param: xmlData XML data to parse.
     :param: error If there is an error reading in the data, upon return contains an `NSError` object that describes the problem.
     
     :returns: An initialized XML Document object containing the parsed data. Returns `nil` if the data could not be parsed.
     */
    public convenience init(version: Double = Defaults.version, encoding: String = Defaults.encoding, standalone: String = Defaults.standalone, xmlData: NSData) throws {
        self.init(version: version, encoding: encoding, standalone: standalone)
        try loadXMLData(xmlData)
    }
    
    // MARK: Read XML
    
    /**
    Creates instance of `AEXMLParser` (private class which is simple wrapper around `NSXMLParser`) and starts parsing the given XML data.
    
    :param: data XML which should be parsed.
    
    :returns: `NSError` if parsing is not successfull, otherwise `nil`.
    */
    public func loadXMLData(data: NSData) throws {
        children.removeAll(keepCapacity: false)
        let xmlParser = AEXMLParser(xmlDocument: self, xmlData: data)
        try xmlParser.parse()
    }
    
    // MARK: Override
    
    /// Override of `xmlString` property of `AEXMLElement` - it just inserts XML Document header at the beginning.
    public override var xmlString: String {
        var xml =  "<?xml version=\"\(version)\" encoding=\"\(encoding)\" standalone=\"\(standalone)\"?>\n"
        for child in children {
            xml += child.xmlString
        }
        return xml
    }
    
}

// MARK: -

private class AEXMLParser: NSObject, NSXMLParserDelegate {
    
    // MARK: Properties
    
    let xmlDocument: AEXMLDocument
    let xmlData: NSData
    
    var currentParent: AEXMLElement?
    var currentElement: AEXMLElement?
    var currentValue = String()
    var parseError: NSError?
    
    // MARK: Lifecycle
    
    init(xmlDocument: AEXMLDocument, xmlData: NSData) {
        self.xmlDocument = xmlDocument
        self.xmlData = xmlData
        currentParent = xmlDocument
        super.init()
    }
    
    // MARK: XML Parse
    
    func parse() throws {
        let parser = NSXMLParser(data: xmlData)
        parser.delegate = self
        let success = parser.parse()
        if !success {
            throw parseError ?? NSError(domain: "net.tadija.AEXML", code: 1, userInfo: nil)
        }
    }
    
    // MARK: NSXMLParserDelegate
    
    @objc func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentValue = String()
        currentElement = currentParent?.addChild(name: elementName, attributes: attributeDict)
        currentParent = currentElement
    }
    
    @objc func parser(parser: NSXMLParser, foundCharacters string: String) {
        currentValue += string
        let newValue = currentValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        currentElement?.value = newValue == String() ? nil : newValue
    }
    
    @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentParent = currentParent?.parent
        currentElement = nil
    }
    
    @objc func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.parseError = parseError
    }
    
}
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
        
        var nserr: NSError?
        let aersp = AEXMLDocument(xmlData: response.dataValue, error: &nserr)
        
        if nserr != nil {
            error = DSFault()
            error.initWithNSError(nserr!)
            return false
        }
        
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
        let rawrsp = HttpClient.Post(physicalAccessPoint!, body: request, err: &e)
        
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
            let xmldoc = AEXMLDocument(xmlData: rsp, error: &e)
            
            if e != nil {
                err = DSFault()
                err.initWithNSError(e!)
                err.request = request
                err.url = physicalAccessPoint
                
                return nil
            } else {
                
                if let envelope = xmldoc {
                    let code = xmldoc?.root["Header"]["Status"]["Code"].stringValue
                    
                    let intCode = code?.toInt()
                    
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
        
        var data = HttpClient.Get(geturl, err: &e)
        
        let span = CFAbsoluteTimeGetCurrent() - before
        println("DSNS Resolve Time(\(dsns))：\(span)")
        
        if e != nil {
            err = DSFault();
            err?.initWithNSError(e!)
            return nil
        }
        
        if let rsp = data {
            //let xml = SWXMLHash.parse(rsp)
            let xml = AEXMLDocument(xmlData: rsp, error: &e)
            
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
        
        var template = "<SecurityToken Type=\"Basic\"><UserName>\(userName)</UserName><Password><![CDATA[\(password)]]></Password></SecurityToken>"
        
        return template
    }
    
    public class func createSessionToken(sessionId: String) -> String {
        var template = "<SecurityToken Type=\"Session\"><SessionID>\(sessionId)</SessionID></SecurityToken>"
        
        return template
    }
    
    public class func createOAuthToken(accessToken: String) -> String{
        var template = "<SecurityToken Type=\"PassportAccessToken\"><AccessToken>\(accessToken)</AccessToken></SecurityToken>"
        
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
        
        if err.userInfo == nil {
            return
        }
        
        if let ns = err.userInfo!["NSErrorFailingURLKey"] as? NSURL {
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

// MARK: Equatable

private func !=(lhs: [NSObject: AnyObject], rhs: [NSObject: AnyObject]) -> Bool {
    for (key, lhsValue) in lhs {
        if let rhsValue: AnyObject = rhs[key] {
            if !(lhsValue === rhsValue) { return true }
        } else { return true }
    }
    return false
}

public func ==(lhs: AEXMLElement, rhs: AEXMLElement) -> Bool {
    if lhs.name != rhs.name { return false }
    if lhs.value != rhs.value { return false }
    if lhs.parent != rhs.parent { return false }
    if lhs.children != rhs.children { return false }
    if lhs.attributes != rhs.attributes { return false }
    return true
}

public class AEXMLElement: Equatable {
    
    // MARK: Properties
    
    public private(set) weak var parent: AEXMLElement?
    public private(set) var children: [AEXMLElement] = [AEXMLElement]()
    
    public let name: String
    public var value: String?
    public private(set) var attributes: [NSObject : AnyObject]
    
    public var stringValue: String {
        return value ?? String()
    }
    public var boolValue: Bool {
        return stringValue.lowercaseString == "true" || stringValue.toInt() == 1 ? true : false
    }
    public var intValue: Int {
        return stringValue.toInt() ?? 0
    }
    public var doubleValue: Double {
        return (stringValue as NSString).doubleValue
    }
    
    // MARK: Lifecycle
    
    public init(_ name: String, value: String? = nil, attributes: [NSObject : AnyObject] = [NSObject : AnyObject]()) {
        self.name = name
        self.value = value
        self.attributes = attributes
    }
    
    // MARK: XML Read
    
    // this element name is used when unable to find element
    public class var errorElementName: String { return "AEXMLError" }
    
    // non-optional first element with given name (<error> element if not exists)
    public subscript(key: String) -> AEXMLElement {
        if name == AEXMLElement.errorElementName {
            return self
        } else {
            let filtered = children.filter { $0.name == key }
            //return filtered.count > 0 ? filtered.first! : AEXMLElement(AEXMLElement.errorElementName, value: "element <\(key)> not found")
            return filtered.count > 0 ? filtered.first! : AEXMLElement(AEXMLElement.errorElementName, value: "")
        }
    }
    
    public var all: [AEXMLElement]? {
        return parent?.children.filter { $0.name == self.name }
    }
    
    public var first: AEXMLElement? {
        return all?.first
    }
    
    public var last: AEXMLElement? {
        return all?.last
    }
    
    public var count: Int {
        return all?.count ?? 0
    }
    
    public func allWithAttributes <K: NSObject, V: AnyObject where K: Equatable, V: Equatable> (attributes: [K : V]) -> [AEXMLElement]? {
        var found = [AEXMLElement]()
        if let elements = all {
            for element in elements {
                var countAttributes = 0
                for (key, value) in attributes {
                    if element.attributes[key] as? V == value {
                        countAttributes++
                    }
                }
                if countAttributes == attributes.count {
                    found.append(element)
                }
            }
            return found.count > 0 ? found : nil
        } else {
            return nil
        }
    }
    
    public func countWithAttributes <K: NSObject, V: AnyObject where K: Equatable, V: Equatable> (attributes: [K : V]) -> Int {
        return allWithAttributes(attributes)?.count ?? 0
    }
    
    // MARK: XML Write
    
    public func addChild(child: AEXMLElement) -> AEXMLElement {
        child.parent = self
        children.append(child)
        return child
    }
    
    public func addChild(#name: String, value: String? = nil, attributes: [NSObject : AnyObject] = [NSObject : AnyObject]()) -> AEXMLElement {
        let child = AEXMLElement(name, value: value, attributes: attributes)
        return addChild(child)
    }
    
    public func addAttribute(name: NSObject, value: AnyObject) {
        attributes[name] = value
    }
    
    public func addAttributes(attributes: [NSObject : AnyObject]) {
        for (attributeName, attributeValue) in attributes {
            addAttribute(attributeName, value: attributeValue)
        }
    }
    
    public func removeFromParent() {
        parent?.removeChild(self)
    }
    
    private func removeChild(child: AEXMLElement) {
        if let childIndex = find(children, child) {
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
    
    private func indentation(count: Int) -> String {
        var indent = String()
        if count > 0 {
            for i in 0..<count {
                indent += "\t"
            }
        }
        return indent
    }
    
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
                xml += ">\(stringValue)</\(name)>"
            }
        }
        
        return xml
    }
    
    public var xmlStringCompact: String {
        let chars = NSCharacterSet(charactersInString: "\n\t")
        return join("", xmlString.componentsSeparatedByCharactersInSet(chars))
    }
}

// MARK: -

public class AEXMLDocument: AEXMLElement {
    
    // MARK: Properties
    
    public let version: Double
    public let encoding: String
    public let standalone: String
    
    public var root: AEXMLElement {
        return children.count == 1 ? children.first! : AEXMLElement(AEXMLElement.errorElementName, value: "XML Document must have root element.")
    }
    
    // MARK: Lifecycle
    
    public init(version: Double = 1.0, encoding: String = "utf-8", standalone: String = "no", root: AEXMLElement? = nil) {
        // set document properties
        self.version = version
        self.encoding = encoding
        self.standalone = standalone
        
        // init super with default name
        super.init("AEXMLDocument")
        
        // document has no parent element
        parent = nil
        
        // add root element to document (if any)
        if let rootElement = root {
            addChild(rootElement)
        }
    }
    
    public convenience init?(version: Double = 1.0, encoding: String = "utf-8", standalone: String = "no", xmlData: NSData, inout error: NSError?) {
        self.init(version: version, encoding: encoding, standalone: standalone)
        if let parseError = readXMLData(xmlData) {
            error = parseError
            return nil
        }
    }
    
    // MARK: Read XML
    
    public func readXMLData(data: NSData) -> NSError? {
        children.removeAll(keepCapacity: false)
        let xmlParser = AEXMLParser(xmlDocument: self, xmlData: data)
        return xmlParser.tryParsing() ?? nil
    }
    
    // MARK: Override
    
    public override var xmlString: String {
        var xml =  "<?xml version=\"\(version)\" encoding=\"\(encoding)\" standalone=\"\(standalone)\"?>\n"
        for child in children {
            xml += child.xmlString
        }
        return xml
    }
    
}

// MARK: -

class AEXMLParser: NSObject, NSXMLParserDelegate {
    
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
    
    func tryParsing() -> NSError? {
        var success = false
        let parser = NSXMLParser(data: xmlData)
        parser.delegate = self
        success = parser.parse()
        return success ? nil : parseError
    }
    
    // MARK: NSXMLParserDelegate
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        currentValue = String()
        currentElement = currentParent?.addChild(name: elementName, attributes: attributeDict)
        currentParent = currentElement
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        currentValue += string ?? String()
        let newValue = currentValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        currentElement?.value = newValue == String() ? nil : newValue
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentParent = currentParent?.parent
        currentElement = nil
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.parseError = parseError
    }
    
}
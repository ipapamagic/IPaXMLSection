//
//  IPaXMLSection.swift
//  IPaXMLSection
//
//  Created by IPa Chen on 2020/7/21.
//

import UIKit
import libxml2
import IPaLog

open class IPaXMLSection: NSObject {
    
    open var name:String = ""
    open var value:String = ""
    open var attributes = [String:String]()
    open var children = [IPaXMLSection]()
    public override init() {
        super.init()
    }
    public init?(_ fileName:String) {
        super.init()
        guard let reader = xmlNewTextReaderFilename(fileName.cString(using: .utf8)) else {
            IPaLog("failed tp create xmlTextReader")
            return nil
        }
        defer {
            xmlFreeTextReader(reader)
        }
        if xmlTextReaderSetParserProp(reader, Int32(XML_PARSER_VALIDATE.rawValue), 1) != 0 {
            IPaLog("Validate error!!")
            return nil
        }
        if !self.readXMLStartElementNode(reader) {
            IPaLog("Read error!!")
            return nil
        }
        if !self.readXMLText(reader) {
            IPaLog("Read Node Error!!")
            return nil
        }
        
    }
    public init?(_ xmlData:Data) {
        super.init()
        let nsXMLData = xmlData as NSData
        guard let reader = xmlReaderForMemory(nsXMLData.bytes.bindMemory(to: Int8.self, capacity: 1), Int32(nsXMLData.length), nil, nil, Int32(XML_PARSE_NOBLANKS.rawValue | XML_PARSE_NOCDATA.rawValue)) else {
            IPaLog("Failed to create xmlTextReader")
            return nil
        }
        defer {
            xmlFreeTextReader(reader)
        }
        if xmlTextReaderSetParserProp(reader, Int32(XML_PARSER_VALIDATE.rawValue), 1) != 0 {
            IPaLog("Validate error!!")
            return nil
        }
        if !self.readXMLStartElementNode(reader) {
            IPaLog("Read error!!")
            return nil
        }
        if !self.readXMLText(reader) {
            IPaLog("Read Node Error!!")
            return nil
        }
    }
    init?(with reader:xmlTextReaderPtr) {
        super.init()
        if !self.readXMLText(reader) {
            return nil
        }
    }
    init?(_ xmlNode:xmlNodePtr) {
        super.init()
        if !self.readXMLNode(xmlNode) {
            IPaLog("Read XML Node Error!")
            return nil
        }
    }
}
//MARK - open func for reading
extension IPaXMLSection {
    open var jsonObject:[String:[String:Any]] {
        var obj = [String:[String:Any]]()
        var content = [String:Any]()
        for (key,value) in self.attributes {
            content[key] = value
        }
        for child in self.children {
            let childObj = child.jsonObject
            guard let (key,value) = childObj.first else {
                continue
            }
            if let oValue = content[key] {
                if var listValue = oValue as? [Any] {
                    listValue.append(value)
                    content[key] = listValue
                }
                else {
                    content[key] = [oValue,value]
                }
            }
            else {
                content[key] = value
            }
        }
        if self.value.count > 0 {
            content["_content"] = self.value
        }
        obj[self.name] = content
        return obj
    }
    open var asString:String {
        return self.asString(with: 0)
    }
    open var asXMLFormatString:String {
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + self.asString
    }
    open var childrenDictionary:[String:String] {
        return self.children.reduce([String:String]()) { (dict, section) in
            var dict = dict
            dict[section.name] = section.value
            return dict
        }
    }
    open func firstSection(with key:String) -> IPaXMLSection? {
        return self.children.first { (section) -> Bool in
            return section.name == key
        }
    }
    open func firstValue(with key:String) -> String {
        guard let section = self.firstSection(with: key) else {
            return ""
        }
        return section.value
    }
    open func values(with key:String) -> [String] {
        return self.children.compactMap { section in
            return (section.name == key) ? section.value : nil
        }
    }
    open func sections(with key:String) -> [IPaXMLSection] {
        return self.children.filter { section in
            return section.name == key
        }
    }
    func asString(with level:Int) -> String {
        var tabString = ""
        var retString = ""
        if level > 0 {
            for _ in 0 ..< level {
                tabString += "\t"
            }
        }
        let attrList = self.attributes.map { (key,value) in
            return "\(key)=\(value)"
        }
        let attr = attrList.joined(separator: " ")
        retString = "\(tabString)<\(self.name) \(attr)"
        if self.children.count == 0 {
            if self.value.count == 0 {
                retString += "/>\n"
            }
            else {
                retString += ">\t\(self.value)\t</\(self.name)>\n"
            }
            return retString
        }
        else {
            if self.value.count > 0 {
                retString += ">\t\(self.value)\n"
                    
            }
            else {
                retString += ">\n"
            }
                
            for subSection in self.children {
                retString += subSection.asString(with: level+1)
            }
        }
        retString += "\(tabString)</\(self.name)>\n"
        return retString
    }
    
    
}
//MARK - XML api
extension IPaXMLSection {
    func readXMLNode(_ nodePtr:xmlNodePtr) -> Bool {
        var node = nodePtr.pointee
        if node.type == XML_DOCUMENT_NODE {
            //document 直接找子node，找到第一個ELEMENT 為止
            
            var nodePointer = node.children
            
            while let nodePtr = nodePointer {
                node = nodePtr.pointee
                if node.type == XML_ELEMENT_NODE {
                    break;
                }
                nodePointer = node.next
            }
            if (nodePointer == nil) {
                return false
            }
            
        }
        else if (node.type != XML_ELEMENT_NODE) {
            //start node must be Element node
            return false
        }
        
        guard let nodeName = String(node.name),nodeName.count > 0 else {
            IPaLog("Node Must have a Name!")
            return false
        }
        self.name = nodeName
        //read attribute
        var attributePtr = node.properties
        while attributePtr != nil
        {
            let attribute = attributePtr!.pointee
            let attributeName = String(attribute.name)
            if let attrChildNode = attribute.children
            {
                if attrChildNode.pointee.type != XML_TEXT_NODE {
                    //something wrong....
                    IPaLog("Attribute Error!");
                    attributePtr = attribute.next
                    continue
                }
                if let attributeName = attributeName,let valueString = String(attrChildNode.pointee.content) {
                    self.attributes[attributeName] = valueString
                
                }
            }
            else
            {
                //something wrong....
                IPaLog("Attribute Error!");
            }
            attributePtr = attribute.next
        
        }
            
        
        //read children node
        var childNodePtr = node.children
        if (childNodePtr != nil) {
            //the first child should be Value
            let childNode = childNodePtr!.pointee
            if childNode.type == XML_TEXT_NODE {
                self.value = String(childNode.content) ?? ""
                childNodePtr = childNode.next
            }
            
            while childNodePtr != nil {
                let childNode = childNodePtr!.pointee
                
                if childNode.type == XML_ELEMENT_NODE,let section = IPaXMLSection(childNodePtr!) {
                    self.children.append(section)
                    
                }
                childNodePtr = childNode.next
            }
        }
        return true
    }
    func readXMLStartElementNode(_ reader:xmlTextReaderPtr) -> Bool
    {
        
        if xmlTextReaderRead(reader) != 1 {
            return false
        }
        
        //    NodeType: The node type
        //    1 for start element
        //    15 for end of element
        //    2 for attributes
        //    3 for text nodes
        //    4 for CData sections
        //    5 for entity references
        //    6 for entity declarations
        //    7 for PIs
        //    8 for comments
        //    9 for the document nodes
        //    10 for DTD/Doctype nodes
        //    11 for document fragment
        //    12 for notation nodes.
        // I test my self 14 like /n
        var nodeType = xmlTextReaderNodeType(reader)
    
        while nodeType != 1 {
            //found next start element
            if xmlTextReaderRead(reader) != 1
            {
                return false
            }
            nodeType = xmlTextReaderNodeType(reader)
        }
        return true
    }
    func readXMLText(_ reader:xmlTextReaderPtr) -> Bool
    {
        //when come here ,the node must be start element
        
        guard let name = xmlTextReaderName(reader) else {
            //   name = xmlStrdup(BAD_CAST "--");
            return false
        }
        self.name = name.withMemoryRebound(to: CChar.self, capacity: 1) { return String(validatingUTF8: $0)
        } ?? ""
        xmlFree(name)
        
        let isEmptyElement = xmlTextReaderIsEmptyElement(reader)
        //read Attribute
        let attributeNum = xmlTextReaderAttributeCount(reader)
        if attributeNum > 0 {
            if xmlTextReaderMoveToFirstAttribute(reader) > 0 {
                
                //read attribute
                repeat {
                    let nodeType = xmlTextReaderNodeType(reader);
                    if nodeType != 2 {
                        continue;
                    }
                    if let name = xmlTextReaderName(reader), let value = xmlTextReaderValue(reader),let attrName = String(name),let attrValue = String(value) {
                        self.attributes[attrName] = attrValue
                        xmlFree(name)
                        xmlFree(value)
                    }
                } while xmlTextReaderMoveToNextAttribute(reader) > 0
            }
        }
        
        if isEmptyElement <= 0 {
            if xmlTextReaderRead(reader) == 1 {
                
                if xmlTextReaderNodeType(reader) == 3 {
                    if xmlTextReaderHasValue(reader) > 0 {
                        if let value = xmlTextReaderValue(reader),let valueString = String(value) {
                            
                            self.value = valueString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            xmlFree(value);
                        }
                        if xmlTextReaderRead(reader) != 1{
                            return false
                        }
                    }
                }
            }
            else {
                return false
            }
            
            var result:Int32 = 0
            repeat{
                //check end node
                let nodeType = xmlTextReaderNodeType(reader)
                switch nodeType {
                    case 15:
                        //should go out from here
                        return true
                    case 1:
                    
                        // new sub node
                        if let newSection = IPaXMLSection(with: reader)
                        {
                            self.children.append(newSection)
                        }
                    default:
                        break;
                }
                result = xmlTextReaderRead(reader)
            }while result == 1
            //can not find end tag
            return false
        }
        return true
    }
}
extension IPaXMLSection:NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let section = IPaXMLSection()
        section.name = self.name
        section.value = self.value;
        section.attributes = self.attributes
        
        for child in self.children {
            section.children.append(child.copy() as! IPaXMLSection)
        }
        return section
    }
}

//
//  IPaXMLParser.swift
//  IPaXMLSection
//
//  Created by IPa Chen on 2020/7/21.
//

import UIKit
import libxml2
import IPaLog
public class IPaXMLParser {
    init() {
        xmlInitParser()
    }
    deinit {
        xmlCleanupParser()
    }
    open func parseXML(_ fileName:String,with xpath:String) -> [IPaXMLSection] {
        
        guard let doc:xmlDocPtr = xmlParseFile(fileName.cString(using: .utf8)) else {
            IPaLog("unable to parse file:\(fileName)")
            return [IPaXMLSection]()
        }
        defer {
            xmlFreeDoc(doc)
        }
        return parseXML(xmlDocument:doc,with:xpath)

    }
    func parseXML(xmlDocument doc:xmlDocPtr,with xpath:String) -> [IPaXMLSection] {
        /* Create xpath evaluation context */
        guard let xpathCtx = xmlXPathNewContext(doc) else {
            IPaLog("Error: unable to create new XPath context")
            return [IPaXMLSection]()
        }
        defer {
            xmlXPathFreeContext(xpathCtx)
        }
        let xpathExpr = xpath.utf8CString.map{ xmlChar(bitPattern: $0) }
        guard let xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx),let nodes = xpathObj.pointee.nodesetval else {
            IPaLog("Error: unable to evaluate xpath expression \"\(xpathExpr)\"\n")
            return [IPaXMLSection]()
        }
        defer {
            xmlXPathFreeObject(xpathObj)
        }
        let nodeSet = nodes.pointee
        //process node
        var resultNodes = [IPaXMLSection]()
        for idx in 0 ..< nodeSet.nodeNr {
            guard let nodePtr = nodeSet.nodeTab[Int(idx)],let section = IPaXMLSection(nodePtr) else {
                continue
            }
            resultNodes.append(section)
        }
        return resultNodes
    }
    func parseXML(_ data:Data,with xpath:String) -> [IPaXMLSection] {
        /* Load XML document */
        let nsData = data as NSData
        guard let doc =  xmlReadMemory(nsData.bytes.bindMemory(to: CChar.self, capacity: 1), Int32(nsData.length), "", nil, Int32(XML_PARSE_RECOVER.rawValue)) else {
            IPaLog("Unable to parse.")
            return [IPaXMLSection]()
        }
        defer {
            xmlFreeDoc(doc)
        }
        return self.parseXML(xmlDocument: doc, with: xpath)
    }
}

//
//  IPaHTMLSection.swift
//  IPaXMLSection
//
//  Created by IPa Chen on 2020/7/21.
//

import UIKit
import libxml2
import IPaLog
open class IPaHTMLSection: IPaXMLSection {
    public override init?(_ xmlData: Data) {
        
        let nsXmlData = xmlData as NSData
        guard let utf8Data = "UTF-8".data(using: .utf8, allowLossyConversion: false) ,let doc = htmlParseDoc(nsXmlData.bytes.bindMemory(to: xmlChar.self, capacity: 1), (utf8Data as NSData).bytes.bindMemory(to: Int8.self, capacity:1)),let root = xmlDocGetRootElement(doc) else {
            IPaLog("Failed to parse html!")
            return nil
        }
        super.init(root)
    }
    public override init?(_ fileName: String) {
        guard let utf8Data = "UTF-8".data(using: .utf8, allowLossyConversion: false), let doc = htmlParseFile(fileName.cString(using: .utf8), (utf8Data as NSData).bytes.bindMemory(to: Int8.self, capacity:1)),let root = xmlDocGetRootElement(doc) else {
            IPaLog("Failed to parse html!")
            return nil
        }
        super.init(root)
    }
    
}

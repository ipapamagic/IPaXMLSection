//
//  String+IPaXMLSection.swift
//  IPaXMLSection
//
//  Created by IPa Chen on 2020/7/21.
//

import UIKit
import libxml2
extension String {
    init?(_ xmlCharString:UnsafePointer<xmlChar>) {
        
        guard let string = xmlCharString.withMemoryRebound(to: CChar.self, capacity: 1, {
            return String(validatingUTF8: $0)
        }) else  {
            return nil
        }
        self = string
    }
}


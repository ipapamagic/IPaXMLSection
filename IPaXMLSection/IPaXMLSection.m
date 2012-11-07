//
//  IPaXMLSection.m
//  IPaXMLSection
//
//  Created by IPaPa on 11/12/29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IPaXMLSection.h"
#include <libxml/xmlreader.h>

@implementation IPaXMLSection
-(id)initWithXMLFile:(NSString*)fileName
{
    self = [super init];
    
    
    xmlTextReaderPtr reader = xmlNewTextReaderFilename([fileName cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!reader) {
        NSLog(@"Failed to create xmlTextReader");
        return nil;
    }
    if  (xmlTextReaderSetParserProp(reader, XML_PARSER_VALIDATE, 1) != 0)
    {
        NSLog(@"Validate error!!");
        return nil;
    }
    if (![self readXMLStartElementNode:reader]) {
        NSLog(@"Read Error!!");
        xmlFreeTextReader(reader);
        return nil;
        
    }
    if (![self readXMLTextReader:reader]) {
        NSLog(@"Read Node Error!!");
        xmlFreeTextReader(reader);
        self.Name = nil;
        self.Value = nil;
        self.attributes = nil;
        self.children = nil;
        return nil;
    }
    
    xmlFreeTextReader(reader);
    return self;
}
-(id)initWithXMLData:(NSData*)data
{
    self = [super init];
    
    
    xmlTextReaderPtr reader = xmlReaderForMemory([data bytes], [data length], NULL, NULL, (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA));// | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
    if (!reader) {
        NSLog(@"Failed to create xmlTextReader");
        return nil;
    }
    if  (xmlTextReaderSetParserProp(reader, XML_PARSER_VALIDATE, 1) != 0)
    {
        NSLog(@"Validate error!!");
        xmlFreeTextReader(reader);
        return nil;
    }
    
    if (![self readXMLStartElementNode:reader]) {
        NSLog(@"Read Error!!");
        xmlFreeTextReader(reader);
        return nil;
        
    }
    if (![self readXMLTextReader:reader]) {
        NSLog(@"Read Node Error!!");
        xmlFreeTextReader(reader);
        
        return nil;
    }
    
    
    
    xmlFreeTextReader(reader);
    
    return self;
}
-(id)initWithXMLNode:(xmlNodePtr)node
{
    self = [super init];
    
    
    
    
    if (![self readXMLNode:node]) {
        NSLog(@"Read XML Node Error!");
        return nil;
    }
    
    return self;
}
-(IPaXMLSection*)FirstSectionWithKey:(NSString*)key
{
    for (IPaXMLSection* section in self.children) {
        if ([section.Name isEqualToString:key]) {
            return section;
        }
    }
    return nil;
}

-(NSString *)ReadFirstChildValue:(NSString*)key
{
    IPaXMLSection *subSec = [self FirstSectionWithKey:key];
    
    return (subSec == nil)?@"":subSec.Value;
}

-(NSArray*)ReadChildrenValue:(NSString*)key
{
    NSMutableArray *listArray = [NSMutableArray arrayWithCapacity:self.children.count];
    for (IPaXMLSection* section in self.children) {
        if ([section.Name isEqualToString:key]) {
            if (section.Value != nil) {
                [listArray addObject:section.Value];
            }
        }
    }
    return listArray;
    
}
-(NSArray*)SectionsWithKey:(NSString*)key
{
    NSMutableArray *array = [NSMutableArray array];
    for (IPaXMLSection* section in self.children) {
        if ([section.Name isEqualToString:key]) {
            [array addObject:section];
        }
    }
    return array;
}

-(NSDictionary*)childrenAsDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.children.count];
    for (IPaXMLSection* section in self.children) {
        [dict setObject:section.Value forKey:section.Name];
    }
    return dict;
}

#pragma mark - XMLNodeAPI
-(BOOL)readXMLNode:(xmlNodePtr)node
{
    if (node->type == XML_DOCUMENT_NODE) {
        //document 直拉找子node，找到第一個ELEMENT 為止
        node = node->children;
        
        while (node) {
            if (node->type == XML_ELEMENT_NODE) {
                break;
            }
            node = node->next;
        }
        if (node == NULL) {
            return NO;
        }
        
    }
    else if (node->type != XML_ELEMENT_NODE) {
        //start node must be Element node
        return NO;
    }
    if (node->name == NULL) {
        NSLog(@"Node Must have a Name!");
        return NO;
    }
    self.Name = [NSString stringWithCString:(const char*)node->name encoding:NSUTF8StringEncoding];
    //read attribute
    xmlAttr *attribute = node->properties;
	if (attribute)
	{
        self.attributes = [NSMutableDictionary dictionary];
		while (attribute)
		{
            NSString *attributeName =
            [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
            
			if (attribute->children)
			{
                xmlNodePtr attrChildNode = attribute->children;
                if (attrChildNode->type != XML_TEXT_NODE) {
                    //something wrong....
                    NSLog(@"Attribute Error!");
                    attribute = attribute->next;
                    continue;
                }
                
                NSString *attrValue = (attrChildNode->content != NULL)?[NSString stringWithCString:(const char*)attrChildNode->content encoding:NSUTF8StringEncoding]:@"";
                
                
				[self.attributes setObject:attrValue forKey:attributeName];
			}
            else
            {
                //something wrong....
                NSLog(@"Attribute Error!");
                attribute = attribute->next;
                continue;
            }
            attribute = attribute->next;
            
		}
	}
    //read children node
    xmlNodePtr childNode = node->children;
    if (childNode != NULL) {
        //the first child should be Value
        if (childNode->type == XML_TEXT_NODE) {
            self.Value = [[NSString stringWithCString:(const char*)childNode->content encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        childNode = childNode->next;
        
        if (childNode != NULL) {
            self.children = [[NSMutableArray alloc] init];
            while (childNode) {
                if (childNode->type == XML_ELEMENT_NODE) {
                    IPaXMLSection *section = [[IPaXMLSection alloc] initWithXMLNode:childNode];
                    [self.children addObject:section];
                }
                childNode = childNode->next;
            }
        }
    }
    
    
    
    return YES;
}

#pragma mark - XMLTextReaderAPI
-(id)initWithXMLTextReaderPtr:(xmlTextReaderPtr)reader
{
    self = [super init];
    if (![self readXMLTextReader:reader]) {
        self.Name = nil;
        self.Value = nil;
        self.attributes = nil;
        self.children = nil;
        return nil;
    }
    
    return self;
}
-(BOOL)readXMLStartElementNode:(xmlTextReaderPtr)reader
{
    
    if (xmlTextReaderRead(reader) != 1) {
        return NO;
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
    int nodeType = xmlTextReaderNodeType(reader);
    
    while (nodeType != 1) {
        //found next start element
        if(xmlTextReaderRead(reader) != 1)
        {
            return NO;
        }
        nodeType = xmlTextReaderNodeType(reader);
    }
    return YES;
}

-(BOOL)readXMLTextReader:(xmlTextReaderPtr)reader
{
    //when come here ,the node must be start element
    xmlChar *name, *value;
    
    name = xmlTextReaderName(reader);
    if (name == NULL)
    {
        //   name = xmlStrdup(BAD_CAST "--");
        return NO;
    }
    self.Name = [NSString stringWithCString:(const char*)name encoding:NSUTF8StringEncoding];
    xmlFree(name);
    //read Attribute
    if (xmlTextReaderMoveToFirstAttribute(reader)) {
        int attributeNum = xmlTextReaderAttributeCount(reader);
        if (attributeNum > 0) {
            self.attributes = [NSMutableDictionary dictionaryWithCapacity:attributeNum];
            
            //read attribute
            do {
                int nodeType = xmlTextReaderNodeType(reader);
                if (nodeType != 2) {
                    continue;
                }
                name = xmlTextReaderName(reader);
                value = xmlTextReaderValue(reader);
                NSString *attrName;
                NSString *attrValue;
                if (name != NULL && value != NULL) {
                    attrName = [NSString stringWithCString:(const char*)name encoding:NSUTF8StringEncoding];
                    attrValue = [NSString stringWithCString:(const char*)value encoding:NSUTF8StringEncoding];
                    
                    [self.attributes setObject:attrValue forKey:attrName];
                    
                }
            } while (xmlTextReaderMoveToNextAttribute(reader));
        }
    }
    
    if (!xmlTextReaderIsEmptyElement(reader)) {
        int nodeType;
        
        if (xmlTextReaderRead(reader)) {
            nodeType = xmlTextReaderNodeType(reader);
            if (nodeType == 3) {
                if (xmlTextReaderHasValue(reader)) {
                    value = xmlTextReaderValue(reader);
                    if (value != NULL) {
                        NSString *valueStr = [NSString stringWithCString:(const char*)value encoding:NSUTF8StringEncoding];
                        self.Value = [valueStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        xmlFree(value);
                    }
                    if (!xmlTextReaderRead(reader)){
                        return NO;
                    }
                }
            }
        }
        else {
            return NO;
        }
        
        self.children = [NSMutableArray array];
        
        do{
            //check end node
            nodeType = xmlTextReaderNodeType(reader);
            
            switch (nodeType) {
                case 15:
                    //should go out from here
                    return YES;
                case 1:
                {
                    // new sub node
                    IPaXMLSection *newSection = [[IPaXMLSection alloc] initWithXMLTextReaderPtr:reader];
                    
                    if (newSection != nil) {
                        [self.children addObject:newSection];
                    }
                }
                    break;
                default:
                    break;
            }
        }while (xmlTextReaderRead(reader));
        
        return NO;
    }
    return YES;
}

@end

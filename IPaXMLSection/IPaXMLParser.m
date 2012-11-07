//
//  IPaXMLParser.m
//  IPaXMLSection
//
//  Created by IPaPa on 11/12/31.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IPaXMLParser.h"
#import "IPaXMLSection.h"
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>



@implementation IPaXMLParser
static IPaXMLParser *defaultParser;
-(id)init {
    if (defaultParser != nil) {
        //you can only use default parser
        return nil;
    }
    self = [super init];
    xmlInitParser();
    defaultParser = self;
    return self;
}

-(void)dealloc
{
    xmlCleanupParser();
}
+(IPaXMLParser*) defaultParser
{
    return (defaultParser == nil)?[[IPaXMLParser alloc] init]:defaultParser;
}
+(NSArray*)parseXMLFile:(NSString*)fileName withXPathExpression:(NSString*)path
{
    IPaXMLParser *parser = [IPaXMLParser defaultParser];
    return [parser parseXMLFile:fileName withXPathExpression:path];
}
+(NSArray*)parseXMLData:(NSData*)data withXPathExpression:(NSString*)path
{
    IPaXMLParser *parser = [IPaXMLParser defaultParser];
    return [parser parseXMLData:data withXPathExpression:path];
}
+(void)cleanUpParser
{
    defaultParser = nil;
}


#pragma mark - XPath
-(NSArray*)parseXMLDoc:(xmlDocPtr)doc withXPathExpression:(NSString*)xpathExpr
{
    xmlXPathContextPtr xpathCtx;
    xmlXPathObjectPtr xpathObj;
    
    /* Create xpath evaluation context */
    xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL) {
        NSLog(@"Error: unable to create new XPath context");
        
        return nil;
    }
    
    
    
    /* Evaluate xpath expression */
    xpathObj = xmlXPathEvalExpression((const xmlChar*)[xpathExpr cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    if(xpathObj == NULL) {
        NSLog(@"Error: unable to evaluate xpath expression \"%@\"\n", xpathExpr);
        xmlXPathFreeContext(xpathCtx);
        return nil;
    }
    
    xmlNodeSetPtr nodes = xpathObj->nodesetval;
    
    //process node
    NSMutableArray *resultNodes = [NSMutableArray array];
    
    if (nodes) {
        
        for (NSInteger i = 0; i < nodes->nodeNr; i++)
        {
            
            
            //[self printNode:nodes->nodeTab[i] level:1];
            
            xmlNodePtr node = nodes->nodeTab[i];
            
            IPaXMLSection *section = [[IPaXMLSection alloc] initWithXMLNode:node];
            
            if (section)
            {
                [resultNodes addObject:section];
            }
        }
        
    }
    
    
    
    
    /* Cleanup */
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    
    return resultNodes;
}
-(NSArray*)parseXMLFile:(NSString*)fileName withXPathExpression:(NSString*)xpathExpr
{
    xmlDocPtr doc;
    
    
    /* Load XML document */
    doc = xmlParseFile([fileName cStringUsingEncoding:NSUTF8StringEncoding]);
    if (doc == NULL) {
        NSLog(@"unable to parse file:%@!",fileName);
        return nil;
    }
    
    NSArray *retArray = [self parseXMLDoc:doc withXPathExpression:xpathExpr];
    
    xmlFreeDoc(doc);
    
    
    return retArray;
}

-(NSArray*)parseXMLData:(NSData*)data withXPathExpression:(NSString*)xpathExpr
{
    xmlDocPtr doc;
    
    /* Load XML document */
    doc =  xmlReadMemory([data bytes], [data length], "", NULL, XML_PARSE_RECOVER);
    if (doc == NULL) {
        NSLog(@"Unable to parse.");
        return nil;
    }
    NSArray *retArray = [self parseXMLDoc:doc withXPathExpression:xpathExpr];
    xmlFreeDoc(doc);
    
    return retArray;
}

-(void)printNode:(xmlNodePtr) currentNode level:(NSInteger)level
{
    NSString *Name;
    NSString *value;
    if (currentNode->type == XML_DOCUMENT_NODE) {
        Name = @"";
        value = @"";
    }
    else
    {
        Name = (currentNode->name != NULL)?[NSString stringWithCString:(const char*)currentNode->name encoding:NSUTF8StringEncoding]:
        @"";
        
        value = (currentNode->content != NULL)?[NSString stringWithCString:(const char*)currentNode->content encoding:NSUTF8StringEncoding]:
        @"";
    }
    NSLog(@"Level :%d ,Type :%d ,Name :%@ , Value: %@ ",level,
          currentNode->type,Name,value );
    if (currentNode->properties) {
        NSLog(@"HasAttribute:");
        xmlAttr *attribute = currentNode->properties;
        
        while (attribute) {
            NSString *attributeName =
            [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
            
			if (attribute->children)
			{
                NSString *attrName = (attribute->children->name != NULL)?[NSString stringWithCString:(const char*)attribute->children->name encoding:NSUTF8StringEncoding]:
                @"";
                NSString *attrValue = (attribute->children->content != NULL)?[NSString stringWithCString:(const char*)attribute->children->content encoding:NSUTF8StringEncoding]:
                @"";
				NSLog(@"attributeName:%@ attributeChildName:%@ attributeChildValue:%@ Type:%d",
                      attributeName,attrName,attrValue,attribute->children->type);
			}
            else
            {
                NSLog(@"attributeName:%@",attributeName);
            }
            
            
            attribute = attribute->next;
        }
        
        
        
    }
    xmlNodePtr childNode = currentNode->children;
	if (childNode)
	{
		
		while (childNode)
		{
            [self printNode:childNode level:level+1];
			childNode = childNode->next;
		}
		
    }
    
}

@end

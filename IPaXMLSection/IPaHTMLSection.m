//
//  IPaHTMLSection.m
//  IPaXMLSection
//
//  Created by IPaPa on 13/5/14.
//
//

#import "IPaHTMLSection.h"
#include <libxml/HTMLparser.h>
@implementation IPaHTMLSection
-(id)initWithXMLData:(NSData*)data
{
    htmlDocPtr doc = htmlParseDoc((xmlChar*)[data bytes], "UTF-8");
    if (doc == nil) {
        NSLog(@"Failed to parse html");
        return nil;
    }
    xmlNodePtr root = xmlDocGetRootElement(doc);
    
    return [super initWithXMLNode:root];
}
-(id)initWithXMLFile:(NSString*)fileName
{
    htmlDocPtr doc = htmlParseFile([fileName UTF8String], "UTF-8");
    if (doc == nil) {
        NSLog(@"Failed to parse html");
        return nil;
    }
    xmlNodePtr root = xmlDocGetRootElement(doc);
    
    return [super initWithXMLNode:root];
    
}
@end

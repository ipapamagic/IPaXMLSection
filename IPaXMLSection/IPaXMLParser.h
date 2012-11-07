//
//  IPaXMLParser.h
//  IPaXMLSection
//
//  Created by IPaPa on 11/12/31.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPaXMLParser : NSObject
+(IPaXMLParser*) defaultParser;
+(NSArray*)parseXMLFile:(NSString*)fileName withXPathExpression:(NSString*)path;
+(NSArray*)parseXMLData:(NSData*)data withXPathExpression:(NSString*)path;
+(void)cleanUpParser;
@end

//
//  IPaXMLSection.h
//  IPaXMLSection
//
//  Created by IPaPa on 11/12/29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

// IPaXMLSection is libxml2 base
// you need to add libxml2.dylib to your project
// and add $(SDKROOT)/usr/include/libxml2/** to yout search header path
//


#import <Foundation/Foundation.h>
#include <libxml/tree.h>
@interface IPaXMLSection : NSObject {

}
-(id)initWithXMLData:(NSData*)data;
-(id)initWithXMLFile:(NSString*)fileName;
-(id)initWithXMLNode:(xmlNodePtr)node;
//get all secitons have key name,array contain list of IPaXMLSection
-(NSArray*)SectionsWithKey:(NSString*)key;
//get the first section has key name
-(IPaXMLSection*)FirstSectionWithKey:(NSString*)key;
//get the value of first section that has key name
-(NSString *)ReadFirstChildValue:(NSString*)key;
//get the value of all sections that have key name
-(NSArray*)ReadChildrenValue:(NSString*)key;
//transform children to a Dictionary, Name as key, value as value
//but if you have two sections with the same name,the last one will replace value  the value in dictionary
//just process one level (children of children will not be processed)
-(NSDictionary*)childrenAsDictionary;
@property (nonatomic,copy) NSString *Name;
@property (nonatomic,copy) NSString *Value;
@property (nonatomic,strong) NSMutableDictionary *attributes;
@property (nonatomic,strong) NSMutableArray *children;
@end

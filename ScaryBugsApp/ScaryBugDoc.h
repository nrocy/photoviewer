//
//  ScaryBugDoc.h
//  ScaryBugsApp
//
//  Created by Ray Wenderlich on 8/11/12.
//  Copyright (c) 2012 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ScaryBugData;

@interface ScaryBugDoc : NSObject

@property (strong) ScaryBugData *data;
@property (strong) NSImage *thumbImage;
@property (strong) NSImage *fullImage;
@property (strong) NSString *pathToFullImage;
@property (strong) NSString *createDate;
@property (strong) NSString *location;
@property (strong) NSString *city;
@property (strong) NSString *country;

- (id)initWithTitle:(NSString*)title rating:(float)rating thumbImage:(NSImage *)thumbImage fullImage:(NSImage *)fullImage pathToFullImage:(NSString *)pathToFullImage createDate:(NSString *)createDate location:(NSString *)location city:(NSString*)city country:(NSString*)country;

@end

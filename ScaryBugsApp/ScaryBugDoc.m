//
//  ScaryBugDoc.m
//  ScaryBugsApp
//
//  Created by Ray Wenderlich on 8/11/12.
//  Copyright (c) 2012 Ray Wenderlich. All rights reserved.
//

#import "ScaryBugDoc.h"
#import "ScaryBugData.h"

@implementation ScaryBugDoc

- (id)initWithTitle:(NSString*)title rating:(float)rating thumbImage:(NSImage *)thumbImage fullImage:(NSImage *)fullImage pathToFullImage:(NSString *)pathToFullImage createDate:(NSString *)createDate location:(NSString *)location city:(NSString*)city country:(NSString*)country {
    if ((self = [super init])) {
        self.data = [[ScaryBugData alloc] initWithTitle:title rating:rating];
        self.thumbImage = thumbImage;
        self.fullImage = fullImage;
        self.pathToFullImage = pathToFullImage;
        self.createDate = createDate;
        self.location = location;
        self.city = city;
        self.country = country;
    }
    return self;
}

@end

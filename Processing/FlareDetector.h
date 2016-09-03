//
//  FlareDetector.h
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FlareDetectorFilter) {
    FlareDetectorFilterByCircularity,
    FlareDetectorFilterByArea,
    FlareDetectorFilterByConvexity,
    FlareDetectorFilterByInertia
};

@interface FlareDetector : NSObject 

- (instancetype)initWithImage:(UIImage*)image;

- (void)setThresholdWithStep:(int)step min:(int)min max:(int)max;
- (void)setFilter:(FlareDetectorFilter)filter min:(float)min max:(float)max;
- (void)unsetFilter:(FlareDetectorFilter)filter;

- (UIImage*)detectFlareMask;

@end

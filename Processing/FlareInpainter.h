//
//  FlareInpainter.hpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlareInpainter : NSObject

- (instancetype)initWithImage:(UIImage*)image mask:(UIImage*)mask;

- (UIImage*)inpaintTELEAWithRadius:(double)radius;
- (UIImage*)inpaintExemplarWithWindowSize:(int)windowSize patchSize:(int)patchSize;

@end

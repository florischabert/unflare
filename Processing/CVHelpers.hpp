//
//  CVHelpers.h
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#ifndef CVHelpers_h
#define CVHelpers_h

#import <CoreGraphics/CoreGraphics.h>

#import <opencv2/opencv.hpp>

CGImageRef MatToCGImage(const cv::Mat& image);
cv::Mat CGImageToMat(const CGImageRef image);

#endif /* CVHelpers_h */

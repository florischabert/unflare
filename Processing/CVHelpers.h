//
//  CVHelpers.h
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

UIImage *MatToUIImage(const cv::Mat& image, UIImageOrientation orientation = UIImageOrientationUp);
cv::Mat UIImageToMat(const UIImage *image);

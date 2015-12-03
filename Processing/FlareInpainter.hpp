//
//  FlareInpainter.hpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#ifndef FlareInpainter_hpp
#define FlareInpainter_hpp

#ifdef __cplusplus
#import <opencv2/opencv.hpp>

class FlareInpainter {
public:
    struct Parameters {
        enum inpaintingTypeStruct {
            inpaintingNS,
            inpaintingTELEA,
            inpaintingCDD
        } inpaintingType;
    };

    FlareInpainter(const Parameters &parameters);
    void inpaint(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage);
    
private:
    Parameters params;
};

#else

// Takes an input image and a flare mask and returns the unflared image
CGImageRef inpaintFlare(CGImageRef image, CGImageRef mask);
    
#endif

#endif /* FlareInpainter_hp */

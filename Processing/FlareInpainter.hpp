//
//  FlareInpainter.hpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#ifndef FlareInpainter_hpp
#define FlareInpainter_hpp

#import <opencv2/opencv.hpp>

class FlareInpainter {
public:
    struct Parameters {
        enum inpaintingTypeStruct {
            inpaintingExemplar,
            inpaintingNS,
            inpaintingTELEA,
            inpaintingMask,
        } inpaintingType;
        
        int windowSize;
        int patchSize;
    };

    FlareInpainter(const Parameters &parameters);
    void inpaint(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage);
    
private:
    void inpaintExemplar(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage);

    Parameters params;
};

#endif /* FlareInpainter_hp */

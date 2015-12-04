//
//  FlareInpainter.cpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#include "FlareInpainter.hpp"
#include "CVHelpers.hpp"

#import <opencv2/opencv.hpp>

FlareInpainter::FlareInpainter(const Parameters &parameters)
{
    params = parameters;
}

void FlareInpainter::inpaint(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage)
{
    if (params.inpaintingType == FlareInpainter::Parameters::inpaintingNS) {
        cv::inpaint(inpaintedImage, mask, image, 10, cv::INPAINT_NS);
        return;
    }
    
    if (params.inpaintingType == FlareInpainter::Parameters::inpaintingTELEA) {
        cv::inpaint(inpaintedImage, mask, image, 10, cv::INPAINT_TELEA);
        return;
    }

    // Exemplar-based inpainting
    
}

#ifndef MATLAB_MEX_FILE
extern "C" CGImageRef inpaintFlare(CGImageRef image, CGImageRef mask)
{
    cv::Mat cvImage;
    CGImageToMat(image, cvImage);

    cv::Mat cvMask;
    CGImageToMat(mask, cvMask);

    FlareInpainter::Parameters params;
    
    params.inpaintingType = FlareInpainter::Parameters::inpaintingExemplar;
    
    cv::Mat inpaintedImage = cvImage;
    FlareInpainter inpainter = FlareInpainter(params);
    inpainter.inpaint(cvImage, cvMask, inpaintedImage);
    
    return MatToCGImage(inpaintedImage);
}
#endif
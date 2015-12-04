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

void FlareInpainter::inpaintExemplar(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage)
{
    // Exemplar-based inpainting (A. Criminisi - 2004)
    
    inpaintedImage = image.clone();

    // For each blob in mask
    std::vector<std::vector<cv::Point>> contours;
    findContours(mask, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    for (int i = 0; i < contours.size(); i++) {
        // Compute the region of interest
        cv::Rect blobBoundingBox = boundingRect(cv::Mat(contours[i]));
        
        int windowWidth = cv::max(params.windowSize, blobBoundingBox.size().width);
        int windowHeight = cv::max(params.windowSize, blobBoundingBox.size().height);
        int extraWidth = windowWidth-blobBoundingBox.size().width;
        int extraHeight = windowHeight-blobBoundingBox.size().width;
        
        blobBoundingBox += cv::Size(extraWidth, extraHeight);
        blobBoundingBox -= cv::Point(extraWidth/2, extraHeight/2);

        cv::Mat regionOfInterest = inpaintedImage(blobBoundingBox);
        cv::Mat regionFillMask = mask(blobBoundingBox);
        cv::Mat regionSourceMask = 1 - mask(blobBoundingBox);
        
        // Compute gradients
        cv::Mat grayRegion;
        cv::cvtColor(regionOfInterest, grayRegion, CV_RGB2GRAY);
        
        cv::Mat gradX;
        cv::Mat kernelx = (cv::Mat_<float>(1,3)<<-0.5, 0, 0.5);
        cv::filter2D(grayRegion, gradX, -1, kernelx);
        
        cv::Mat gradY;
        cv::Mat kernely = (cv::Mat_<float>(3,1)<<-0.5, 0, 0.5);
        cv::filter2D(grayRegion, gradY, -1, kernely);

        // Rotate gradients 90deg
        cv::Mat temp = gradX;
        gradX = -gradY;
        gradY = temp;
        
        // Loop untill the whole region has been filled
        while (cv::countNonZero(regionFillMask) != regionFillMask.total()) {
    
            // Find contour & normalized gradients of fill region
            cv::Mat laplacian;
            cv::Mat kernelLaplacian = (cv::Mat_<float>(3,3)<<1,1,1, 1,-8,1, 1, 1, 1);
            cv::filter2D(laplacian, regionFillMask, -1, kernelLaplacian);
            
            regionOfInterest = laplacian;
            
            cv::Mat sourceGradX;
            cv::filter2D(regionSourceMask, sourceGradX, -1, kernelx);
            
            cv::Mat sourceGradY;
            cv::filter2D(regionSourceMask, sourceGradY, -1, kernely);
            
            sourceGradX = sourceGradX.mul(laplacian > 0);
            sourceGradY = sourceGradY.mul(laplacian > 0);

            sourceGradX = cv::abs(sourceGradX.mul(sourceGradX != sourceGradX));
            sourceGradY = cv::abs(sourceGradY.mul(sourceGradY != sourceGradY));
            
        
        }
    }
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

    if (params.inpaintingType == FlareInpainter::Parameters::inpaintingExemplar) {
        inpaintExemplar(image, mask, inpaintedImage);
        return;
    }
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
    params.windowSize = 200;
    params.patchSize = 9;
    
    cv::Mat inpaintedImage = cvImage;
    FlareInpainter inpainter = FlareInpainter(params);
    inpainter.inpaint(cvImage, cvMask, inpaintedImage);
    
    return MatToCGImage(inpaintedImage);
}
#endif
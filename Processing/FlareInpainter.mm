//
//  FlareInpainter.cpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import "FlareInpainter.h"
#import "CVHelpers.h"
#import <opencv2/opencv.hpp>

@implementation FlareInpainter {
    cv::Mat _image;
    UIImageOrientation _orientation;
    cv::Mat _mask;
}

- (instancetype)initWithImage:(UIImage*)image mask: (UIImage*)mask {
    self = [super init];
    if (self) {
        _image = UIImageToMat(image);
        _orientation = image.imageOrientation;
        _mask = UIImageToMat(mask);
        _mask.convertTo(_mask, CV_8U);
    }
    return self;
}

- (UIImage*)inpaintTELEAWithRadius:(double)radius {
    cv::Mat image3;
    cv::Mat inpaintedImage;
    
    cv::cvtColor(_image, image3, cv::COLOR_BGRA2BGR, 3);
    cv::inpaint(image3, _mask, inpaintedImage, radius, cv::INPAINT_TELEA);

    return MatToUIImage(inpaintedImage, _orientation);
}

- (UIImage*)inpaintExemplarWithWindowSize:(int)windowSize patchSize:(int)patchSize {
    // Exemplar-based inpainting (A. Criminisi - 2004)
    
    cv::Mat inpaintedImage = _image.clone();
    
    // For each blob in mask
    std::vector<std::vector<cv::Point>> contours;
    findContours(_mask.clone(), contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    for (int k = 0; k < contours.size(); k++) {
        // Compute the region of interest
        cv::Rect blobBoundingBox = boundingRect(cv::Mat(contours[k]));
        
        int windowWidth = cv::max(windowSize, blobBoundingBox.size().width);
        int windowHeight = cv::max(windowSize, blobBoundingBox.size().height);
        int extraWidth = windowWidth-blobBoundingBox.size().width;
        int extraHeight = windowHeight-blobBoundingBox.size().width;
        
        blobBoundingBox += cv::Size(extraWidth, extraHeight);
        blobBoundingBox -= cv::Point(extraWidth/2, extraHeight/2);

        cv::Mat regionOfInterestOut = inpaintedImage(blobBoundingBox);
        cv::Mat regionOfInterest = _image(blobBoundingBox);
        cv::Mat regionFillMask = _mask(blobBoundingBox);
        cv::Mat regionSourceMask = 1 - _mask(blobBoundingBox);
        
        // Compute gradients
        cv::Mat grayRegion;
        cv::cvtColor(regionOfInterest, grayRegion, CV_BGR2GRAY);

        cv::Mat grayRegionDouble;
        grayRegion.convertTo(grayRegionDouble, CV_64F);
        grayRegionDouble /= 255;
        
        cv::Mat gradX;
        cv::Mat kernelx = (cv::Mat_<double>(3,1)<<-0.5, 0, 0.5);
        cv::filter2D(grayRegionDouble, gradX, CV_64F, kernelx);
        gradX /= 255;

        cv::Mat gradY;
        cv::Mat kernely = (cv::Mat_<double>(1,3)<<-0.5, 0, 0.5);
        cv::filter2D(grayRegionDouble, gradY, CV_64F, kernely);
        gradY /= 255;

        // Rotate gradients 90deg
        cv::Mat temp = gradX.clone();
        gradX = -gradY;
        gradY = temp;
        
        cv::Mat regionSourceMaskDouble;
        regionSourceMask.convertTo(regionSourceMaskDouble, CV_64F);

        cv::Mat confidence = regionSourceMaskDouble.clone();

        // Loop untill the whole region has been filled
        while (cv::countNonZero(regionFillMask)) {
            
            // Compute contours
            cv::Mat laplacian;
            cv::Mat kernelLaplacian = (cv::Mat_<double>(3,3)<<1,1,1, 1,-8,1, 1,1,1);
            cv::filter2D(regionFillMask, laplacian, CV_64F, kernelLaplacian);

            cv::Mat sourceGradX;
            cv::filter2D(regionSourceMask, sourceGradX, CV_64F, kernelx);
            
            cv::Mat sourceGradY;
            cv::filter2D(regionSourceMask, sourceGradY, CV_64F, kernely);
            
            sourceGradX /= cv::abs(sourceGradX);
            sourceGradY /= cv::abs(sourceGradY);

            double maxPriority = 0;
            cv::Point maxPoint;
            for(int i = patchSize/2; i < laplacian.rows - patchSize/2; i++) {
                for(int j = patchSize/2; j < laplacian.cols - patchSize/2; j++) {
                    if (laplacian.at<double>(i, j) > 0) {

                        // Compute confidence
                        cv::Point patchCenter(j-patchSize/2, i-patchSize/2);
                        cv::Rect patch(patchCenter, cv::Size(patchSize, patchSize));
                        
                        cv::Mat confidencePatch = confidence(patch).mul(regionSourceMaskDouble(patch));

                        confidence.at<double>(i,j) = cv::sum(confidencePatch)[0];
                        confidence.at<double>(i,j) /= patchSize * patchSize;

                        // Compute patch priorities
                        double dataTerm = gradX.at<double>(i,j) * sourceGradX.at<double>(i,j);
                        dataTerm += gradY.at<double>(i,j) * sourceGradY.at<double>(i,j);
                        dataTerm = cv::abs(dataTerm);
                        dataTerm += 0.001;
                        
                        double priority = confidence.at<double>(i,j) * dataTerm;

                        if (priority > maxPriority) {
                            maxPriority = priority;
                            maxPoint = cv::Point(j,i);
                        }
                    }
                }
            }
            
            if (!maxPriority) {
                break;
            }
            
            // Get patch with max priority
            cv::Point patchCenter(maxPoint.x-patchSize/2, maxPoint.y-patchSize/2);
            cv::Rect patch(patchCenter, cv::Size(patchSize, patchSize));
            
            cv::Mat patchRegion = regionFillMask(patch);
            cv::Mat patchRegionSource = regionSourceMask(patch);
        
            // Find exemplar that minimize error
            double minError = 1e100;
            cv::Rect bestPatch;
            for(int i = patchSize/2; i < grayRegion.rows - patchSize/2; i++) {
                for(int j = patchSize/2; j < grayRegion.cols - patchSize/2; j++) {
                    cv::Point currentPatchCenter(j-patchSize/2, i-patchSize/2);
                    cv::Rect currentPatch(currentPatchCenter, cv::Size(patchSize, patchSize));
                    
                    if (cv::countNonZero(regionSourceMask(currentPatch)) != patchSize*patchSize) {
                        continue;
                    }
                    
                    cv::Mat diff = cv::abs(regionOfInterest(patch) - regionOfInterest(currentPatch));
                    double error = cv::sum(diff)[0] + cv::sum(diff)[1] + cv::sum(diff)[2];
                    error *= error;
                    
                    if (minError > error) {
                        minError = error;
                        bestPatch = currentPatch;
                    }
                }
            }

            for(int i = 0; i < patchRegion.rows; i++) {
                for(int j = 0; j < patchRegion.cols; j++) {
                    if (patchRegion.at<uchar>(i, j)) {
                        
                        // Update fill region
                        patchRegion.at<uchar>(i, j) = 0;
                        patchRegionSource.at<uchar>(i, j) = 1;
                        regionSourceMask.convertTo(regionSourceMaskDouble, CV_64F);

                        // Propagate confidence
                        confidence(patch).at<double>(i,j) = confidence.at<double>(maxPoint);
                        
                        // Propagate isophotes
                        gradX(patch).at<double>(i,j) = gradX(bestPatch).at<double>(i,j);
                        gradY(patch).at<double>(i,j) = gradY(bestPatch).at<double>(i,j);
                        
                        
                        // Copy patch to inpainted image
                        regionOfInterestOut(patch).at<cv::Vec3b>(i,j) = regionOfInterestOut(bestPatch).at<cv::Vec3b>(i,j);
                    }
                }
            }
        }
    }
    
    return MatToUIImage(inpaintedImage, _orientation);
}

@end

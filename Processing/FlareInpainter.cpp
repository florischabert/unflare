//
//  FlareInpainter.cpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#include "FlareInpainter.hpp"

#import <opencv2/opencv.hpp>

FlareInpainter::FlareInpainter(const Parameters &parameters)
{
    params = parameters;
}

void FlareInpainter::inpaintExemplar(const cv::Mat& image, cv::Mat& mask, cv::Mat& inpaintedImage)
{
    // Exemplar-based inpainting (A. Criminisi - 2004)
    
    inpaintedImage = image.clone();
    
    cv::Size patchSize(params.patchSize, params.patchSize);
    mask.convertTo(mask, CV_8U);

    // For each blob in mask
    std::vector<std::vector<cv::Point>> contours;
    findContours(mask.clone(), contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
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
            std::cout << "To fill: " << cv::countNonZero(regionFillMask) << std::endl;

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
            for(int i = params.patchSize/2; i < laplacian.rows - params.patchSize/2; i++) {
                for(int j = params.patchSize/2; j < laplacian.cols - params.patchSize/2; j++) {
                    if (laplacian.at<double>(i, j) > 0) {

                        // Compute confidence
                        cv::Point patchCenter(j-params.patchSize/2, i-params.patchSize/2);
                        cv::Rect patch(patchCenter, patchSize);
                        
                        cv::Mat confidencePatch = confidence(patch).mul(regionSourceMaskDouble(patch));

                        confidence.at<double>(i,j) = cv::sum(confidencePatch)[0];
                        confidence.at<double>(i,j) /= params.patchSize * params.patchSize;

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

            // Get patch with max priority
            cv::Point patchCenter(maxPoint.x-params.patchSize/2, maxPoint.y-params.patchSize/2);
            cv::Rect patch(patchCenter, patchSize);

            cv::Mat patchRegion = regionFillMask(patch);
            cv::Mat patchRegionSource = regionSourceMask(patch);
            
            // Find exemplar that minimize error
            double minError = 1.0/0.0;
            cv::Rect bestPatch;
            for(int i = params.patchSize/2; i < grayRegion.rows - params.patchSize/2; i++) {
                for(int j = params.patchSize/2; j < grayRegion.cols - params.patchSize/2; j++) {
                    cv::Point currentPatchCenter(j-params.patchSize/2, i-params.patchSize/2);
                    cv::Rect currentPatch(currentPatchCenter, patchSize);
                    
                    if (cv::countNonZero(regionSourceMask(currentPatch)) != params.patchSize*params.patchSize) {
                        continue;
                    }
                    
                    cv::Mat diff = cv::abs(grayRegionDouble(patch) - grayRegionDouble(currentPatch));
                    double error = cv::sum(diff)[0];
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
                        
                        std::cout << "Filling "<< patch << ": " << j << "," << i << std::endl;
                        
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
                        regionOfInterest(patch).at<cv::Scalar>(i,j) = regionOfInterest(bestPatch).at<cv::Scalar>(i,j);
                        grayRegionDouble(patch).at<double>(i,j) = grayRegionDouble(bestPatch).at<double>(i,j);
                    }
                }
            }
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

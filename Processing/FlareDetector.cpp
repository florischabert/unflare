//
//  FlareDetector.cpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#include "FlareDetector.hpp"
#include "CVHelpers.hpp"

FlareDetector::FlareDetector(const Parameters &parameters)
{
    params = parameters;
}

void FlareDetector::filterBlobs(const cv::Mat& binaryImage, std::vector<Blob>& blobs, std::vector<std::vector<cv::Point>>& curContours) const
{
    std::vector<std::vector<cv::Point>> contours;
    
    // Extract connected components
    findContours(binaryImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);

    // Filter each contour given specified properties
    for (size_t contourIdx = 0; contourIdx < contours.size(); contourIdx++) {
        Blob blob;
        blob.confidence = 1;

        cv::Moments moms = cv::moments(cv::Mat(contours[contourIdx]));
        if (params.filterByArea) {
            double area = moms.m00;
            if (area < params.minArea || area >= params.maxArea)
                continue;
        }

        if (params.filterByCircularity) {
            double area = moms.m00;
            double perimeter = cv::arcLength(cv::Mat(contours[contourIdx]), true);
            double ratio = 4 * CV_PI * area / (perimeter * perimeter);
            if (ratio < params.minCircularity || ratio >= params.maxCircularity)
                continue;
        }

        if (params.filterByInertia) {
            double denominator = sqrt(pow(2 * moms.mu11, 2) + pow(moms.mu20 - moms.mu02, 2));
            const double eps = 1e-2;
            double ratio;
            if (denominator > eps) {
                double cosmin = (moms.mu20 - moms.mu02) / denominator;
                double sinmin = 2 * moms.mu11 / denominator;
                double cosmax = -cosmin;
                double sinmax = -sinmin;
                
                double imin = 0.5 * (moms.mu20 + moms.mu02) - 0.5 * (moms.mu20 - moms.mu02) * cosmin - moms.mu11 * sinmin;
                double imax = 0.5 * (moms.mu20 + moms.mu02) - 0.5 * (moms.mu20 - moms.mu02) * cosmax - moms.mu11 * sinmax;
                ratio = imin / imax;
            }
            else {
                ratio = 1;
            }
            
            if (ratio < params.minInertiaRatio || ratio >= params.maxInertiaRatio)
                continue;
            
            blob.confidence = ratio * ratio;
        }

        if (params.filterByConvexity) {
            std::vector < cv::Point > hull;
            cv::convexHull(cv::Mat(contours[contourIdx]), hull);
            double area = contourArea(cv::Mat(contours[contourIdx]));
            double hullArea = contourArea(cv::Mat(hull));
            double ratio = area / hullArea;
            if (ratio < params.minConvexity || ratio >= params.maxConvexity)
                continue;
        }

        // Compute blob properties
        blob.location = cv::Point2d(moms.m10 / moms.m00, moms.m01 / moms.m00);
        std::vector<double> dists;
        for (size_t pointIdx = 0; pointIdx < contours[contourIdx].size(); pointIdx++) {
            cv::Point2d pt = contours[contourIdx][pointIdx];
            dists.push_back(norm(blob.location - pt));
        }
        std::sort(dists.begin(), dists.end());
        blob.radius = (dists[(dists.size() - 1) / 2] + dists[dists.size() / 2]) / 2.;

        blobs.push_back(blob);
        curContours.push_back(contours[contourIdx]);
    }
}

void FlareDetector::detect(const cv::Mat& image, cv::Mat& mask)
{
    std::vector<std::vector<Blob>> blobs;
    std::vector<std::vector<cv::Point>> contours;
    
    // Threshold steps
    for (double thresh = params.minThreshold; thresh < params.maxThreshold; thresh += params.thresholdStep) {
        cv::Mat binarizedImage;
        cv::threshold(image, binarizedImage, thresh, 255, cv::THRESH_BINARY);
        
        // Filter blobs for each binary image
        std::vector<Blob> curBlobs;
        std::vector<std::vector<cv::Point>> curContours, newContours;
        filterBlobs(binarizedImage, curBlobs, curContours);
        
        // Prune blobs
        std::vector<std::vector<Blob>> newBlobs;

        for (size_t i = 0; i < curBlobs.size(); i++) {
            bool isNew = true;
            for (size_t j = 0; j < blobs.size(); j++) {
                double dist = norm(blobs[j][blobs[j].size() / 2].location - curBlobs[i].location);
                isNew = dist >= params.minDistBetweenBlobs && dist >= blobs[j][ blobs[j].size() / 2 ].radius && dist >= curBlobs[i].radius;
                if (!isNew) {
                    blobs[j].push_back(curBlobs[i]);
                    
                    size_t k = blobs[j].size() - 1;
                    while (k > 0 && blobs[j][k].radius < blobs[j][k-1].radius) {
                        blobs[j][k] = blobs[j][k-1];
                        k--;
                    }
                    blobs[j][k] = curBlobs[i];
                    
                    break;
                }
            }
            if (isNew) {
                newBlobs.push_back(std::vector<Blob> (1, curBlobs[i]));
                newContours.push_back(curContours[i]);
            }
        }
    
        std::copy(newBlobs.begin(), newBlobs.end(), std::back_inserter(blobs));
        std::copy(newContours.begin(), newContours.end(), std::back_inserter(contours));
    }
    
    // Create mask
    mask = cv::Mat::zeros(image.size(), CV_8UC1);
    cv::drawContours(mask, contours, -1, cv::Scalar(255), 8, 8);
    cv::drawContours(mask, contours, -1, cv::Scalar(255), CV_FILLED, 8);
}

#ifndef MATLAB_MEX_FILE
extern "C" CGImageRef detectFlare(CGImageRef image)
{
    // Detector parameters
    FlareDetector::Parameters params;

    params.minThreshold = 50;
    params.maxThreshold = 255;
    params.thresholdStep = 10;
    params.minDistBetweenBlobs = 50.0f;
    
    params.filterByCircularity = true;
    params.minCircularity = 0.4;
    params.maxCircularity = 1;
    
    params.filterByArea = true;
    params.minArea = 400.0f;
    params.maxArea = 1500.0f;
    
    params.filterByConvexity = true;
    params.minConvexity = 0.8;
    params.maxConvexity = 1;
    
    params.filterByInertia = true;
    params.minInertiaRatio = 0.7;
    params.maxInertiaRatio = 1;
    
    cv::Mat cvImage;
    CGImageToMat(image, cvImage);

    cv::Mat cvImageGray;
    cv::cvtColor(cvImage, cvImageGray, CV_BGR2GRAY);
    
    // Detect blobs
    cv::Mat mask;
    FlareDetector detector = FlareDetector(params);
    detector.detect(cvImageGray, mask);
    
    return MatToCGImage(mask);
}
#endif

//
//  FlareDetector.cpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import "FlareDetector.h"
#import "CVHelpers.h"

@implementation FlareDetector {
    cv::Mat _image;

    float _minDistBetweenBlobs;
    int _thresholdStep;
    int _minThreshold;
    int _maxThreshold;
    
    struct FilterParams {
        float min;
        float max;
    };

    std::map<FlareDetectorFilter, FilterParams> _filters;
}

- (instancetype)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        _image = UIImageToMat(image);
        _minDistBetweenBlobs = 50.0f;
    }
    return self;
}

- (void)setThresholdWithStep:(int)step min:(int)min max:(int)max {
    _thresholdStep = step;
    _minThreshold = min;
    _maxThreshold = max;
}

- (void)setFilter:(FlareDetectorFilter)filter min:(float)min max:(float)max {
    FilterParams filterParams;
    filterParams.min = min;
    filterParams.max = max;
    
    _filters[filter] = filterParams;
}

- (void)unsetFilter:(FlareDetectorFilter)filter {
    _filters.erase(filter);
}

struct Blob {
    float confidence;
    cv::Point2d location;
    float radius;
};

- (void)_filterBlobsInImage:(const cv::Mat&)binaryImage blobs:(std::vector<Blob>&)blobs contours:(std::vector<std::vector<cv::Point>>&)curContours
{
    std::vector<std::vector<cv::Point>> contours;
    
    // Extract connected components
    findContours(binaryImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    
    // Filter each contour given specified properties
    for (size_t contourIdx = 0; contourIdx < contours.size(); contourIdx++) {
        Blob blob;
        blob.confidence = 1;
        
        cv::Moments moms = cv::moments(cv::Mat(contours[contourIdx]));
        if (_filters.count(FlareDetectorFilterByArea)) {
            double area = moms.m00;
            if (area < _filters[FlareDetectorFilterByArea].min || area >= _filters[FlareDetectorFilterByArea].max)
                continue;
        }
        
        if (_filters.count(FlareDetectorFilterByCircularity)) {
            double area = moms.m00;
            double perimeter = cv::arcLength(cv::Mat(contours[contourIdx]), true);
            double ratio = 4 * CV_PI * area / (perimeter * perimeter);
            if (ratio < _filters[FlareDetectorFilterByCircularity].min || ratio >= _filters[FlareDetectorFilterByCircularity].max)
                continue;
        }
        
        if (_filters.count(FlareDetectorFilterByInertia)) {
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
            
            if (ratio < _filters[FlareDetectorFilterByInertia].min || ratio >= _filters[FlareDetectorFilterByInertia].max)
                continue;
            
            blob.confidence = ratio * ratio;
        }
        
        if (_filters.count(FlareDetectorFilterByConvexity)) {
            std::vector < cv::Point > hull;
            cv::convexHull(cv::Mat(contours[contourIdx]), hull);
            double area = contourArea(cv::Mat(contours[contourIdx]));
            double hullArea = contourArea(cv::Mat(hull));
            double ratio = area / hullArea;
            if (ratio < _filters[FlareDetectorFilterByConvexity].min || ratio >= _filters[FlareDetectorFilterByConvexity].max)
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

- (UIImage*)detectFlareMask {
    cv::Mat mask;
    std::vector<std::vector<Blob>> blobs;
    std::vector<std::vector<cv::Point>> contours;
    
    cv::Mat imageGray = _image;
    
    if (_image.channels() != 1) {
        cv::cvtColor(_image, imageGray, CV_BGR2GRAY);
    }
    
    // Threshold steps
    for (double thresh = _minThreshold; thresh < _maxThreshold; thresh += _thresholdStep) {
        cv::Mat binarizedImage;
        cv::threshold(imageGray, binarizedImage, thresh, 255, cv::THRESH_BINARY);
        
        // Filter blobs for each binary image
        std::vector<Blob> curBlobs;
        std::vector<std::vector<cv::Point>> curContours, newContours;
        [self _filterBlobsInImage:binarizedImage blobs:curBlobs contours:curContours];
    
        // Prune blobs
        std::vector<std::vector<Blob>> newBlobs;
        
        for (size_t i = 0; i < curBlobs.size(); i++) {
            bool isNew = true;
            for (size_t j = 0; j < blobs.size(); j++) {
                double dist = norm(blobs[j][blobs[j].size() / 2].location - curBlobs[i].location);
                isNew = dist >= _minDistBetweenBlobs && dist >= blobs[j][ blobs[j].size() / 2 ].radius && dist >= curBlobs[i].radius;
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
    
    mask = cv::Mat::zeros(imageGray.size(), CV_8UC1);
    cv::drawContours(mask, contours, -1, cv::Scalar(1), 15, 8);
    cv::drawContours(mask, contours, -1, cv::Scalar(1), CV_FILLED, 8);
    
    return MatToUIImage(mask);
}

@end

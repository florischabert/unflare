//
//  FlareDetector.hpp
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#ifndef FlareDetector_hpp
#define FlareDetector_hpp

#ifdef __cplusplus
#import <opencv2/opencv.hpp>

class FlareDetector {
public:
    struct Parameters {
        int minThreshold;
        int maxThreshold;
        int thresholdStep;
        float minDistBetweenBlobs;
        
        bool filterByCircularity;
        float minCircularity;
        float maxCircularity;
        
        bool filterByArea;
        float minArea;
        float maxArea;
        
        bool filterByConvexity;
        float minConvexity;
        float maxConvexity;
        
        bool filterByInertia;
        float minInertiaRatio;
        float maxInertiaRatio;
    };
    
    struct Blob {
        float confidence;
        cv::Point2d location;
        float radius;
    };
    
    FlareDetector(const Parameters &parameters);
    void detect(const cv::Mat& image, cv::Mat& mask);
    
private:
    virtual void filterBlobs(const cv::Mat& binaryImage, std::vector<Blob>& blobs, std::vector <std::vector<cv::Point>>& curContours) const;
    
    Parameters params;
};

#else

// Takes an input image and returns a flare mask
CGImageRef detectFlare(CGImageRef image);
    
#endif

#endif /* FlareDetector_h */

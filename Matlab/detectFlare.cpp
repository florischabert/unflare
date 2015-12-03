#include "mex.h"
#include "MxArray.hpp"
#include "../Processing/FlareDetector.hpp"

// input: image, params
// output: mask
void mexFunction(
	int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2 || nlhs != 1) {
		mexErrMsgTxt("Usage: mask = detectFlare(image, pa");
	}

    FlareDetector::Parameters params;
    
    params.minThreshold = mxGetScalar(mxGetField(prhs[1], 0, "minThreshold"));
    params.maxThreshold = mxGetScalar(mxGetField(prhs[1], 0, "maxThreshold"));
    params.thresholdStep = mxGetScalar(mxGetField(prhs[1], 0, "thresholdStep"));
    params.minDistBetweenBlobs = mxGetScalar(mxGetField(prhs[1], 0, "minDistBetweenBlobs"));
    
    params.filterByCircularity = mxGetScalar(mxGetField(prhs[1], 0, "filterByCircularity"));
    params.minCircularity = mxGetScalar(mxGetField(prhs[1], 0, "minCircularity"));
    params.maxCircularity = mxGetScalar(mxGetField(prhs[1], 0, "maxCircularity"));
    
    params.filterByArea = mxGetScalar(mxGetField(prhs[1], 0, "filterByArea"));
    params.minArea = mxGetScalar(mxGetField(prhs[1], 0, "minArea"));
    params.maxArea = mxGetScalar(mxGetField(prhs[1], 0, "maxArea"));
    
    params.filterByConvexity = mxGetScalar(mxGetField(prhs[1], 0, "filterByConvexity"));
    params.minConvexity = mxGetScalar(mxGetField(prhs[1], 0, "minConvexity"));
    params.maxConvexity = mxGetScalar(mxGetField(prhs[1], 0, "maxConvexity"));
    
    params.filterByInertia = mxGetScalar(mxGetField(prhs[1], 0, "filterByInertia"));
    params.minInertiaRatio = mxGetScalar(mxGetField(prhs[1], 0, "minInertiaRatio"));
    params.maxInertiaRatio = mxGetScalar(mxGetField(prhs[1], 0, "maxInertiaRatio"));
    
    cv::Mat cvImage = MxArray(prhs[0]).toMat();

    cv::Mat cvImageGray;
    cv::cvtColor(cvImage, cvImageGray, CV_BGR2GRAY);
    
    cv::Mat mask;
    FlareDetector detector = FlareDetector(params);
    detector.detect(cvImageGray, mask);

    plhs[0] = MxArray(mask);
}
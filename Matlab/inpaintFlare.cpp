#include "mex.h"
#include "MxArray.hpp"
#include "../Processing/FlareInpainter.hpp"

// input: image, mask, params
// output: inpainted image
void mexFunction(
	int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
    if (nrhs != 3 || nlhs != 1) {
		mexErrMsgTxt("Usare: inpainted = detectFlare(image, mask, params)");
	}
        
    FlareInpainter::Parameters params;
    params.inpaintingType = static_cast<FlareInpainter::Parameters::inpaintingTypeStruct>(mxGetScalar(mxGetField(prhs[2], 0, "inpaintingType")));

    cv::Mat cvImage = MxArray(prhs[0]).toMat();
    cv::Mat cvMask = MxArray(prhs[1]).toMat();
    
    cv::Mat inpaintedImage = cvImage;
    FlareInpainter inpainter = FlareInpainter(params);
    inpainter.inpaint(cvImage, cvMask, inpaintedImage);

    plhs[0] = MxArray(inpaintedImage);
}
//
//  PhotoEditingViewController.m
//  Extension
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import "PhotoEditingViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

#import "FlareDetector.hpp"
#import "FlareInpainter.hpp"
#import "CVHelpers.hpp"

@interface PhotoEditingViewController () <PHContentEditingController>
@property (strong) PHContentEditingInput *input;
@end

@implementation PhotoEditingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PHContentEditingController

- (BOOL)canHandleAdjustmentData:(PHAdjustmentData *)adjustmentData {
    // Inspect the adjustmentData to determine whether your extension can work with past edits.
    // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
    return NO;
}

- (void)startContentEditingWithInput:(PHContentEditingInput *)contentEditingInput placeholderImage:(UIImage *)placeholderImage {
    // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
    // If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
    // If you returned NO, the contentEditingInput has past edits "baked in".
    self.input = contentEditingInput;
    
    CGImageRef image = [UIImage imageWithContentsOfFile:self.input.fullSizeImageURL.path].CGImage;
    
    // Setup Detection
    FlareDetector::Parameters detectionParams;
    
    detectionParams.minThreshold = 50;
    detectionParams.maxThreshold = 255;
    detectionParams.thresholdStep = 10;
    detectionParams.minDistBetweenBlobs = 50.0f;
    
    detectionParams.filterByCircularity = true;
    detectionParams.minCircularity = 0.4;
    detectionParams.maxCircularity = 1;
    
    detectionParams.filterByArea = true;
    detectionParams.minArea = 400.0f;
    detectionParams.maxArea = 1500.0f;
    
    detectionParams.filterByConvexity = true;
    detectionParams.minConvexity = 0.8;
    detectionParams.maxConvexity = 1;
    
    detectionParams.filterByInertia = true;
    detectionParams.minInertiaRatio = 0.7;
    detectionParams.maxInertiaRatio = 1;
    
    // Detect blobs
    cv::Mat mask;
    cv::Mat originalImage = CGImageToMat(image);
    FlareDetector detector = FlareDetector(detectionParams);
    detector.detect(originalImage, mask);
    
    // Setup Inpainting
    FlareInpainter::Parameters inpaintingParams;
    
    inpaintingParams.inpaintingType = FlareInpainter::Parameters::inpaintingTELEA;
    inpaintingParams.windowSize = 200;
    inpaintingParams.patchSize = 9;
    
    // Inpaint image
    cv::Mat inpaintedImage;
    FlareInpainter inpainter = FlareInpainter(inpaintingParams);
    inpainter.inpaint(originalImage, mask, inpaintedImage);
    
    // Show restored image
    self.imageView.image = [UIImage imageWithCGImage:MatToCGImage(inpaintedImage)];
}

- (void)finishContentEditingWithCompletionHandler:(void (^)(PHContentEditingOutput *))completionHandler {
    // Update UI to reflect that editing has finished and output is being rendered.
    
    // Render and provide output on a background queue.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create editing output from the editing input.
        PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput:self.input];
        
        // Provide new adjustments and render output to given location.
         output.adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"UnFlare" formatVersion:@"0.1" data:[NSData data]];
         NSData *renderedJPEGData = UIImageJPEGRepresentation(self.imageView.image, 1);
         [renderedJPEGData writeToURL:output.renderedContentURL atomically:YES];
        
        // Call completion handler to commit edit to Photos.
        completionHandler(output);
    });
}

- (BOOL)shouldShowCancelConfirmation {
    // Returns whether a confirmation to discard changes should be shown to the user on cancel.
    // (Typically, you should return YES if there are any unsaved changes.)
    return NO;
}

- (void)cancelContentEditing {
    // Clean up temporary files, etc.
    // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
}

@end

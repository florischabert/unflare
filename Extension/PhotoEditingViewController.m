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
    
    CGImageRef mask = detectFlare(image);
    CGImageRef inpaintedImage = inpaintFlare(image, mask);
    
    self.imageView.image = [UIImage imageWithCGImage:inpaintedImage];
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

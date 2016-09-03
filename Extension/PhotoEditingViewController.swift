//
//  PhotoEditingViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/3/16.
//  Copyright © 2016 floris. All rights reserved.
//

import Foundation
import FlareProcessor
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {
    public var shouldShowCancelConfirmation = true;
    
    @IBOutlet var imageView: UIImageView?
    var input: PHContentEditingInput?;

    public func cancelContentEditing() {
        
    }
    
    public func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return false;
    }
    
    public func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        let image = UIImage(contentsOfFile: (contentEditingInput.fullSizeImageURL?.path)!);
        
        let detector = FlareDetector(image: image);
        detector?.setThresholdWithStep(10, min: 50, max: 255);
        detector?.setFilter(.byCircularity, min: 0.4, max: 1);
        detector?.setFilter(.byArea, min: 400, max: 1500);
        detector?.setFilter(.byConvexity, min: 0.8, max: 1);
        detector?.setFilter(.byInertia, min: 0.7, max: 1);
        
        let mask = detector?.detectFlareMask();
        let inpainter = FlareInpainter(image: image, mask: mask);
        let inpaintedImage = inpainter?.inpaintTELEA(withRadius: 10);
//        let inpaintedImage = inpainter?.inpaintExemplar(withWindowSize: 200, patchSize: 9);
        
        input = contentEditingInput;
        imageView?.image = inpaintedImage;
    }
    
    public func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Swift.Void) {
        DispatchQueue.global().async {
            let output = PHContentEditingOutput(contentEditingInput: self.input!);
            output.adjustmentData = PHAdjustmentData(formatIdentifier: "UnFlare", formatVersion: "0.1", data: Data());
            
            let renderedJPEGData = UIImageJPEGRepresentation(self.imageView!.image!, 1);
            do {
                try renderedJPEGData?.write(to: output.renderedContentURL);
            }
            catch {
            }

            completionHandler(output);
        }
    }
    
}

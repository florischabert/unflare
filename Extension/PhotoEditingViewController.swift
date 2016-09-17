//
//  PhotoEditingViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/3/16.
//  Copyright © 2016 floris. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import MobileCoreServices

class PhotoEditingViewController: UIViewController, PHContentEditingController {
    public var shouldShowCancelConfirmation = true;
    
    @IBOutlet var imageView: UIImageView?
    var input: PHContentEditingInput?
    var image: UIImage?

    public func cancelContentEditing() {
        
    }
    
    public func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return false
    }
    
    public func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        input = contentEditingInput
        
        imageView?.image = placeholderImage
        
        let inputImage = CIImage(contentsOf: input!.fullSizeImageURL!)
        let context = CIContext()
        let orientedImage = inputImage?.applyingOrientation(input!.fullSizeImageOrientation)
        let cgImage = context.createCGImage(orientedImage!, from: orientedImage!.extent)
        image = UIImage(cgImage: cgImage!)
        image = processImage(image!)

        imageView?.image = image
    }
    
    public func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        let output = PHContentEditingOutput(contentEditingInput: input!)
        output.adjustmentData = PHAdjustmentData.unflare()
        
        let destination = CGImageDestinationCreateWithURL(output.renderedContentURL as CFURL, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(destination!, image!.cgImage!, nil)
        CGImageDestinationFinalize(destination!)
        
        completionHandler(output)
    }
    
}

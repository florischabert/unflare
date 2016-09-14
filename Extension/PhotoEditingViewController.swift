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

class PhotoEditingViewController: UIViewController, PHContentEditingController {
    public var shouldShowCancelConfirmation = true;
    
    @IBOutlet var imageView: UIImageView?
    var input: PHContentEditingInput?

    public func cancelContentEditing() {
        
    }
    
    public func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return adjustmentData.isUnflare()
    }
    
    public func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        var image: UIImage?
        try! image = UIImage(data: Data(contentsOf: contentEditingInput.fullSizeImageURL!))
        input = contentEditingInput
        imageView?.image = processImage(image!)
    }
    
    public func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        let output = PHContentEditingOutput(contentEditingInput: self.input!)
        output.adjustmentData = PHAdjustmentData.unflare()
        try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)
        
        completionHandler(output)
    }
    
}

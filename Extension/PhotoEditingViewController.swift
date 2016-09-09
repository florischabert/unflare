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
    var input: PHContentEditingInput?;

    public func cancelContentEditing() {
        
    }
    
    public func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return false;
    }
    
    public func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        let image = UIImage(contentsOfFile: (contentEditingInput.fullSizeImageURL?.path)!)
        input = contentEditingInput
        imageView?.image = processImage(image!)
    }
    
    public func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Swift.Void) {
        DispatchQueue.global().async {
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            output.adjustmentData = PHAdjustmentData(formatIdentifier: "UnFlare", formatVersion: "1.0", data: Data())
            
            try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)
            
            completionHandler(output)
        }
    }
    
}

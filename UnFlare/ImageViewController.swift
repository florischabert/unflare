//
//  ImageViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/8/16.
//  Copyright © 2016 floris. All rights reserved.
//

import UIKit
import Photos

class ImageViewController: UIViewController {
    
    var asset: PHAsset?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: nil, resultHandler: { result, info in
            DispatchQueue.main.async {
                self.imageView.image = result
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.button.title = "UnFlare"
    }
    
    @IBAction func unflare(_ sender: AnyObject) {
        button.isEnabled = false
        
        asset!.requestContentEditingInput(with: nil, completionHandler: { input, list in
            let output = PHContentEditingOutput(contentEditingInput: input!)
            output.adjustmentData = PHAdjustmentData(formatIdentifier: "UnFlare", formatVersion: "1.0", data: Data())

            self.imageView.image = processImage(self.imageView.image!)
            try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: self.asset!)
                request.contentEditingOutput = output
                
                DispatchQueue.main.async {
                    self.button.isEnabled = true
                    self.button.title = "Save"
                }
            })
        })
    }
    
}

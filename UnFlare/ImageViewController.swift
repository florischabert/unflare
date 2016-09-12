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
    @IBOutlet weak var topButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
            DispatchQueue.main.async {
                self.imageView.image = result
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        topButton.title = "UnFlare"
        topButton.isEnabled = true
    }
    
    @IBAction func action(_ sender: AnyObject) {
        if topButton.title == "UnFlare" {
            let pending = UIAlertController(title: "Unflaring...", message: nil, preferredStyle: .alert)
            
            present(pending, animated: true, completion: {
                let image = processImage(self.imageView.image!)
                DispatchQueue.main.async {
                    self.imageView.image = image
                    pending.dismiss(animated: true)
                    self.topButton.title = "Save"
                }
            })
        }
        else {
            topButton.isEnabled = false
            asset!.requestContentEditingInput(with: nil, completionHandler: { input, list in
                let output = PHContentEditingOutput(contentEditingInput: input!)
                output.adjustmentData = PHAdjustmentData(formatIdentifier: "io.nexan.apps.UnFlare", formatVersion: "1.0", data: "1.0".data(using: .utf8, allowLossyConversion: true)!)

                try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)

                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: self.asset!)
                    request.contentEditingOutput = output
                })
            })
        }
    }
}

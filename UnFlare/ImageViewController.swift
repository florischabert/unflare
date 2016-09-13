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
        
        topButton.title = "UnFlare"
        topButton.isEnabled = false
    }
    
    func updateImage() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
            DispatchQueue.main.async {
                self.imageView.image = result
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Int {
                    if isDegraded == 0 {
                        self.updateButton()
                    }
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateImage()
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

                if input?.adjustmentData == nil {
                    output.adjustmentData = PHAdjustmentData(formatIdentifier: "io.nexan.apps.UnFlare", formatVersion: "1.0", data: "1.0".data(using: .utf8, allowLossyConversion: true)!)

                    try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)
                }

                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: self.asset!)
                    if let _ = input?.adjustmentData {
                        request.revertAssetContentToOriginal()
                    }
                    else {
                        request.contentEditingOutput = output
                    }
                }, completionHandler: { bool, error in
                    if let _ = input?.adjustmentData {
                        self.updateImage()
                    }
                    if let _ = error {
                        DispatchQueue.main.async {
                            self.topButton.isEnabled = true
                        }
                    }
                    else {
                        self.updateButton()
                    }
                })
            })
        }
    }
    
    func updateButton() {
        let adjustmentData = PHAdjustmentData(formatIdentifier: "io.nexan.apps.UnFlare", formatVersion: "1.0", data: "1.0".data(using: .utf8, allowLossyConversion: true)!)

        asset!.requestContentEditingInput(with: nil) { input, list in
            DispatchQueue.main.async {
                if input?.adjustmentData?.formatIdentifier == adjustmentData.formatIdentifier &&
                    input?.adjustmentData?.formatVersion == adjustmentData.formatVersion {
                    self.topButton.title = "Revert"
                    self.topButton.tintColor = .red
                }
                else {
                    self.topButton.title = "UnFlare"
                    self.topButton.tintColor = UIView().tintColor
                }
                self.topButton.isEnabled = true
            }
        }
    }
}

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
    @IBOutlet weak var uflareButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: nil, resultHandler: { result, info in
            DispatchQueue.main.async {
                self.imageView.image = result
            }
        })
        
        saveButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.uflareButton.isEnabled = true
    }
    
    @IBAction func unflare(_ sender: AnyObject) {
        uflareButton.isEnabled = false
        let pending = UIAlertController(title: "Unflaring...", message: nil, preferredStyle: .alert)

        present(pending, animated: true, completion: {
            let image = processImage(self.imageView.image!)
            DispatchQueue.main.async {
                self.imageView.image = image
                pending.dismiss(animated: true)
                self.saveButton.isEnabled = true
            }
        })
    }
    
    @IBAction func save(_ sender: AnyObject) {
        saveButton.isEnabled = false
        asset!.requestContentEditingInput(with: nil, completionHandler: { input, list in
            let output = PHContentEditingOutput(contentEditingInput: input!)
            output.adjustmentData = PHAdjustmentData(formatIdentifier: "io.nexan.apps.UnFlare", formatVersion: "1.0", data: "1.0".data(using: .utf8, allowLossyConversion: true)!)

            try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: self.asset!)
                request.contentEditingOutput = output
            })
            
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        })
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        dismiss(animated: true)
    }
}

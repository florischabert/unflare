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
    var input: PHContentEditingInput?
    var processedImage: UIImage?
    var adjustmentData: PHAdjustmentData? {
        didSet {
            DispatchQueue.main.async {
                if self.adjustmentData?.isUnflare() ?? false {
                    self.topButton.tintColor = self.view.tintColor
                }
                else {
                    self.topButton.tintColor = UIColor.white
                }
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitle("", color: UIColor.white)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        slideTitle("Loading photo...")
        
        requestImage() {
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { adjustment in
                return adjustment.isUnflare()
            }
            self.asset!.requestContentEditingInput(with: options) { input, info in
                self.input = input
                
                self.slideTitle()
                self.topButton.isEnabled = true
                self.adjustmentData = input?.adjustmentData
            }
        }
    }
    
    func requestImage(_ version: PHImageRequestOptionsVersion = .current, block: @escaping () -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = version
        
        print(version.rawValue)
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
            
            print(result)
            print(info)
            DispatchQueue.main.async {
                self.imageView.image = result
                
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Int {
                    if isDegraded == 0 {
                        block()
                    }
                }
            }
        })
    }
    
    @IBAction func action(_ sender: AnyObject) {
        self.topButton.isEnabled = false
        self.doneButton.isEnabled = false
        
        if adjustmentData?.isUnflare() ?? false {
            self.slideTitle("Reverting photo...")
            
            requestImage(.unadjusted) {
                self.slideTitle()
                self.adjustmentData = nil
                self.topButton.isEnabled = true
                self.doneButton.isEnabled = true
            }
        }
        else {
            DispatchQueue.global().async {
                self.slideTitle("UnFlaring photo...")
                
                if self.processedImage == nil {
                    self.processedImage = processImage(self.imageView.image!)
                }
                
                self.slideTitle()
                
                DispatchQueue.main.async {
                    self.adjustmentData = PHAdjustmentData.unflare()
                    self.topButton.isEnabled = true
                    self.imageView.image = self.processedImage
                    self.doneButton.isEnabled = true
                }
            }
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    @IBAction func done(_ sender: AnyObject) {
        doneButton.isEnabled = false
        
        if (input?.adjustmentData?.isUnflare() ?? false) == (adjustmentData?.isUnflare() ?? false) {
            dismiss(animated: true)
            return
        }
        
        let output = PHContentEditingOutput(contentEditingInput: input!)
        output.adjustmentData = self.adjustmentData
        try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset!)
            
            if self.adjustmentData == nil {
                output.adjustmentData = PHAdjustmentData(formatIdentifier: "identity", formatVersion: "0", data: "0".data(using: .utf8, allowLossyConversion: true)!)
                request.contentEditingOutput = output
            }
            else {
                request.contentEditingOutput = output
            }
        }, completionHandler: { bool, error in
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        })
    }
}

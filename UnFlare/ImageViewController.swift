//
//  ImageViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/8/16.
//  Copyright © 2016 floris. All rights reserved.
//

import UIKit
import Photos

class ImageViewController: UIViewController, ZoomTransitionProtocol {
    
    var asset: PHAsset?
    var input: PHContentEditingInput?
    var processedImage: UIImage?
    var adjustmentData: PHAdjustmentData? {
        didSet {
            DispatchQueue.main.async {
                if self.adjustmentData?.isUnflare() ?? false {
                    self.topButton.tintColor = UIColor.orange
                }
                else {
                    self.topButton.tintColor = self.view.tintColor
                }
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true

        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
            self.imageView.image = result
        })
    
//        requestImage() {
//            let options = PHContentEditingInputRequestOptions()
//            options.canHandleAdjustmentData = { adjustment in
//                return adjustment.isUnflare()
//            }
//            self.asset!.requestContentEditingInput(with: options) { input, info in
//                self.input = input
//                
//                self.topButton.isEnabled = true
//                self.adjustmentData = input?.adjustmentData
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func requestImage(_ version: PHImageRequestOptionsVersion = .current, block: @escaping () -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = version
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
            DispatchQueue.main.async {
                self.imageView.image = result

                if let isDegraded = info?[PHImageResultIsDegradedKey] as? NSNumber {
                    if isDegraded == 0 {
                        block()
                    }
                }
            }
        })
    }
    
    @IBAction func action(_ sender: AnyObject) {
        self.topButton.isEnabled = false
        
        if adjustmentData?.isUnflare() ?? false {
            requestImage(.unadjusted) {
                self.adjustmentData = nil
                self.topButton.isEnabled = true
            }
        }
        else {
            DispatchQueue.global().async {
                if self.processedImage == nil {
                    self.processedImage = processImage(self.imageView.image!)
                }
                
                DispatchQueue.main.async {
                    self.adjustmentData = PHAdjustmentData.unflare()
                    self.topButton.isEnabled = true
                    self.imageView.image = self.processedImage
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
            }
        }
    }
    
    @IBAction func done(_ sender: AnyObject) {        
        if (input?.adjustmentData?.isUnflare() ?? false) == (adjustmentData?.isUnflare() ?? false) {
            navigationController?.setToolbarHidden(true, animated: false)
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
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.dismiss(animated: true)
            }
        })
    }

    func viewForTransition() -> UIView {
        return imageView
    }
}

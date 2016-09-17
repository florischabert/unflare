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
    }

    enum State {
        case disabled, unflare, save, revert
    }
    
    var state: State = .disabled {
        didSet {
            DispatchQueue.main.async {
                switch self.state {
                case .disabled: self.topButton.title = "UnFlare"
                case .unflare:  self.topButton.title = "UnFlare"
                case .save:     self.topButton.title = "Save"
                case .revert:   self.topButton.title = "Revert"
                }
                self.topButton.isEnabled = self.state != .disabled
                self.topButton.tintColor = self.state == .revert ? .red : self.view.tintColor
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        state = .disabled
        requestImage({
            self.asset!.requestContentEditingInput(with: nil) { input, info in
                self.slideTitle()
                
                self.state = .unflare
                if let isUnflare = input?.adjustmentData?.isUnflare(), isUnflare {
                    self.state = .revert
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupTitle("Photo")
        
        if state == .disabled {
            slideTitle("Loading")
        }
    }
    
    func requestImage(_ block: @escaping () -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: { result, info in
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
        switch state {
        case .unflare:
            self.slideTitle("UnFlaring")

            let image = processImage(self.imageView.image!)

            DispatchQueue.main.async {
                self.imageView.image = image
                self.state = .save
                
                self.slideTitle()
            }
        case .save:
            self.slideTitle("Saving")

            asset!.requestContentEditingInput(with: nil) { input, list in
                let output = PHContentEditingOutput(contentEditingInput: input!)
                output.adjustmentData = PHAdjustmentData.unflare()
                try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)
                
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: self.asset!)
                    request.contentEditingOutput = output
                }, completionHandler: { bool, error in
                    self.slideTitle()

                    if error == nil {
                        self.state = .revert
                    }
                })
            }
        case .revert:
            self.slideTitle("Reverting")

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: self.asset!)
                request.revertAssetContentToOriginal()
            }, completionHandler: { bool, error in
                self.slideTitle()

                if error == nil {
                    self.state = .unflare
                    self.requestImage() {}
                }
            })
        default: break
        }

    }
    
}

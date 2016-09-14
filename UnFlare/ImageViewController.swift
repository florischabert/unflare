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
                case .disabled: self.topButton.title = "Loading"
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
                self.state = .unflare
                if let isUnflare = input?.adjustmentData?.isUnflare(), isUnflare {
                    self.state = .revert
                }
            }
        })
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
            let pending = UIAlertController(title: "Unflaring...", message: nil, preferredStyle: .alert)
            present(pending, animated: true) {
                let image = processImage(self.imageView.image!)
                DispatchQueue.main.async {
                    self.imageView.image = image
                    pending.dismiss(animated: true)
                    self.state = .save
                }
            }
        case .save:
            asset!.requestContentEditingInput(with: nil) { input, list in
                let output = PHContentEditingOutput(contentEditingInput: input!)
                output.adjustmentData = PHAdjustmentData.unflare()
                try! UIImageJPEGRepresentation(self.imageView!.image!, 1)?.write(to: output.renderedContentURL)
                
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: self.asset!)
                    request.contentEditingOutput = output
                }, completionHandler: { bool, error in
                    if error == nil {
                        self.state = .revert
                    }
                })
            }
        case .revert:
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: self.asset!)
                request.revertAssetContentToOriginal()
            }, completionHandler: { bool, error in
                if error == nil {
                    self.state = .unflare
                    self.requestImage() {}
                }
            })
        default: break
        }

    }
    
}

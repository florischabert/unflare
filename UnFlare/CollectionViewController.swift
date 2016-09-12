//
//  ViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/3/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit
import Photos

class ViewCell : UICollectionViewCell {
    var asset: PHAsset?
}

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var assets: PHFetchResult<PHAsset>?
    var status: PHAuthorizationStatus?
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        PHPhotoLibrary.requestAuthorization { status in
            if self.status != status {
                self.status = status
                self.updateUI()
            }
        }
    }
    
    func updateUI() {
        if status == .denied {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "Denied", sender: self)
                }
            }
        else {
            DispatchQueue.global().async {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                self.assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    
                    let lastItem = self.collectionView?.numberOfItems(inSection: 0)
                    let indexPath = IndexPath(item: lastItem!-1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    func collectionView(_ collection: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.bounds.size.width/4
        if indexPath.row % 4 != 3  {
            size -= 1
        }
        return CGSize(width: size, height: size)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ViewCell
        let imageView = cell.viewWithTag(42) as! UIImageView
        let asset = assets!.object(at: indexPath.row)
        cell.asset = asset

//        DispatchQueue.global().async {
            let options = PHImageRequestOptions()
            options.resizeMode = .exact
            options.isSynchronous = true
            
            let retinaScale = UIScreen.main.scale;
            let retinaSquare = CGSize(width: 100*retinaScale, height: 100*retinaScale)

            let cropSideLength = min(asset.pixelWidth, asset.pixelHeight)
            let x = asset.pixelWidth > asset.pixelHeight ? abs(asset.pixelWidth - asset.pixelHeight) / 2 : 0
            let y = asset.pixelWidth > asset.pixelHeight ? 0 : abs(asset.pixelWidth - asset.pixelHeight) / 2
            let square = CGRect(x: x, y: y, width: cropSideLength, height: cropSideLength)
            let cropRect = square.applying(CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight)))
            options.normalizedCropRect = cropRect
            
            PHImageManager.default().requestImage(for: asset, targetSize: retinaSquare, contentMode: .aspectFit, options: options, resultHandler: {(result, info)->Void in
                DispatchQueue.main.async {
                    imageView.image = result
                }
            })
//        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Photo" {
            let cell = sender as! ViewCell
            let imageViewController = segue.destination as! ImageViewController
            imageViewController.asset = cell.asset
        }
    }

}
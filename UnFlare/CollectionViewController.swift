//
//  ViewController.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/3/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit
import Photos

// TODO: What if library access not allowed?

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var assets: PHFetchResult<PHAsset>?
    var firstTime = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if firstTime {
            collectionView?.scrollRectToVisible(CGRect(origin: CGPoint(x: collectionView!.contentSize.width-1, y: collectionView!.contentSize.height-1), size: CGSize(width: 1, height: 1)), animated: false)
            firstTime = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    func collectionView(_ collection: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = view.bounds.size.width/4-1
        return CGSize(width: size, height: size)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let imageView = cell.viewWithTag(42) as! UIImageView
        let asset = assets!.object(at: indexPath.row)

        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        
        let cropSideLength = min(asset.pixelWidth, asset.pixelHeight)
        let square = CGRect(x: 0, y: 0, width: cropSideLength, height: cropSideLength)
        let cropRect = square.applying(CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight)))
        options.normalizedCropRect = cropRect
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth/10, height: asset.pixelHeight/10), contentMode: .aspectFit, options: options, resultHandler: {(result, info)->Void in
            DispatchQueue.main.async {
                imageView.image = result
            }
        })
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "removeFlare" {
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView!.indexPath(for: cell)
            let imageViewController = segue.destination as! ImageViewController
            imageViewController.asset = assets!.object(at: indexPath!.row)
        }
    }

}

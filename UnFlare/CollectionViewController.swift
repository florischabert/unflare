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
    @IBOutlet weak var imageView: UIImageView!
}

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ZoomTransitionProtocol {

    var assets: PHFetchResult<PHAsset>?
    var status: PHAuthorizationStatus?
    
    var selectedIndexPath: IndexPath?
    
    var animationController: ZoomTransition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.toolbar.isHidden = true
        
        if let navigationController = self.navigationController {
            animationController = ZoomTransition(navigationController: navigationController)
        }
        navigationController?.delegate = animationController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
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
        let photosPerRow = UIDevice.current.orientation.isLandscape ? 6 : 4

        let size = Int(view.bounds.size.width)/photosPerRow
        let remainer = Int(view.bounds.size.width) % photosPerRow
        let width = indexPath.row % photosPerRow != photosPerRow-1 ? size-1 : size + remainer
        return CGSize(width: width, height: size)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ViewCell
        let asset = assets!.object(at: indexPath.row)
        cell.asset = asset

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
                cell.imageView.image = result
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Photo" {
            let cell = sender as! ViewCell
            let imageViewController = segue.destination as! ImageViewController
            imageViewController.asset = cell.asset
        }
    }
    
    func viewForTransition() -> UIView {
        collectionView?.layoutIfNeeded()
        return (collectionView?.cellForItem(at: selectedIndexPath!) as! ViewCell).imageView
    }
    
}

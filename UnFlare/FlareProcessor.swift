//
//  FlareProcessor.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/8/16.
//  Copyright © 2016 floris. All rights reserved.
//

import UIKit
import FlareProcessor

func processImage(_ image: UIImage) -> UIImage {
    let detector = FlareDetector(image: image);
    detector?.setThresholdWithStep(20, min: 100, max: 255);
    detector?.setFilter(.byCircularity, min: 0.8, max: 1);
    detector?.setFilter(.byArea, min: 100, max: 2000);
    detector?.setFilter(.byConvexity, min: 0.8, max: 1);
    detector?.setFilter(.byInertia, min: 0.7, max: 1);
    
    let mask = detector?.detectFlareMask();
    let inpainter = FlareInpainter(image: image, mask: mask);
    let inpaintedImage = inpainter?.inpaintTELEA(withRadius: 10);
//    let inpaintedImage = inpainter?.inpaintExemplar(withWindowSize: 200, patchSize: 9);

    return inpaintedImage!
}

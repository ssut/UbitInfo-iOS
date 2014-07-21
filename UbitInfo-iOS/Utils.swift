//
//  Utils.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/22/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import Foundation

func scaleImage(image: UIImage, newSize: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
    var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

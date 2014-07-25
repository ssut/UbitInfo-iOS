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

func localizedString(key: String) -> String {
    let string: String? = NSLocalizedString(key, tableName: nil, comment: "")
    return string!
}

func buildURL(path: String) -> (string: String, nsurl: NSURL) {
    let url: String = URL_PREFIX + path
    
    return (url, NSURL(string: url))
}

extension NSDate {
    func toString(format: String) -> String {
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = format
        
        return formatter.stringFromDate(self)
    }
}

//
//  IIVImageRect.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 28.8.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

// Inspired by:
// https://github.com/BasselEzzeddine/PhotoCrop

import UIKit

public struct IIVImageRect {
    static func getImageRect(fromImageView imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.frame.size
        let imgSize = imageView.image?.size

        guard let imageSize = imgSize else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)

        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += imageView.frame.origin.x
        imageRect.origin.y += imageView.frame.origin.y

        return imageRect
    }
}

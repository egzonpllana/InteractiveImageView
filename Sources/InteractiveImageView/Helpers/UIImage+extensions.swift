//
//  UIImage+extensions.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 7.2.24.
//  Copyright © 2024 Egzon Pllana. All rights reserved.
//

import UIKit

// MARK: - Rotate image -
public extension UIImage {
    func rotated(by degrees: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: self.size.width / 2, y: self.size.height / 2)
        context.rotate(by: degrees * CGFloat.pi / 180.0)

        self.draw(at: CGPoint(x: -self.size.width / 2, y: -self.size.height / 2))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }
}

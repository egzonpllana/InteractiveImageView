//
//  InteractiveImageViewProtocol.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 4.11.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

import UIKit

public protocol InteractiveImageViewProtocol {
    /// Double tap scale factor, default value is 2.0.
    var doubleTapZoomFactor: CGFloat { get set }

    /// Setup initial properties of the view.
    /// - Parameters:
    ///   - nextContentMode: Next content mode, for example heightFill.
    ///   - focusOffset: Initial focus mode of the image view, center or top.
    ///   - image: Image to interact with.
    ///   - identifier: This identifier represents UIView tag.
    func configure(withNextContentMode nextContentMode: IIVContentMode,  withFocusOffset focusOffset: IIVFocusOffset, withImage image: UIImage?, withIdentifier identifier: Int)

    /// Setup initial properties of the view.
    /// - Parameters:
    ///   - nextContentMode: Next content mode, for example heightFill.
    ///   - focusOffset: Initial focus mode of the image view, center or top.
    ///   - image: Image to interact with.
    func configure(withNextContentMode nextContentMode: IIVContentMode,  withFocusOffset focusOffset: IIVFocusOffset, withImage image: UIImage?)

    /// Set image view focus properties with content offset and zoom scale.
    /// - Parameters:
    ///   - offset: Offset to focus.
    ///   - animated: Animation state when performing offset changes.
    ///   - zoomScale: Zoom scale to apply on ImageView.
    func setContentOffset(_ offset: CGPoint, animated: Bool, zoomScale: CGFloat)

    /// Toggle between initial content mode (aspectFill) and nextContentMode.
    func toggleImageContentMode()

    /// Perform croping image process visible image and listen to delegates to get cropped image.
    func performCropImage()

    /// Crop and get presented image.
    /// - Returns: UIImage?
    func cropAndGetImage() -> UIImage?

    /// Set UIImageView image without changing other IIV view attributes.
    /// - Parameter image: UIImage?
    func setImage(_ image: UIImage?)

    /// Get initial state of the image without any modifications.
    /// - Returns: UIImage?
    func getOriginalImage() -> UIImage?
}

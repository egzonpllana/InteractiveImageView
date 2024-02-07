//
//  InteractiveImageViewProtocol.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 4.11.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

import UIKit

/// A protocol defining methods to interact with an image within an `InteractiveImageView`.
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
    ///
    /// - Returns: UIImage?
    func cropAndGetImage() -> UIImage?

    /// Updates the image displayed in the interactive image view.
    ///
    /// - Parameter image: The new image to be displayed.
    func updateImageOnly(_ image: UIImage?)
    
    /// Updates the image view with the provided image.
    ///
    /// - Parameter image: The image to be displayed.
    func updateImageView(withImage image: UIImage?)
    
    /// Retrieves the original image displayed in the interactive image view.
    ///
    /// - Returns: The original image displayed in the interactive image view.
    func getOriginalImage() -> UIImage?
    
    /// Rotates the image displayed in the interactive image view by the specified degrees.
    ///
    /// - Parameters:
    ///   - degrees: The angle, in degrees, by which to rotate the image.
    ///   - keepChanges: A Boolean value that determines whether the changes made to the image (e.g., cropping or scaling) should be preserved after rotation.
    ///                  If `true`, the rotated image will be based on the current state of the image view, preserving any previous changes.
    ///                  If `false`, the original image will be reset and then rotated, discarding any previous changes made to the image.
    func rotateImage(_ degrees: CGFloat, keepChanges: Bool)
}

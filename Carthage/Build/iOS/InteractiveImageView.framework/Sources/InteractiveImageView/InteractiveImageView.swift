//
//  InteractiveImageView.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 28.8.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

import UIKit

protocol InteractiveImageViewDelegate: UIScrollViewDelegate {
    func didCropImage(image: UIImage)
    func didFailImageCropping()
    func didFailTogglingContentMode()
    func didFailAdjustingFramesWhenZooming()
    func didFailToGetImageView()
}

protocol InteractiveImageViewProtocol {
    func configure(withNextContentMode nextContentMode: IIVContentMode,  withFocusOffset initialOffset: IIVFocusOffset, withImage image: UIImage)
    func toggleImageContentMode()
    func cropImage()
}

public class InteractiveImageView: UIScrollView {

    // MARK: - Properties

    weak var interactiveImageViewDelegate: InteractiveImageViewDelegate?

    private var imageView: UIImageView? = nil
    private var imageContentMode: IIVContentMode = .widthFill
    private var nextContentMode: IIVContentMode = .aspectFit
    private var configuredImage: UIImage? = nil
    private var imageSize: CGSize = CGSize.zero
    private var initialOffset: IIVFocusOffset = .begining
    private var scrollViewOffsetY: CGFloat = 0.0
    private var scrollViewOffsetX: CGFloat = 0.0
    private var pointToCenterAfterResize: CGPoint = CGPoint.zero
    private var scaleToRestoreAfterResize: CGFloat = 1.0
    private var maxScaleFromMinScale: CGFloat = 3.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollView.DecelerationRate.fast
        delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(InteractiveImageView.changeOrientationNotification), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    // MARK: - Deinitialization

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Overrides

    public override var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }
}

// MARK: - InteractiveImageViewProtocol

extension InteractiveImageView: InteractiveImageViewProtocol {
    public func configure(withNextContentMode nextContentMode: IIVContentMode,  withFocusOffset focusOffset: IIVFocusOffset, withImage image: UIImage) {

        // Setup private properties
        self.nextContentMode = nextContentMode
        self.configuredImage = image
        self.initialOffset = focusOffset
        self.setImage(image)

        // get top super view
        var topSupperView = superview
        while topSupperView?.superview != nil {
            topSupperView = topSupperView?.superview
        }
        // make sure views have already layout with precise frame
        topSupperView?.layoutIfNeeded()

        // reload UI in main thread
        DispatchQueue.main.async { self.refresh() }
    }

    public func toggleImageContentMode() {
        guard let configuredImage = configuredImage else {
            interactiveImageViewDelegate?.didFailTogglingContentMode()
            return
        }

        imageContentMode = (imageContentMode != nextContentMode) ? nextContentMode : .aspectFill
        setImage(configuredImage)
    }

    public func cropImage() {
        guard let imageView = imageView else {
            interactiveImageViewDelegate?.didFailToGetImageView()
            return
        }
        let scrollViewFrameX = self.frame.origin.x
        let imageViewFrameX = IIVImageRect.getImageRect(fromImageView: imageView).origin.x
        let framesOnX = scrollViewFrameX - imageViewFrameX

        // Crop image based on: image width is smaller than scroll view width or not.
        let cropOffsetOnX: CGFloat = (framesOnX > 0) ? (scrollViewOffsetX - (2*imageViewFrameX)) : framesOnX

        let cropRect = CGRect(x: cropOffsetOnX,
                              y: scrollViewOffsetY - IIVImageRect.getImageRect(fromImageView: imageView).origin.y,
                              width: self.frame.width,
                              height: self.frame.height)

        let croppedImage = IIVCropHandler.cropImage(imageView.image!,
                                                                     toRect: cropRect,
                                     viewWidth: IIVImageRect.getImageRect(fromImageView: imageView).width,
                                     viewHeight: self.imageView!.frame.height)
        if let image = croppedImage {
            self.interactiveImageViewDelegate?.didCropImage(image: image)
        } else {
            self.interactiveImageViewDelegate?.didFailImageCropping()
        }
    }
}

// MARK: - Private extension

// Inspired by:
// https://github.com/huynguyencong/ImageScrollView

private extension InteractiveImageView {

    func setImage(_ image: UIImage) {
        // Remove old view
        if let zoomView = imageView {
            zoomView.removeFromSuperview()
        }

        // Add new view
        imageView = UIImageView(image: image)
        imageView!.isUserInteractionEnabled = true
        addSubview(imageView!)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(InteractiveImageView.doubleTapGestureRecognizer(_:)))
        tapGesture.numberOfTapsRequired = 2
        imageView!.addGestureRecognizer(tapGesture)
        configureImageForSize(image.size)
    }

    func refresh() {
        if let image = imageView?.image {
            setImage(image)
        }
    }

    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    func adjustFrameToCenterWhenZoomed() {
        guard let unwrappedZoomView = imageView else {
            interactiveImageViewDelegate?.didFailAdjustingFramesWhenZooming()
            return
        }
        var frameToCenter = unwrappedZoomView.frame

        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }

        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }

        unwrappedZoomView.frame = frameToCenter
    }

    func configureImageForSize(_ size: CGSize) {
        imageSize = size
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale

        switch initialOffset {
        case .begining:
            contentOffset =  CGPoint.zero
        case .center:
            let xOffset = contentSize.width < bounds.width ? 0 : (contentSize.width - bounds.width)/2
            let yOffset = contentSize.height < bounds.height ? 0 : (contentSize.height - bounds.height)/2

            switch imageContentMode {
            case .aspectFit:
                contentOffset =  CGPoint.zero
            case .aspectFill:
                contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                contentOffset = CGPoint(x: 0, y: yOffset)
            case .customOffset:
                contentOffset = CGPoint(x: 0, y: yOffset)
            }
        }
    }

    func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = bounds.height / imageSize.height   // the scale needed to perfectly fit the image height-wise

        var minScale: CGFloat = 1

        switch imageContentMode {
        case .aspectFill:
            minScale = max(xScale, yScale)
        case .aspectFit:
            minScale = min(xScale, yScale)
        case .widthFill:
            minScale = xScale
        case .heightFill:
            minScale = yScale
        case .customOffset(let offset):
            minScale = xScale * (offset)
        }

        let maxScale = maxScaleFromMinScale*minScale

        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }

        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }

    func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: imageView)

        scaleToRestoreAfterResize = zoomScale

        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }

    func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()

        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)

        // restore center point, first making sure it is within the allowable range.

        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: imageView)

        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)

        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()

        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)

        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)

        contentOffset = offset
    }

    func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }

    func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }
}

// MARK: - Observers methods

private extension InteractiveImageView {
    @objc private func changeOrientationNotification() {
        // Reload UI in main thread
        DispatchQueue.main.async {
            self.configureImageForSize(self.imageSize)
        }
    }

    @objc private func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than the scale factor after double-tap scaling. Else, zoom in
        let zoomFactorWhenDoubleTap: CGFloat = 2.0
        if zoomScale >= minimumZoomScale * zoomFactorWhenDoubleTap - 0.01 {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(zoomFactorWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension InteractiveImageView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Update private properties
        scrollViewOffsetY = scrollView.contentOffset.y
        scrollViewOffsetX = scrollView.contentOffset.x

        // Notificy delegate observers
        interactiveImageViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        interactiveImageViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        interactiveImageViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        interactiveImageViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        interactiveImageViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        interactiveImageViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        interactiveImageViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        interactiveImageViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        interactiveImageViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    @available(iOS 11.0, *)
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        interactiveImageViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenterWhenZoomed()
        interactiveImageViewDelegate?.scrollViewDidZoom?(scrollView)
    }
}

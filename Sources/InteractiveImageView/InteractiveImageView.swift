//
//  InteractiveImageView.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 28.8.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

import UIKit

public protocol InteractiveImageViewDelegate: AnyObject {
    func didCropImage(image: UIImage)
    func didFailImageCropping()
    func didFailTogglingContentMode()
    func didFailAdjustingFramesWhenZooming()
    func didFailToGetImageView()
    func didScrollAt(offset: CGPoint, scale: CGFloat)
    func didZoomAt(offset: CGPoint, scale: CGFloat)
}

public protocol InteractiveImageViewProtocol {
    func configure(withNextContentMode nextContentMode: IIVContentMode,  withFocusOffset initialOffset: IIVFocusOffset, withImage image: UIImage)
    func toggleImageContentMode()
    func setContentOffset(_ offset: CGPoint, animated: Bool, zoomScale: CGFloat)
    func cropImage()
}

public class InteractiveImageView: UIView {

    // MARK: - Properties

    public weak var delegate: InteractiveImageViewDelegate?
    public var isScrollEnabled: Bool = true {
        didSet {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }
    public var isPinchAllowed: Bool = true {
        didSet {
            scrollView.pinchGestureRecognizer?.isEnabled = isPinchAllowed
        }
    }
    public var isDoubleTapToZoomAllowed: Bool = true

    private var scrollView: UIScrollView = UIScrollView()
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
        // Setup scroll view properties
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        scrollView.delegate = self

        // A workaround to setup pinchGestureRecognizer
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.scrollView.pinchGestureRecognizer?.isEnabled = self.isPinchAllowed
        }

        // Add scroll view as a subview
        self.addSubview(scrollView)

        // Add scroll view constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            scrollView.widthAnchor.constraint(equalTo: self.widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])

        // Add observer for: changeOrientationNotification
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
            delegate?.didFailTogglingContentMode()
            return
        }

        imageContentMode = (imageContentMode != nextContentMode) ? nextContentMode : .aspectFill
        setImage(configuredImage)
    }

    public func cropImage() {
        guard let imageView = imageView else {
            delegate?.didFailToGetImageView()
            return
        }

        let cropRect = CGRect(x: scrollViewOffsetX,
                              y: scrollViewOffsetY,
                              width: self.frame.width,
                              height: self.frame.height)

        let croppedImage = IIVCropHandler.cropImage(imageView.image!,
                                                                     toRect: cropRect,
                                     viewWidth: IIVImageRect.getImageRect(fromImageView: imageView).width,
                                     viewHeight: self.imageView!.frame.height)
        if let image = croppedImage {
            self.delegate?.didCropImage(image: image)
        } else {
            self.delegate?.didFailImageCropping()
        }
    }

    public func setContentOffset(_ offset: CGPoint, animated: Bool, zoomScale: CGFloat) {
        scrollView.setZoomScale(zoomScale, animated: false)
        scrollView.setContentOffset(offset, animated: animated)
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
        scrollView.addSubview(imageView!)

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
            delegate?.didFailAdjustingFramesWhenZooming()
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
        scrollView.contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        scrollView.zoomScale = scrollView.minimumZoomScale

        switch initialOffset {
        case .begining:
            scrollView.contentOffset =  CGPoint.zero
        case .center:
            let xOffset = scrollView.contentSize.width < bounds.width ? 0 : (scrollView.contentSize.width - bounds.width)/2
            let yOffset = scrollView.contentSize.height < bounds.height ? 0 : (scrollView.contentSize.height - bounds.height)/2

            switch imageContentMode {
            case .aspectFit:
                scrollView.contentOffset =  CGPoint.zero
            case .aspectFill:
                scrollView.contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                scrollView.contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                scrollView.contentOffset = CGPoint(x: 0, y: yOffset)
            case .customOffset:
                scrollView.contentOffset = CGPoint(x: 0, y: yOffset)
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

        scrollView.maximumZoomScale = maxScale
        scrollView.minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }

    func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: imageView)

        scaleToRestoreAfterResize = scrollView.zoomScale

        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= scrollView.minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }

    func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()

        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(scrollView.minimumZoomScale, scaleToRestoreAfterResize)
        scrollView.zoomScale = min(scrollView.maximumZoomScale, maxZoomScale)

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

        scrollView.contentOffset = offset
    }

    func maximumContentOffset() -> CGPoint {
        return CGPoint(x: scrollView.contentSize.width - bounds.width,y:scrollView.contentSize.height - bounds.height)
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
        // make sure Zoom is allowed
        guard isDoubleTapToZoomAllowed else { return }

        // zoom out if it bigger than the scale factor after double-tap scaling. Else, zoom in
        let zoomFactorWhenDoubleTap: CGFloat = 2.0
        if scrollView.zoomScale >= scrollView.minimumZoomScale * zoomFactorWhenDoubleTap - 0.01 {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(zoomFactorWhenDoubleTap * scrollView.minimumZoomScale, center: center)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension InteractiveImageView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Update private properties
        scrollViewOffsetY = scrollView.contentOffset.y
        scrollViewOffsetX = scrollView.contentOffset.x
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.didScrollAt(offset: CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y), scale: scrollView.zoomScale)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) { }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.didZoomAt(offset: scrollView.contentOffset, scale: scrollView.zoomScale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    @available(iOS 11.0, *)
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) { }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenterWhenZoomed()
    }
}

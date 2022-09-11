//
//  ViewController.swift
//  InteractiveImageViewExample
//
//  Created by Egzon Pllana on 25.8.22.
//

import UIKit
import InteractiveImageView

class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var imageView: InteractiveImageView!
    @IBOutlet private weak var croppedImageView: UIImageView!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // Configure InteractiveImageView
        configureImageView()
    }

    // MARK: - Methods

    private func configureImageView() {
        // Setup imageView
        let imageExample = #imageLiteral(resourceName: "image.png")
        imageView.configure(withNextContentMode: .customOffset(offset: Double(2)/Double(3)), withFocusOffset: .center, withImage: imageExample, withIdentifier: 0)
        imageView.delegate = self

        // Controll imageView user actions
        imageView.isScrollEnabled = true
        imageView.isDoubleTapToZoomAllowed = true
        imageView.isPinchAllowed = false

    }

    // MARK: - Actions


    @IBAction func changeContentModePressed(_ sender: Any) {
        imageView.toggleImageContentMode()
    }

    @IBAction func cropImagePressed(_ sender: Any) {
        // Crop: Method 1
        imageView.performCropImage()

        // Crop: Method 2
        // Use direct crop image method.
        // croppedImageView.image = imageView.cropAndGetImage()
    }
}

extension ViewController: InteractiveImageViewDelegate {
    func didCropImage(image: UIImage, fromView: InteractiveImageView) {
        croppedImageView.image = image
    }

    func didScrollAt(offset: CGPoint, scale: CGFloat, fromView: InteractiveImageView) {
        //
    }

    func didZoomAt(offset: CGPoint, scale: CGFloat, fromView: InteractiveImageView) {
        //
    }

    func didFail(_ fail: IIVFailType) {
        //
    }
}

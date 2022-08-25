//
//  IIVContentMode.swift
//  InteractiveImageView
//
//  Created by Egzon Pllana on 28.8.22.
//  Copyright © 2022 Egzon Pllana. All rights reserved.
//

import UIKit

public enum IIVContentMode: Equatable {
    case aspectFill
    case aspectFit
    case widthFill
    case heightFill
    case customOffset(offset: CGFloat)
}

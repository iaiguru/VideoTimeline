//
//  UIView+Extension.swift
//  VideoTimeline
//
//  Created by hope on 12/16/22.
//

import Foundation
import UIKit

extension UIView {
    func constraints(leading: NSLayoutXAxisAnchor? = nil,
                     top: NSLayoutYAxisAnchor? = nil,
                     trailing: NSLayoutXAxisAnchor? = nil,
                     bottom: NSLayoutYAxisAnchor? = nil,
                     paddingLeft: CGFloat = 0,
                     paddingTop: CGFloat = 0,
                     paddingRight: CGFloat = 0,
                     paddingBottom: CGFloat = 0,
                     width: CGFloat? = nil,
                     height: CGFloat? = nil,
                     centerX: NSLayoutXAxisAnchor? = nil,
                     centerY: NSLayoutYAxisAnchor? = nil) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: paddingLeft).isActive = true
        }
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: -paddingRight).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
    }
    
    func aspectRatio(_ ratio: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                           toItem: self, attribute: .width, multiplier: 1/ratio, constant: 0)
    }
}

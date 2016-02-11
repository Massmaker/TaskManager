//
//  UIView+Extensions.swift
//  TaskManager
//
//  Created by CloudCraft on 2/11/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    func maskToCircle(withShadow shadow:Bool){
        
        let bounds = self.bounds
        let minValue = min(bounds.size.height, bounds.size.width)
        let path = UIBezierPath(ovalInRect: bounds)//UIBezierPath(roundedRect: bounds, cornerRadius:minValue / 2.0)
        
        let layer = CAShapeLayer()
        layer.frame = bounds
        layer.path = path.CGPath
        
        if shadow{
            
            guard let superview = self.superview else{
                return
            }
            
            let shadowLayer = CALayer()
            shadowLayer.frame = CGRectMake(0.0, 0.0, bounds.width, bounds.height)
            shadowLayer.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.6).CGColor;
            shadowLayer.shadowOffset = CGSizeMake(3.0, 3.0);
            shadowLayer.shadowOpacity = 1.0;
            
            shadowLayer.shadowPath = path.CGPath
            superview.layer.insertSublayer(shadowLayer, below: self.layer)
        }
        else
        {
            let lineWidth = minValue / 25.0
            let borderLayer = CAShapeLayer()
            borderLayer.frame = bounds
            borderLayer.cornerRadius = minValue / 2.0
            borderLayer.masksToBounds = true
            borderLayer.borderWidth = lineWidth

            borderLayer.borderColor = self.tintColor.CGColor
        
            //added simple border handling above
            //and
            //commented below because the approach did cause some not antialiased circle
            
//            //borderLayer.backgroundColor = self.tintColor.CGColor
//            let circlePath = UIBezierPath(ovalInRect: CGRectInset(bounds, lineWidth + lineWidth / 1.5 , lineWidth + lineWidth / 1.5))
//            //circlePath.lineWidth = minValue / 10.0
//            
//            borderLayer.drawsAsynchronously = true
//            borderLayer.fillColor = UIColor.clearColor().CGColor
//            borderLayer.fillRule = kCAFillRuleEvenOdd
//            borderLayer.strokeColor = self.tintColor.CGColor
//            borderLayer.lineWidth = lineWidth
//            borderLayer.lineJoin = kCALineJoinRound
//            
//            borderLayer.edgeAntialiasingMask = [.LayerLeftEdge, .LayerRightEdge, .LayerBottomEdge, .LayerTopEdge ]
////            borderLayer.strokeStart = 0.1
////            borderLayer.strokeEnd = 0.9
//            
//            borderLayer.path = circlePath.CGPath
            self.layer.addSublayer(borderLayer)
        }
        
        self.layer.mask = layer
    }
}
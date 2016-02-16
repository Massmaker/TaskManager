//
//  UIImage+Extensions.swift
//  TaskManager
//
//  Created by CloudCraft on 1/28/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

let testAvatarImage = UIImage(named: "No_Avatar")
let checkboxImage = UIImage(named: "CheckBox_1")
extension UIImage{

    var hasAlpha:Bool{
        let alphaInfo:CGImageAlphaInfo = CGImageGetAlphaInfo(self.CGImage)
        switch alphaInfo{
        case .First, .Last, .PremultipliedFirst, .PremultipliedLast:
            return true
        default:
            return false
        }
    }
    
    func imageWithAlpha() -> UIImage?{
        if self.hasAlpha{
            return self
        }
        
        guard let imageRef = self.CGImage else{
            return nil
        }
        
        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let colorSpace = CGImageGetColorSpace(imageRef)
        
        let offscreenContext = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        CGContextDrawImage(offscreenContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
        guard let cgImageWithAlpha = CGBitmapContextCreateImage(offscreenContext) else{
            return nil
        }
        
        let image = UIImage(CGImage: cgImageWithAlpha)
        
        return image
    }
    
    func transparentBorderImage(border:UInt) -> UIImage?{
        guard let transparentImage = self.imageWithAlpha() else{
            return nil
        }
        
        guard let cgImage = self.CGImage else{
            return nil
        }
        
        // Build a context that's the same dimensions as the new size
        let newRect = CGRectMake(0, 0, transparentImage.size.width + CGFloat(border) * CGFloat(2.0), transparentImage.size.height + CGFloat(border) * 2.0)
        guard let bitmapContext = CGBitmapContextCreate(nil, Int(newRect.size.width), Int(newRect.size.height), CGImageGetBitsPerComponent(cgImage), 0, CGImageGetColorSpace(cgImage), CGImageGetBitmapInfo(cgImage).rawValue) else {
            return nil
        }
        
        // Draw the image in the center of the context, leaving a gap around the edges
        let imageLocation = CGRectMake(CGFloat(border), CGFloat(border), transparentImage.size.width, transparentImage.size.height)
        CGContextDrawImage(bitmapContext, imageLocation, cgImage)

        guard let imageRef = CGBitmapContextCreateImage(bitmapContext) else{
            return nil
        }
        
        // Create a mask to make the border transparent, and combine it with the image
        guard let maskRef = self.newBorderMask(border, size: newRect.size) else{
            return nil
        }
        
        guard let transparentBorderImageRef = CGImageCreateWithMask(imageRef, maskRef) else{
            return nil
        }
        
        let transparentBorderImage = UIImage(CGImage: transparentBorderImageRef)
        
        return transparentBorderImage
        
    }
    
    func roundedCornerImageWith(corner:Int, borderSize:Int) -> UIImage {
        // If the image does not have an alpha layer, add one
        guard let image = self.imageWithAlpha() else{
            return self
        }
        
        // Build a context that's the same dimensions as the new size
        let imageSize = image.size
        
        guard let context = CGBitmapContextCreate(nil,
            Int(imageSize.width),
            Int(imageSize.height),
            CGImageGetBitsPerComponent(image.CGImage),
            0,
            CGImageGetColorSpace(image.CGImage),
            CGImageGetBitmapInfo(image.CGImage).rawValue) else {
                
                return self
        }
        
        // Create a clipping path with rounded corners
        let floatBorder = CGFloat(borderSize)
        let floatCorner = CGFloat(corner)
        let anotherRect = CGRectMake(floatBorder, floatBorder, imageSize.width - floatBorder * 2.0 , imageSize.height - floatBorder * 2.0)
        CGContextBeginPath(context);
        self.addRoundedRectToPath(anotherRect, context: context, ovalWidth: floatCorner, ovalHeight: floatCorner)
        
        CGContextClosePath(context)
        CGContextClip(context)
        
        
        // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
        let bounds = CGRectMake(0, 0, imageSize.width, imageSize.height)
        CGContextDrawImage(context, bounds, image.CGImage)
        
        // Create a CGImage from the context
        guard let clippedImageRef = CGBitmapContextCreateImage(context) else {
            return self
        }
        
        let imageToReturn = UIImage(CGImage: clippedImageRef)
        
        return imageToReturn
    }
    
    /**
    - Returns: 
        - a copy of this image that is cropped to the given bounds. 
        - source image if no CGImage found(e.g. image was created using CIImage)
    - The bounds will be adjusted using CGRectIntegral.
    - Note: This method ignores the image's imageOrientation setting.
    */
    
    func croppedToBounds(bounds:CGRect) -> UIImage{
        guard let imageRef = self.CGImage else{
            return self
        }
        
        CGImageCreateWithImageInRect(imageRef, bounds)
        let croppedImage = UIImage(CGImage: imageRef)
        return croppedImage
    }
    /**
      - Returns: a copy of this image that is squared to the thumbnail size.
      - If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.
     */
    func thumbnailImageSize(size:Int, transparentBorder:UInt, cornerRadius:UInt, interPolationQuality:CGInterpolationQuality) -> UIImage? {
        // Crop out any part of the image that's larger than the thumbnail size
        // The cropped rect must be centered on the resized image
        // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
        
        return nil
        //TODO: - finish method implementation
        /*
        CGRect cropRect = CGRectMake(round((resizedImage.size.width - thumbnailSize) / 2),
        round((resizedImage.size.height - thumbnailSize) / 2),
        thumbnailSize,
        thumbnailSize);
        UIImage *croppedImage = [resizedImage croppedImage:cropRect];
        
        UIImage *transparentBorderImage = borderSize ? [croppedImage transparentBorderImage:borderSize] : croppedImage;
        
        return [transparentBorderImage roundedCornerImage:cornerRadius borderSize:borderSize]
        */
    }
    
    
    //MARK: - helpers, not to use directly
    func newBorderMask(border:UInt, size:CGSize) -> CGImageRef?{
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        
        // Build a context that's the same dimensions as the new size
        let uintNeeded = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.None.rawValue
        guard let maskContext = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, grayColorSpace, uintNeeded) else{
            return nil
        }
        
        // Start with a mask that's entirely transparent
        CGContextSetFillColorWithColor(maskContext, UIColor.blackColor().CGColor)
        CGContextFillRect(maskContext, CGRectMake(0, 0, size.width, size.height))
        
        // Make the inner part (within the border) opaque
        CGContextSetFillColorWithColor(maskContext, UIColor.whiteColor().CGColor)
        let cgFloatBorder = CGFloat(border)
        
        // Make the inner part (within the border) opaque
        let frame = CGRectMake(CGFloat(border), CGFloat(border), size.width - cgFloatBorder * 2.0, size.height - cgFloatBorder * 2.0)
        CGContextFillRect(maskContext, frame)
        
        // Get an image of the context
        guard let imageRef = CGBitmapContextCreateImage(maskContext) else { return nil }
        
        return imageRef
        
    }
    
    func addRoundedRectToPath(rect:CGRect, context:CGContextRef, ovalWidth:CGFloat, ovalHeight:CGFloat){
        if ovalHeight <= 0 || ovalWidth <= 0 {
            CGContextAddRect(context, rect)
            return
        }
        
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect))
        CGContextScaleCTM(context, ovalWidth, ovalHeight)
        let aWidth = CGRectGetWidth(rect) / ovalWidth
        let aHeight = CGRectGetHeight(rect) / ovalHeight
        
        CGContextMoveToPoint(context, aWidth, aHeight / 2.0)
        
        CGContextAddArcToPoint(context, aWidth, aHeight, aWidth / 2.0, aHeight, 1.0)
        CGContextAddArcToPoint(context, 0, aHeight, 0, aHeight / 2.0, 1.0)
        CGContextAddArcToPoint(context, 0, 0, aWidth / 2.0, 0.0, 1.0)
        CGContextAddArcToPoint(context, aWidth, 0, aWidth / 2.0, aHeight / 2.0, 1.0)
        
        CGContextClosePath(context)
        
        CGContextRestoreGState(context)
        
    }
    
    /// Returns an affine transform that takes into account the image orientation when drawing a scaled image
    func transformFromOrientationWithSize(size:CGSize) -> CGAffineTransform{
    
        var aTransform = CGAffineTransformIdentity
        
        switch self.imageOrientation{
        case    .Down,              // EXIF = 3
                .DownMirrored:      // EXIF = 4
            aTransform = CGAffineTransformTranslate(aTransform, size.width, size.height)
            aTransform = CGAffineTransformRotate(aTransform, CGFloat(M_PI))
        case    .Left,              // EXIF = 6
                .LeftMirrored:      // EXIF = 5
            aTransform = CGAffineTransformTranslate(aTransform, size.width, 0)
            aTransform = CGAffineTransformRotate(aTransform, CGFloat(M_PI_2))
        case    .Right,             // EXIF = 8
                .RightMirrored:     // EXIF = 7
            aTransform = CGAffineTransformTranslate(aTransform, 0, size.height);
            aTransform = CGAffineTransformRotate(aTransform, CGFloat(-M_PI_2) );
        default:
            break
        }
        
        switch self.imageOrientation{
            case    .UpMirrored,    // EXIF = 2
                    .DownMirrored:  // EXIF = 4
                aTransform = CGAffineTransformTranslate(aTransform, size.width, 0);
                aTransform = CGAffineTransformScale(aTransform, -1, 1);
        case    .LeftMirrored,      // EXIF = 5
                .RightMirrored:     // EXIF = 7
            aTransform = CGAffineTransformTranslate(aTransform, size.height, 0);
            aTransform = CGAffineTransformScale(aTransform, -1, 1);
        default: break
        }
        
        return aTransform
    }
    
    
    /// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
    /// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
    /// If the new size is not integral, it will be rounded up
    func resizedImageWithSize(newSize:CGSize, transform:CGAffineTransform, drawTransposed:Bool, interpolationQuality:CGInterpolationQuality) -> UIImage? {
        
        guard let imageRef = self.CGImage else{
            return nil
        }
        
        let newRect = CGRectIntegral(CGRectMake(0,0,newSize.width,newSize.height))
        let transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width)
        
        // Build a context that's the same dimensions as the new size
        guard let bitmap = CGBitmapContextCreate(nil, Int(newRect.size.width), Int(newRect.size.height), CGImageGetBitsPerComponent(imageRef), 0, CGImageGetColorSpace(imageRef), CGImageGetBitmapInfo(imageRef).rawValue)
            else{
                return nil
        }
        
        // Rotate and/or flip the image if required by its orientation
        CGContextConcatCTM(bitmap, transform)
        
        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(bitmap, interpolationQuality)
        
        // Draw into the context; this scales the image
        CGContextDrawImage(bitmap, drawTransposed ? transposedRect : newRect, imageRef)
        
        // Get the resized image from the context and a UIImage
        guard let newImageRef = CGBitmapContextCreateImage(bitmap) else{
            return nil
        }
        
        let newImage = UIImage(CGImage: newImageRef)
        
        return newImage
    }
    
}
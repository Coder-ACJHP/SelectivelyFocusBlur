//
//  ViewController.swift
//  SelectiveFocusBlur
//
//  Created by Onur Işık on 10.04.2020.
//  Copyright © 2020 Onur Işık. All rights reserved.
//

import UIKit

class SelectiveFocusViewController: UIViewController {

    
    @IBOutlet weak var imageView: UIImageView!
    
    let ciContext = CIContext()
    private var imageCenter: CIVector = .init(cgPoint: .zero)
    private var originalImage: UIImage = UIImage(named: "GirlImage")!
    
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private var smallRadius: CGFloat = 0
    private var largeRadius: CGFloat = 0
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        return tapGestureRecognizer
    }()
    
    private lazy var pichGesture: UIPinchGestureRecognizer = {
        let pichGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        return pichGestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        imageView.addGestureRecognizer(pichGesture)
        
        guard let ciImage = CIImage(image: self.originalImage) else {
            print("Cannot create ciImage from original image!")
            return
        }
        
        width = ciImage.extent.width
        height = ciImage.extent.height
        
        imageCenter = CIVector(x: width / 2,
                               y: width / 2)
        
        smallRadius = min(width / 4.0, height / 4.0)
        largeRadius = min(width / 1.5, height / 1.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        if let resultImage = applyMaskedBlurFilter(smallRadius: smallRadius,
                                                   largeRadius: largeRadius,
                                                   blurPower: 15) {
        
            self.imageView.image = resultImage
        }
    }
    
    private final func applyMaskedBlurFilter(smallRadius: CGFloat, largeRadius: CGFloat, blurPower: CGFloat = 30) -> UIImage? {
        
        guard let radialMask = CIFilter(name:"CIRadialGradient") else {
            print("Cannot create Radial Gradient Filter!")
            return nil
        }
        
        guard let ciImage = CIImage(image: self.originalImage) else {
            print("Cannot create ciImage from original image!")
            return nil
        }
        
        radialMask.setValue(imageCenter, forKey:kCIInputCenterKey)
        radialMask.setValue(smallRadius, forKey:"inputRadius0")
        radialMask.setValue(largeRadius, forKey:"inputRadius1")
        radialMask.setValue(CIColor(red:0, green:1, blue:0, alpha:0), forKey:"inputColor0")
        radialMask.setValue(CIColor(red:0, green:1, blue:0, alpha:1), forKey:"inputColor1")
        
        guard let maskedVariableBlur = CIFilter(name:"CIMaskedVariableBlur") else {
            print("Cannot create Masked Variable Blur Filter!")
            return nil
        }
        
        maskedVariableBlur.setValue(ciImage, forKey: kCIInputImageKey)
        maskedVariableBlur.setValue(blurPower, forKey: kCIInputRadiusKey)
        maskedVariableBlur.setValue(radialMask.outputImage, forKey: "inputMask")
        
        guard let selectivelyFocusedCIImage = maskedVariableBlur.outputImage else {
            print("Cannot create Masked Variable Blur Filter!")
            return nil
        }
        
        guard let focusedImage = ciContext.createCGImage(selectivelyFocusedCIImage,
                                                                      from: ciImage.extent) else {
            print("Masked Variable Blur Filter result is nil!")
            return nil
        }
        
        return UIImage(cgImage: focusedImage)
    }
    
    @objc
    private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
                
        let tappedPoint: CGPoint = gestureRecognizer.location(in: imageView)
        
        let realPoint = imageView.convertPoint(fromViewPoint: tappedPoint)
        self.imageCenter = CIVector(cgPoint: CGPoint(x: realPoint.x, y: self.originalImage.size.height - realPoint.y))
        
        if let resultImage = applyMaskedBlurFilter(smallRadius: smallRadius,
                                                   largeRadius: largeRadius,
                                                   blurPower: 15) {
        
            self.imageView.image = resultImage
        }
                
    }

    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
        let scale = gestureRecognizer.scale
                
        switch gestureRecognizer.state {
        case .began, .changed:
            
            smallRadius = (width / 4.0) * scale
            largeRadius = smallRadius * 2.5
            
            print("Small radius", smallRadius)
            print("Large radius", largeRadius)
            
            
        case .ended, .cancelled:
            
            gestureRecognizer.scale = 1.0
            
            if let resultImage = applyMaskedBlurFilter(smallRadius: smallRadius,
                                                       largeRadius: largeRadius,
                                                       blurPower: 15) {

                self.imageView.image = resultImage
            }
        default: break
        }
    }
}

extension UIImageView {
    
    func convertPoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        guard let imageSize = image?.size else { return CGPoint.zero }
        
        var imagePoint = viewPoint
        let viewSize = bounds.size
        
        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height
        
        switch contentMode {
        case .scaleAspectFit: fallthrough
        case .scaleAspectFill:
            var scale : CGFloat = 0
            
            if contentMode == .scaleAspectFit {
                scale = min(ratioX, ratioY)
            }
            else {
                scale = max(ratioX, ratioY)
            }
            
            // Remove the x or y margin added in FitMode
            imagePoint.x -= (viewSize.width  - imageSize.width  * scale) / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height * scale) / 2.0
            
            imagePoint.x /= scale;
            imagePoint.y /= scale;
            
        case .scaleToFill: fallthrough
        case .redraw:
            imagePoint.x /= ratioX
            imagePoint.y /= ratioY
        case .center:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .top:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
        case .bottom:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .left:
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .right:
            imagePoint.x -= (viewSize.width - imageSize.width);
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .topRight:
            imagePoint.x -= (viewSize.width - imageSize.width);
        case .bottomLeft:
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .bottomRight:
            imagePoint.x -= (viewSize.width - imageSize.width)
            imagePoint.y -= (viewSize.height - imageSize.height)
        case.topLeft: fallthrough
        default:
            break
        }
        
        return imagePoint
    }
}


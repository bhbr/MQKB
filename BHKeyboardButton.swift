////
////  BHKeyboardButton.swift
////  MathQuillMessages
////
////  Created by Ben Hambrecht on 15.02.17.
////  Copyright © 2017 Ben Hambrecht. All rights reserved.
////
//
//
//import UIKit
//import CoreGraphics
//
//enum BHKeyboardButtonDisplayType {
//    case Label
//    case Image
//}
//
//
//
//extension UIImage {
//    
//    func inverted() -> UIImage? {
//        guard let cgImage = self.cgImage else { return nil }
//        let ciImage = CoreImage.CIImage(cgImage: cgImage)
//        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
//        filter.setDefaults()
//        filter.setValue(ciImage, forKey: kCIInputImageKey)
//        let context = CIContext(options: nil)
//        guard let outputImage = filter.outputImage else { return nil }
//        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
//        return UIImage(cgImage: outputImageCopy)
//    }
//    
//}
//
//
//class BHKeyboardButton: CYRKeyboardButton {
//    
//    
//    var _inputOptionsImages: Array<UIImage>? = []
//    var inputOptionsImages: Array<UIImage>? {
//        
//        get {
//            return _inputOptionsImages
//        }
//        
//        set(newInputOptionsImages) {
//            willChangeValue(forKey: "_inputOptionsImages")
//            _inputOptionsImages = newInputOptionsImages
//            didChangeValue(forKey: "_inputOptionsImages")
//            
//            // automatically save inverted images
//            selectedInputOptionsImages = []
//            for inputOptionImage: UIImage in newInputOptionsImages! {
//                //let idx: NSInteger = (newInputOptionsImages?.index(of: inputOptionImage))!
//                selectedInputOptionsImages?.append(inputOptionImage.inverted()!)
//            }
//        }
//    }
//    
//    var _selectedInputOptionsImages: Array<UIImage>? = []
//    var selectedInputOptionsImages: Array<UIImage>? {
//        
//        get {
//            return _selectedInputOptionsImages
//        }
//        
//        set(newSelectedInputOptionsImages) {
//            willChangeValue(forKey: "_selectedInputOptionsImages")
//            _selectedInputOptionsImages = newSelectedInputOptionsImages
//            didChangeValue(forKey: "_selectedInputOptionsImages")
//        }
//    }
//    
//    var inputImageView = UIImageView()
//    var displayType = BHKeyboardButtonDisplayType.Label
//    var rowCounts: Array<Int> = [1]
//    var delegate: BHKeyboardButtonDelegate? // KeyboardVC
//    
//    var bhButtonView: BHKeyboardButtonView?
//    
//    override var buttonView: CYRKeyboardButtonView? {
//        get {
//            return bhButtonView
//        }
//        set {
//            NSLog("Warning: bhButtonView unchanged")
//        }
//    }
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func commonInit() {
//        super.commonInit()
//        // Input image
//        let newInputImage = UIImage()
//        let newInputImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height))
//        newInputImageView.image = newInputImage
//        newInputImageView.contentMode = .center
//        newInputImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        newInputImageView.isUserInteractionEnabled = false
//        newInputImageView.backgroundColor = .clear
//
//        self.inputImageView = newInputImageView
//        self.addSubview(newInputImageView)
//        self.inputImageView.isHidden = true
//        
//        // use label by default
//        //displayType = .Label
//        
//        
//    }
//    
//    
//    
//    
//    override func handleTouchUpInside() {
//        delegate?.buttonPressed(inputIdentifier: input!)
//        super.handleTouchUpInside()
//    }
//    
//    override func draw(_ rect: CGRect) {
//        
//        switch displayType {
//        case .Label:
//            inputLabel.isHidden = false
//            inputImageView.isHidden = true
//            break
//        case .Image:
//            inputLabel.isHidden = true
//            inputImageView.isHidden = false
//            break
//        }
//        
//        super.draw(rect) // CYRKeyboardButton implementation
//    }
//    
//    
//    func setImage(_ image: UIImage?) {
//        self.inputImageView.image = image
//    }
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//}

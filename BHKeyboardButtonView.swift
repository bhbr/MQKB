////
////  BHKeyboardButtonView.swift
////  MathQuillMessages
////
////  Created by Ben Hambrecht on 15.02.17.
////  Copyright © 2017 Ben Hambrecht. All rights reserved.
////
//
//import Foundation
//import AVFoundation
//import UIKit
//
//class BHKeyboardButtonView: CYRKeyboardButtonView {
//    
//    var bhButton: BHKeyboardButton?
//    
//    override var button: CYRKeyboardButton? {
//        get {
//            return bhButton
//        }
//        set {
//            self.button = newValue
//            NSLog("Warning: bhButton unchanged")
//        }
//    }
//    
//    override init(keyboardButton newButton: CYRKeyboardButton, newType: CYRKeyboardButtonViewType) {
//        if let newBHButton = newButton as? BHKeyboardButton {
//            bhButton = newBHButton
//        } else {
//            bhButton = nil
//            NSLog("bhButton set to nil")
//        }
//        super.init(keyboardButton: newButton, newType: newType)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func drawInputView(_ rect: CGRect) {
//        
//        let context = UIGraphicsGetCurrentContext()
//        context?.setShadow(offset: CGSize.zero, blur: 0, color: UIColor.clear.cgColor)
//        context?.saveGState()
//        
//        switch (bhButton?.displayType)! {
//            
//        case .Label:
//            
//            let inputOptions = button?.inputOptions
//            for optionString: String in inputOptions! {
//                
//                let idx: NSInteger = (inputOptions?.index(of: optionString))!
//                let optionRect: CGRect = (inputOptionsRects?[idx])!
//                let selected = (idx == selectedInputIndex)
//                
//                if (selected) {
//                    // Draw selection background
//                    let roundedRectanglePath = UIBezierPath(roundedRect: optionRect, cornerRadius: 4.0)
//                    tintColor.setFill()
//                    roundedRectanglePath.fill()
//                }
//                
//                // Draw the text
//                let stringColor = (selected ? UIColor.white : button?.keyTextColor)
//                let stringSize = optionString.size(attributes: [NSFontAttributeName: (button?.inputOptionsFont)!])
//                let stringRect = CGRect(x: optionRect.midX - stringSize.width * 0.5, y: optionRect.midY - stringSize.height * 0.5, width: stringSize.width, height: stringSize.height)
//                let p = NSMutableParagraphStyle()
//                p.alignment = NSTextAlignment.center
//                let attributedString = NSAttributedString.init(string: optionString, attributes: [NSFontAttributeName: (button?.inputOptionsFont)!, NSForegroundColorAttributeName: stringColor!, NSParagraphStyleAttributeName: p])
//                attributedString.draw(in: stringRect)
//                
//            }
//            
//        case .Image:
//            
//            let inputOptionsImages = bhButton?.inputOptionsImages
//            for optionImage: UIImage in inputOptionsImages! {
//                
//                let idx: NSInteger = (inputOptionsImages?.index(of: optionImage))!
//                let optionRect: CGRect = (inputOptionsRects?[idx])!
//                let selectedOptionImage: UIImage = (bhButton?.selectedInputOptionsImages?[idx])!
//                let selected = (idx == selectedInputIndex)
//                let aspectRatioPreservingRect = AVMakeRect(aspectRatio: selectedOptionImage.size, insideRect: optionRect)
//                
//                if (selected) {
//                    // Draw selection background
//                    let roundedRectanglePath = UIBezierPath(roundedRect: optionRect, cornerRadius: 4.0)
//                    tintColor.setFill()
//                    roundedRectanglePath.fill()
//                    selectedOptionImage.draw(in: aspectRatioPreservingRect)
//                } else {
//                    optionImage.draw(in: aspectRatioPreservingRect)
//                }
//                
//            }
//            
//        }
//        
//        
//        
//        context?.restoreGState()
//    }
//    
//    
//    override func drawExpandedInputViewOptions() {
//        
//        let context = UIGraphicsGetCurrentContext()
//        context?.setShadow(offset: CGSize.zero, blur: 0, color: UIColor.clear.cgColor)
//        context?.saveGState()
//        
//        switch (bhButton?.displayType)! {
//            
//        case .Label:
//            
//            let inputOptions = button?.inputOptions
//            for optionString: String in inputOptions! {
//                
//                let idx: NSInteger = (inputOptions?.index(of: optionString))!
//                let optionRect: CGRect = (inputOptionsRects?[idx])!
//                let selected = (idx == selectedInputIndex)
//                
//                if (selected) {
//                    // Draw selection background
//                    let roundedRectanglePath = UIBezierPath(roundedRect: optionRect, cornerRadius: 4.0)
//                    tintColor.setFill()
//                    roundedRectanglePath.fill()
//                }
//                
//                // Draw the text
//                let stringColor = (selected ? UIColor.white : button?.keyTextColor)
//                let stringSize = optionString.size(attributes: [NSFontAttributeName: (button?.inputOptionsFont)!])
//                let stringRect = CGRect(x: optionRect.midX - stringSize.width * 0.5, y: optionRect.midY - stringSize.height * 0.5, width: stringSize.width, height: stringSize.height)
//                let p = NSMutableParagraphStyle()
//                p.alignment = NSTextAlignment.center
//                let attributedString = NSAttributedString.init(string: optionString, attributes: [NSFontAttributeName: (button?.inputOptionsFont)!, NSForegroundColorAttributeName: stringColor!, NSParagraphStyleAttributeName: p])
//                attributedString.draw(in: stringRect)
//                
//            }
//            
//        case .Image:
//            
//            let inputOptionsImages = bhButton?.inputOptionsImages
//            for optionImage: UIImage in inputOptionsImages! {
//                
//                let idx: NSInteger = (inputOptionsImages?.index(of: optionImage))!
//                let optionRect: CGRect = (inputOptionsRects?[idx])!
//                let selectedOptionImage: UIImage = (bhButton?.selectedInputOptionsImages?[idx])!
//                let selected = (idx == selectedInputIndex)
//                let aspectRatioPreservingRect = AVMakeRect(aspectRatio: selectedOptionImage.size, insideRect: optionRect)
//                
//                if (selected) {
//                    // Draw selection background
//                    let roundedRectanglePath = UIBezierPath(roundedRect: optionRect, cornerRadius: 4.0)
//                    tintColor.setFill()
//                    roundedRectanglePath.fill()
//                    selectedOptionImage.draw(in: aspectRatioPreservingRect)
//                } else {
//                    optionImage.draw(in: aspectRatioPreservingRect)
//                }
//                
//            }
//            
//        }
//        
//        
//        
//        context?.restoreGState()
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
//}

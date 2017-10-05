//
//  KeyboardViewController.swift
//  MathQuillKeyboard
//
//  Created by Ben Hambrecht on 28.11.16.
//  Copyright © 2016 Ben Hambrecht. All rights reserved.
//

import UIKit
import WebKit
import CoreGraphics

let SPECIAL_BUTTON_BG_COLOR: UIColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
let SPECIAL_BUTTON_HIGHLIGHT_BG_COLOR: UIColor = .white
let ARROW_BUTTON_BG_COLOR: UIColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
let COPY_BUTTON_COLOR: UIColor = UIColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1.0)
let IMAGE_PADDING : CGFloat = 50


// MARK: UIImage


extension UIImage {
    
    func padToSquare() -> UIImage {
        
        let sideLength = (size.width > size.height) ? size.width : size.height
        let newWidth = sideLength + 2 * IMAGE_PADDING
        let newHeight = sideLength + 2 * IMAGE_PADDING
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, scale)
        _ = UIGraphicsGetCurrentContext()
        
        // Now we can draw anything we want into this new context.
        let origin = CGPoint(x: (newWidth - size.width) / 2.0,
                             y: (newHeight - size.height) / 2.0)
        draw(at: origin)
        
        // Clean up and get the new image.
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    
    func trim() -> UIImage {
        let newRect = self.cropRect
        if let imageRef = self.cgImage!.cropping(to: newRect) {
            return UIImage(cgImage: imageRef)
        }
        return self
    }
    
    var cropRect: CGRect {
        let cgImage = self.cgImage
        let context = createARGBBitmapContextFromImage(inImage: cgImage!)
        if context == nil {
            return CGRect.zero
        }
        
        let height = CGFloat(cgImage!.height)
        let width = CGFloat(cgImage!.width)
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context?.draw(cgImage!, in: rect)
        
        guard let data = context?.data?.assumingMemoryBound(to: UInt8.self) else {
            return CGRect.zero
        }
        
        var lowX = width
        var lowY = height
        var highX: CGFloat = 0
        var highY: CGFloat = 0
        
        let heightInt = Int(height)
        let widthInt = Int(width)
        print("height: \(height)")
        print("width: \(width)")
        
        //Filter through data and look for non-transparent pixels.
        for y in (0 ..< heightInt) {
            let y = CGFloat(y)
            for x in (0 ..< widthInt) {
                let x = CGFloat(x)
                let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */
                
                let alpha =  data[Int(pixelIndex)]
                let red =  data[Int(pixelIndex + 1)]
                let green = data[Int(pixelIndex) + 2]
                let blue =  data[Int(pixelIndex + 3)]
                
                if (alpha != 255 && red != 255 && green != 255 && blue != 255) {
                    print("(\(x),\(y)) -> (\(alpha),\(red),\(green),\(blue))")
                }
                
                if data[Int(pixelIndex)] == 0  {
                    continue
                } // crop transparent
                
                
                if data[Int(pixelIndex+1)] > 0xE0 && data[Int(pixelIndex+2)] > 0xE0 && data[Int(pixelIndex+3)] > 0xE0 {
                    continue
                } // crop white
                
                
                if (x < lowX) {
                    lowX = x
                }
                if (x > highX) {
                    highX = x
                }
                if (y < lowY) {
                    lowY = y
                }
                if (y > highY) {
                    highY = y
                }
            }
        }
        
        // lowY -= 200
        // highY += 200
        print(lowX)
        print(highX)
        print(lowY)
        print(highY)
        
        let padding: CGFloat = 5.0
        
        //return CGRect(x: 0, y: 0, width: CGFloat(widthInt), height: highY + lowY)
        return CGRect(x: lowX - padding, y: lowY - padding, width: highX - lowX + 2.0 * padding, height: highY - lowY + 2.0 * padding)
    }
    
    func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {
        
        let width = inImage.width
        let height = inImage.height
        
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        
        let context = CGContext (data: bitmapData,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,      // bits per component
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        return context
    }
    
    convenience init?(imageName: String) {
        self.init(named: imageName)!
        accessibilityIdentifier = imageName
    }
    
    // http://stackoverflow.com/a/40177870/4488252
    func imageWithColor(newColor: UIColor?) -> UIImage? {
        
        if let newColor = newColor {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            
            let context = UIGraphicsGetCurrentContext()!
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.setBlendMode(.normal)
            
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context.clip(to: rect, mask: cgImage!)
            
            newColor.setFill()
            context.fill(rect)
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            newImage.accessibilityIdentifier = accessibilityIdentifier
            return newImage
        }
        
        if let accessibilityIdentifier = accessibilityIdentifier {
            return UIImage(imageName: accessibilityIdentifier)
        }
        
        return self
    }
    
    func inverted() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setDefaults()
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else { return nil }
        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: outputImageCopy)
    }

    
}


// MARK: KeyboardViewController

class KeyboardViewController: UIInputViewController, UITextViewDelegate, MFKBDelegate {
    
    var nextKeyboardButton: UIButton!
    
    @IBOutlet var containerView : UIView!
    var formulaWebView: WKWebView?
    var myView : UIView!
    var myTextView: UITextView!
    
    var bracketTracker: [String] = []
    
// MARK: - Button Declarations
    
    
    
    var buttonNext: MuFuKeyboardButton = MuFuKeyboardButton()
    

    // upper row
    
    var buttonDot: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonOps: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonOpsShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonOpen: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonClose: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonBlackboard: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonSets: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonSetsShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonUp: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonDelete: MuFuKeyboardButton = MuFuKeyboardButton()

    // middle row

    var buttonDigit: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonEquals: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonEqualsShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonSqrt: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonFrac: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonArrows: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonDoubleArrows: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonLogGeom: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonLogGeomShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonLeft: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonDown: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonRight: MuFuKeyboardButton = MuFuKeyboardButton()

    // lower row

    var buttonLower: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonUpper: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonLowerGreek: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonUpperGreek: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonLowerRoman: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonUpperRoman: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonExponent: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonSubScript: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonOver: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonCalc: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonCalcShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonTrig: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonTrigShift: MuFuKeyboardButton = MuFuKeyboardButton()
    var buttonCopy: MuFuKeyboardButton = MuFuKeyboardButton()
    

    
    // MARK: Rest
    
    var shiftToggle = false
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // load the nib file
        let MQKBNib = UINib(nibName: "MQKBView", bundle: nil)
        // instantiate the view
        view = MQKBNib.instantiate(withOwner: self,options: nil)[0] as! UIView
        
        formulaWebView = WKWebView()
        formulaWebView?.contentScaleFactor = 1.0
        formulaWebView?.backgroundColor = .clear //UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)
        
        containerView.addSubview(formulaWebView!)
        formulaWebView?.frame.size = containerView.frame.size
        formulaWebView?.frame.origin = CGPoint(x: 0, y: 0)
        containerView?.layer.borderWidth = 1.0
        containerView?.layer.borderColor = UIColor.black.cgColor
        
        //containerView.clipsToBounds = false
        //formulaWebView?.clipsToBounds = false
        //formulaWebView?.scrollView.clipsToBounds = false
        
        let localfilePath = Bundle.main.url(forResource: "test", withExtension: "html")
        let myRequest = URLRequest(url: localfilePath!)
        _ = formulaWebView?.load(myRequest)
        
        view.setNeedsDisplay()
        
        myTextView = UITextView()
        myTextView.delegate = self
        
        
        
        
        // dummy default values
        
        let buttonXOffset: CGFloat = 5.0
        let buttonYOffset: CGFloat = 80.0
        
        let xGap: CGFloat = 3.0
        let yGap: CGFloat = 3.0
        
        let buttonWidth: CGFloat = buttonNext.frame.size.width + xGap
        let buttonHeight: CGFloat = buttonNext.frame.size.height + yGap
        
        /////////////////
        // NEXT BUTTON //
        /////////////////
        
        
        buttonNext = MuFuKeyboardButton(x: buttonXOffset, y: 10.0, style: .Phone)
        buttonNext.position = .Inner
        buttonNext.frame.size.width = 33.0
        buttonNext.inputID = "Next"
        //buttonNext.displayLabel.text = "🌐"
        buttonNext.displayType = .Image
        buttonNext.displayImageView.image = UIImage(named: "next")!
        buttonNext.displayImageView.frame.size.height = 0.6 * buttonNext.frame.size.height
        buttonNext.displayImageView.contentMode = .scaleAspectFit
        buttonNext.displayImageView.center.x = 0.5 * buttonNext.frame.size.width
        buttonNext.displayImageView.center.y = 0.5 * buttonNext.frame.size.height
        buttonNext.showMagnifier = false
        buttonNext.keyColor = SPECIAL_BUTTON_BG_COLOR
        //buttonNext.displayType = .Label
        buttonNext.delegate = self
        view.addSubview(buttonNext)

        buttonNext.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        

        
 // MARK: - Upper Row
        
        
        buttonDot = MuFuKeyboardButton(x: buttonXOffset, y: buttonYOffset, style: .Phone)
        buttonDot.position = .Inner
        buttonDot.inputID = "."
        buttonDot.inputOptionsIDs = [".", ",", "'", "…", ":", ";", "!"]
        buttonDot.inputOptionsGlyphs = [".", ",", "'", "…", ":", ";", "!"]
        
        //buttonDot.optionsRowLengths = [4, 3]
        //buttonDot.optionsRowOffsets = [0.0, 0.5]
        buttonDot.displayType = .Label
        buttonDot.delegate = self
        
        
        
        

        
        buttonOps = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOps.position = .Inner
        buttonOps.inputID = "+"
        buttonOps.inputOptionsIDs = ["+", "–", "×", "·", "/", ":", "%"]
        buttonOps.inputOptionsGlyphs = ["+", "–", "×", "·", "/", ":", "%"]
        //buttonOps.optionsRowLengths = [4, 3]
        //buttonOps.optionsRowOffsets = [0.0, 0.5]
        buttonOps.displayType = .Label
        buttonOps.delegate = self


        buttonOpsShift = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOpsShift.position = .Inner
        buttonOpsShift.inputID = "±"
        buttonOpsShift.inputOptionsIDs = ["±", "∓","∗", "·", "÷", "∘", "°"]
        buttonOpsShift.inputOptionsGlyphs = ["±", "∓","∗", "·", "÷", "∘", "°"]
        //buttonOpsShift.optionsRowLengths = [4, 3]
        //buttonOpsShift.optionsRowOffsets = [0.0, 0.5]
        buttonOpsShift.displayType = .Label
        buttonOpsShift.delegate = self



        buttonOpen = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOpen.position = .Inner
        buttonOpen.inputID = "("
        buttonOpen.inputOptionsIDs = ["(", "[", "{", "〈", "⎣", "lvert"]
        buttonOpen.inputOptionsGlyphs = ["(", "[", "{", "〈", "⎣", "|"]
        buttonOpen.displayLabel.text = "("
        buttonOpen.displayType = .Label
        buttonOpen.delegate = self



        buttonClose = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonClose.position = .Inner
        buttonClose.inputID = ")"
        buttonClose.inputOptionsIDs = [")", "]", "}", "〉", "⎦", "rvert"]
        buttonClose.inputOptionsGlyphs = [")", "]", "}", "〉", "⎦", "|"]
        buttonClose.displayLabel.text = ")"
        buttonClose.displayType = .Label
        buttonClose.delegate = self




        
        



        
        buttonSqrt = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonSqrt.position = .Inner
        buttonSqrt.inputID = "sqrt"
        let sqrtImage = UIImage(named: "sqrt")!
        let csqrtImage = UIImage(named: "csqrt")!
        let nsqrtImage = UIImage(named: "nsqrt")!
        buttonSqrt.displayImageView.image = sqrtImage
        buttonSqrt.magnifiedDisplayImageView.image = sqrtImage
        buttonSqrt.inputOptionsIDs = ["sqrt", "csqrt", "nsqrt"]
        buttonSqrt.inputOptionsImages = [sqrtImage, csqrtImage, nsqrtImage]
        buttonSqrt.displayType = .Image
        buttonSqrt.labelIsPersistent = false
        buttonSqrt.delegate = self
        
        
        
        
        buttonFrac = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonFrac.position = .Inner
        buttonFrac.inputID = "frac"
        let fracImage = UIImage(named: "frac")
        let binomImage = UIImage(named: "frac")
        buttonFrac.displayImageView.image = fracImage
        buttonFrac.inputOptionsIDs = ["frac", "binom"]
        buttonFrac.inputOptionsImages = [fracImage!, binomImage!]
        buttonFrac.displayType = .Image
        buttonSqrt.labelIsPersistent = false
        buttonFrac.delegate = self


        buttonShift = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonShift.position = .Inner
        //buttonShift.frame.size.width = 60.0
        buttonShift.inputID = "Shift"
        buttonShift.displayLabel.text = "⇧"
        buttonShift.showMagnifier = false
        buttonShift.keyColor = SPECIAL_BUTTON_BG_COLOR
        //buttonShift.keyHighlightedColor = SPECIAL_BUTTON_HIGHLIGHT_BG_COLOR
            // highlighting is for iPad only (darker color instead of magnifier)
        buttonShift.displayType = .Label
        buttonShift.delegate = self


        buttonUp = MuFuKeyboardButton(x: buttonXOffset + 7.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonUp.position = .Inner
        buttonUp.inputID = "Up"
        buttonUp.displayLabel.text = "↑"
        buttonUp.keyColor = ARROW_BUTTON_BG_COLOR
        buttonUp.keyTextColor = .white
        buttonUp.displayType = .Label
        buttonUp.delegate = self



        buttonDelete = MuFuKeyboardButton(x: buttonXOffset + 8.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        //buttonDelete.frame.size.width = 40.0
        buttonDelete.position = .Inner
        buttonDelete.inputID = "Delete"
        buttonDelete.displayImageView.image = UIImage(named:"backspace")
        buttonNext.displayImageView.contentMode = .scaleAspectFit
        buttonNext.displayImageView.center.x = 0.5 * buttonNext.frame.size.width
        buttonNext.displayImageView.center.y = 0.5 * buttonNext.frame.size.height
        buttonDelete.showMagnifier = false
        buttonDelete.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonDelete.displayType = .Image
        buttonDelete.delegate = self





















// MARK: Middle Row


        buttonDigit = MuFuKeyboardButton(x: buttonXOffset, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonDigit.position = .Left
        buttonDigit.inputID = "123"
        buttonDigit.inputOptionsIDs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        buttonDigit.inputOptionsGlyphs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        buttonDigit.optionsRowLengths = [5, 5]
        buttonDigit.optionsRowOffsets = [0.0, 0.0]
        buttonDigit.displayType = .Label
        buttonDigit.font? = .systemFont(ofSize: 14.0)
        buttonDigit.showMagnifier = false
        buttonDigit.optionsViewDelay = 0.0
        buttonDigit.delegate = self



        buttonEquals = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonEquals.position = .Inner
        buttonEquals.inputID = "="
        buttonEquals.inputOptionsIDs = ["=", "<", ">", "∼", "≃", "≡", "∝"]
        buttonEquals.inputOptionsGlyphs = ["=", "<", ">", "∼", "≃", "≡", "∝"]
        buttonEquals.labelIsPersistent = false
        buttonEquals.displayType = .Label
        buttonEquals.delegate = self



        buttonEqualsShift = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonEqualsShift.position = .Inner
        buttonEqualsShift.inputID = "≠"
        buttonEqualsShift.inputOptionsIDs = ["≠", "≤", "≥", "≪", "≫", "≢"]
        buttonEqualsShift.inputOptionsGlyphs = ["≠", "≤", "≥", "≪", "≫", "≢"]
        buttonEqualsShift.labelIsPersistent = false
        buttonEqualsShift.displayType = .Label
        buttonEqualsShift.delegate = self




        buttonBlackboard = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonBlackboard.position = .Inner
        buttonBlackboard.inputID = "ℕ"
        buttonBlackboard.inputOptionsIDs = ["ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ"]
        buttonBlackboard.inputOptionsGlyphs = ["ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ"]
        buttonBlackboard.optionsRowLengths = [4, 4]
        buttonBlackboard.optionsRowOffsets = [0.0, 0.0]
        buttonBlackboard.displayType = .Label
        //buttonBlackboard.font? = .systemFont(ofSize: 14.0)
        buttonBlackboard.showMagnifier = false
        buttonBlackboard.optionsViewDelay = 0.0
        buttonBlackboard.delegate = self


        
        buttonSets = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonSets.position = .Inner
        buttonSets.inputID = "∈"
        buttonSets.inputOptionsIDs = ["∈", "∅", "∪", "∩", "setminus", "mid", "⊂", "⊃"]
        buttonSets.inputOptionsGlyphs = ["∈", "∅", "∪", "∩", "\\", "|", "⊂", "⊃"]
        buttonSets.optionsRowLengths = [4, 4]
        buttonSets.optionsRowOffsets = [0.0, 0.0]
        buttonSets.displayType = .Label
        buttonSets.displayLabel.text = "∈"
        buttonSets.delegate = self
        
        
        buttonSetsShift = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonSetsShift.position = .Inner
        buttonSetsShift.inputID = "∉"
        buttonSetsShift.inputOptionsIDs = ["∉", "⊆", "⊇"]
        buttonSetsShift.inputOptionsGlyphs = ["∉", "⊆", "⊇"]
        buttonSetsShift.displayType = .Label
        buttonSetsShift.displayLabel.text = "∉"
        buttonSetsShift.delegate = self


        buttonArrows = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonArrows.position = .Inner
        buttonArrows.inputID = "→"
        buttonArrows.inputOptionsIDs = ["↔︎", "↑", "↦", "←", "↓", "→"]
        buttonArrows.inputOptionsGlyphs = ["↔︎", "↑", "↦", "←", "↓", "→"]
        buttonArrows.displayType = .Label
        buttonArrows.optionsRowLengths = [3, 3]
        buttonArrows.optionsRowOffsets = [0.0, 0.0]
        buttonArrows.displayLabel.text = "→"
        buttonArrows.labelIsPersistent = false
        buttonArrows.delegate = self


        buttonDoubleArrows = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonDoubleArrows.position = .Inner
        buttonDoubleArrows.inputID = "⇒"
        buttonDoubleArrows.inputOptionsIDs = ["⇔", "⇑", "↪", "⇐", "⇓", "⇒"]
        buttonDoubleArrows.inputOptionsGlyphs = ["⇔", "⇑", "\u{21aa}\u{fe0e}", "⇐", "⇓", "⇒"]
        buttonDoubleArrows.displayType = .Label
        buttonDoubleArrows.optionsRowLengths = [3, 3]
        buttonDoubleArrows.optionsRowOffsets = [0.0, 0.0]
        buttonDoubleArrows.displayLabel.text = "⇒"
        buttonDoubleArrows.labelIsPersistent = false
        buttonDoubleArrows.delegate = self




        buttonLogGeom = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonLogGeom.position = .Inner
        buttonLogGeom.inputID = "∃"
        buttonLogGeom.inputOptionsIDs = ["∃", "∀", "∧", "∨", "⊥", "∠", "|", "∥"]
        buttonLogGeom.inputOptionsGlyphs = ["∃", "∀", "∧", "∨", "⊥", "∠", "|", "∥"]
        buttonLogGeom.optionsRowLengths = [4, 4]
        buttonLogGeom.optionsRowOffsets = [0.0, 0.0]
        buttonLogGeom.displayType = .Label
        buttonLogGeom.displayLabel.text = "∃"
        buttonLogGeom.labelIsPersistent = false
        buttonLogGeom.delegate = self



        buttonLogGeomShift = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonLogGeomShift.position = .Inner
        buttonLogGeomShift.inputID = "∄"
        buttonLogGeomShift.inputOptionsIDs = ["∄", "¬", "∡", "∤", "∦"]
        buttonLogGeomShift.inputOptionsGlyphs = ["∄", "¬", "∡", "∤", "∦"]
        buttonLogGeomShift.displayType = .Label
        buttonLogGeomShift.displayLabel.text = "∄"
        buttonLogGeomShift.labelIsPersistent = false
        buttonLogGeomShift.delegate = self





        buttonLeft = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonLeft.position = .Inner
        buttonLeft.inputID = "Left"
        buttonLeft.displayLabel.text = "←"
        buttonLeft.keyColor = ARROW_BUTTON_BG_COLOR
        buttonLeft.keyTextColor = .white
        buttonLeft.displayType = .Label
        buttonLeft.delegate = self

        buttonDown = MuFuKeyboardButton(x: buttonXOffset + 7.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonDown.position = .Inner
        buttonDown.inputID = "Down"
        buttonDown.displayLabel.text = "↓"
        buttonDown.keyColor = ARROW_BUTTON_BG_COLOR
        buttonDown.keyTextColor = .white
        buttonDown.displayType = .Label
        buttonDown.delegate = self

        buttonRight = MuFuKeyboardButton(x: buttonXOffset + 8.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonRight.position = .Inner
        buttonRight.inputID = "Right"
        buttonRight.displayLabel.text = "→"
        buttonRight.keyColor = ARROW_BUTTON_BG_COLOR
        buttonRight.keyTextColor = .white
        buttonRight.displayType = .Label
        buttonRight.delegate = self















    // MARK: Lower Row


        buttonLower = MuFuKeyboardButton(x: buttonXOffset, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonLower.position = .Right
        buttonLower.inputID = "x"
        buttonLower.inputOptionsIDs = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"]
        buttonLower.inputOptionsGlyphs = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"]
        buttonLower.inputOptionsFont = UIFont.italicSystemFont(ofSize: 22.0)
        buttonLower.optionsRowLengths = [10, 9, 7]
        buttonLower.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonLower.displayLabel.text = "x"
        buttonLower.displayLabel.font = UIFont.italicSystemFont(ofSize: 22.0)
        buttonLower.displayType = .Label
        buttonLower.delegate = self



        buttonUpper = MuFuKeyboardButton(x: buttonXOffset, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonUpper.position = .Right
        buttonUpper.inputID = "X"
        buttonUpper.inputOptionsIDs = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M"]
        buttonUpper.inputOptionsGlyphs = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M"]
        buttonUpper.inputOptionsFont = UIFont.italicSystemFont(ofSize: 22.0)
        buttonUpper.optionsRowLengths = [10, 9, 7]
        buttonUpper.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonUpper.displayLabel.text = "X"
        buttonUpper.displayLabel.font = UIFont.italicSystemFont(ofSize: 22.0)
        buttonUpper.displayType = .Label
        buttonUpper.delegate = self



        buttonLowerGreek = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonLowerGreek.position = .Right
        buttonLowerGreek.inputID = "\\alpha"
        buttonLowerGreek.inputOptionsIDs = ["\\alpha", "\\beta", "\\gamma", "\\delta", "\\epsilon", "\\zeta", "\\eta", "\\theta", "\\iota", "\\kappa", "\\lambda", "\\mu", "\\nu", "\\xi", "\\omicron", "\\pi", "\\rho", "\\sigma", "\\varsigma", "\\tau", "\\upsilon", "\\phi", "\\varphi", "\\chi", "\\psi", "\\omega"]
        buttonLowerGreek.inputOptionsGlyphs = ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ", "ν", "ξ", "ο", "π", "ρ", "σ", "ς", "τ", "υ", "ϕ", "φ", "χ", "ψ", "ω"]
        buttonLowerGreek.inputOptionsFont = UIFont.italicSystemFont(ofSize: 22.0)
        buttonLowerGreek.optionsRowLengths = [9, 8, 9]
        buttonLowerGreek.optionsRowOffsets = [0.0, 10.0, 0.0]
        //buttonLowerGreek.optionsRectWidth = 18.0
        buttonLowerGreek.displayLabel.text = "α"
        buttonLowerGreek.displayLabel.font = UIFont.italicSystemFont(ofSize: 22.0)
        buttonLowerGreek.displayType = .Label
        buttonLowerGreek.delegate = self



        buttonUpperGreek = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonUpperGreek.position = .Right
        buttonUpperGreek.inputID = "\\Gamma"
        buttonUpperGreek.inputOptionsIDs = ["\\Gamma", "\\Delta", "\\Theta", "\\Lambda", "\\Xi", "\\Pi", "\\Sigma", "\\Upsilon", "\\Phi", "\\Psi", "\\Omega"]
        buttonUpperGreek.inputOptionsGlyphs = ["Γ", "Δ", "Θ", "Λ", "Ξ", "Π", "Σ", "Υ", "Φ", "Ψ", "Ω"]
        buttonUpperGreek.inputOptionsFont = UIFont.systemFont(ofSize: 22.0)
        buttonUpperGreek.optionsRowLengths = [4,3,4]
        buttonUpperGreek.optionsRowOffsets = [0.0, 10.0, 0.0]
        buttonUpperGreek.displayLabel.text = "Γ"
        buttonUpperGreek.displayLabel.font = UIFont.systemFont(ofSize: 22.0)
        buttonUpperGreek.displayType = .Label
        buttonUpperGreek.delegate = self





        buttonLowerRoman = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonLowerRoman.position = .Right
        buttonLowerRoman.inputID = "x"
        buttonLowerRoman.inputOptionsIDs = ["romanq", "romanw", "romane", "romanr", "romant", "romany", "romanu", "romani", "romano", "romanp", "romana", "romans", "romand", "romanf", "romang", "romanh", "romanj", "romank", "romanl", "romanz", "romanx", "romanc", "romanv", "romanb", "romann", "romanm"]
        buttonLowerRoman.inputOptionsGlyphs = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"]
        buttonLowerRoman.optionsRowLengths = [10, 9, 7]
        buttonLowerRoman.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonLowerRoman.displayLabel.text = "abc"
        buttonLowerRoman.displayLabel.font? = .systemFont(ofSize: 14.0)
        buttonLowerRoman.displayType = .Label
        buttonLowerRoman.delegate = self




        buttonUpperRoman = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonUpperRoman.position = .Right
        buttonUpperRoman.inputID = "X"
        buttonUpperRoman.inputOptionsIDs = ["romanQ", "romanW", "romanE", "romanR", "romanT", "romanY", "romanU", "romanI", "romanO", "\romanP", "romanA", "romanS", "romanD", "romanF", "romanG", "romanH", "romanJ", "romanK", "\romanL", "romanZ", "romanX", "romanC", "romanV", "romanB", "romanN", "romanM"]
        buttonUpperRoman.inputOptionsGlyphs = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M"]
        buttonUpperRoman.optionsRowLengths = [10, 9, 7]
        buttonUpperRoman.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonUpperRoman.displayLabel.text = "ABC"
        buttonUpperRoman.displayLabel.font? = .systemFont(ofSize: 12.0)
        buttonUpperRoman.displayType = .Label
        buttonUpperRoman.delegate = self







        buttonExponent = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonExponent.position = .Inner
        buttonExponent.inputID = "^"
        buttonExponent.inputOptionsIDs = ["^", "^2", "^3", "^-1", "^_"]
        buttonExponent.displayImageView.image = UIImage(named:"exponent")
        buttonExponent.inputOptionsImages = [UIImage(named:"exponent")!, UIImage(named:"exponent2")!, UIImage(named:"exponent3")!, UIImage(named:"exponent-1")!, UIImage(named:"subsup")!]
        buttonExponent.displayType = .Image
        buttonExponent.labelIsPersistent = false
        buttonExponent.delegate = self


        buttonSubScript = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonSubScript.position = .Inner
        buttonSubScript.inputID = "_"
        buttonSubScript.inputOptionsIDs = ["_", "_0", "_1", "_2", "^_"]
        buttonSubScript.displayImageView.image = UIImage(named:"sub")
        buttonSubScript.inputOptionsImages = [UIImage(named:"sub")!, UIImage(named:"sub0")!, UIImage(named:"sub1")!, UIImage(named:"sub2")!, UIImage(named:"subsup")!]
        buttonSubScript.displayType = .Image
        buttonSubScript.labelIsPersistent = false
        buttonSubScript.delegate = self


        buttonOver = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonOver.position = .Inner
        buttonOver.inputID = "overline"
        buttonOver.inputOptionsIDs = ["overline", "vec", "underline"]
        buttonOver.inputOptionsImages = [UIImage(named:"overline")!, UIImage(named:"vec")!, UIImage(named:"underline")!]
        buttonOver.displayType = .Image
        buttonOver.displayImageView.image = UIImage(named:"overline")!
        buttonOver.labelIsPersistent = false
        buttonOver.delegate = self








        buttonCalc = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCalc.position = .Inner
        buttonCalc.inputID = "∫"
        buttonCalc.inputOptionsIDs = ["∫", "∫ ̻", "∬", "∮", "∂", "∇", "sum", "prod", "∞"]
        buttonCalc.inputOptionsGlyphs = ["∫", "∫ ̻", "∬", "∮", "∂", "∇", "Σ", "Π", "∞"]
        buttonCalc.optionsRowLengths = [4, 5]
        buttonCalc.optionsRowOffsets = [0.5, 0.0]
        buttonCalc.displayType = .Label
        buttonCalc.displayLabel.text = "∫"
        buttonCalc.delegate = self
        buttonCalc.magnifiedDisplayLabelFont = .systemFont(ofSize: 30.0)



        buttonCalcShift = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCalcShift.position = .Inner
        buttonCalcShift.inputID = "⊕"
        buttonCalcShift.inputOptionsIDs = ["⊕", "⊗", "⊙", "⨿", "†", "ℏ"]
        buttonCalcShift.inputOptionsGlyphs = ["⊕", "⊗", "⊙", "⨿", "†", "ℏ"]
        buttonCalcShift.displayType = .Label
        buttonCalcShift.displayLabel.text = "⊕"
        buttonCalcShift.delegate = self





        buttonTrig = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonTrig.position = .Inner
        buttonTrig.inputID = "sin"
        buttonTrig.inputOptionsIDs = ["sin", "cos", "tan", "exp", "log"]
        buttonTrig.inputOptionsGlyphs = ["sin", "cos", "tan", "exp", "log"]
        buttonTrig.displayType = .Label
        buttonTrig.displayLabel.text = "sin"
        buttonTrig.displayLabel.font? = .systemFont(ofSize: 22.0)
        buttonTrig.inputOptionsFont = .systemFont(ofSize: 22.0)
        buttonTrig.magnifiedDisplayLabelFont = .systemFont(ofSize: 24.0)
        buttonTrig.delegate = self








        buttonCopy = MuFuKeyboardButton(x: buttonXOffset + 7.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCopy.frame.size.width = 2.0 * buttonWidth - xGap
        buttonCopy.position = .Inner
        buttonCopy.inputID = "Copy"
        buttonCopy.displayType = .Image
        buttonCopy.displayImageView.image = UIImage(named: "copy")!
        buttonCopy.displayImageView.frame.size.height = 0.75 * buttonNext.frame.size.height
        buttonCopy.displayImageView.contentMode = .scaleAspectFit
        buttonCopy.displayImageView.center.x = 0.5 * buttonCopy.frame.size.width
        buttonCopy.displayImageView.center.y = 0.5 * buttonCopy.frame.size.height
        buttonCopy.showMagnifier = false
        buttonCopy.keyColor = COPY_BUTTON_COLOR
        buttonCopy.displayLabel.textColor = .white
        //buttonCopy.displayType = .Label
        buttonCopy.delegate = self
        
        
        
        
        
        
        
        
        
        view.addSubview(buttonDot)
        view.addSubview(buttonBlackboard)
        view.addSubview(buttonOpen)
        view.addSubview(buttonClose)
        view.addSubview(buttonShift)
        view.addSubview(buttonUp)
        view.addSubview(buttonDelete)


        view.addSubview(buttonDigit)
        view.addSubview(buttonSqrt)
        view.addSubview(buttonFrac)
        view.addSubview(buttonLeft)
        view.addSubview(buttonDown)
        view.addSubview(buttonRight)


        view.addSubview(buttonOver)
        view.addSubview(buttonCopy)
        
        

        
        // adding buttons depending on shift
        toggleButtons()
        
        
    }
    
    
    func toggleButtons() {
        
        
        if shiftToggle {
            
            buttonShift.keyColor = SPECIAL_BUTTON_HIGHLIGHT_BG_COLOR
            buttonShift.displayLabel.text = "⬆︎"
            buttonShift.setNeedsDisplay()
            
            view.willRemoveSubview(buttonOps)
            view.willRemoveSubview(buttonSets)
            view.willRemoveSubview(buttonEquals)
            view.willRemoveSubview(buttonArrows)
            view.willRemoveSubview(buttonLogGeom)
            view.willRemoveSubview(buttonLower)
            view.willRemoveSubview(buttonLowerGreek)
            view.willRemoveSubview(buttonLowerRoman)
            view.willRemoveSubview(buttonExponent)
            view.willRemoveSubview(buttonCalc)
            view.willRemoveSubview(buttonTrig)

            view.addSubview(buttonOpsShift)
            view.addSubview(buttonSetsShift)
            view.addSubview(buttonEqualsShift)
            view.addSubview(buttonDoubleArrows)
            view.addSubview(buttonLogGeomShift)
            view.addSubview(buttonUpper)
            view.addSubview(buttonUpperGreek)
            view.addSubview(buttonUpperRoman)
            view.addSubview(buttonSubScript)
            view.addSubview(buttonCalcShift)
            
        } else {
            
            buttonShift.keyColor = SPECIAL_BUTTON_BG_COLOR
            buttonShift.displayLabel.text = "⇧"
            
            view.willRemoveSubview(buttonOpsShift)
            view.willRemoveSubview(buttonSetsShift)
            view.willRemoveSubview(buttonEqualsShift)
            view.willRemoveSubview(buttonDoubleArrows)
            view.willRemoveSubview(buttonLogGeomShift)
            view.willRemoveSubview(buttonUpper)
            view.willRemoveSubview(buttonUpperGreek)
            view.willRemoveSubview(buttonUpperRoman)
            view.willRemoveSubview(buttonSubScript)
            view.willRemoveSubview(buttonCalcShift)

            view.addSubview(buttonOps)
            view.addSubview(buttonSets)
            view.addSubview(buttonEquals)
            view.addSubview(buttonArrows)
            view.addSubview(buttonLogGeom)
            view.addSubview(buttonLower)
            view.addSubview(buttonLowerGreek)
            view.addSubview(buttonLowerRoman)
            view.addSubview(buttonExponent)
            view.addSubview(buttonCalc)
            view.addSubview(buttonTrig)
            
        }
    }
    
    func handleKeyboardEvent(_ id: String) {
        switch id {
            
            
        case ".", ",", "'", "…", ":", ";", "!":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonDot.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
        case "+", "–", "×", "∙", "/", "%":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOps.inputID = id

            
        case "±", "∓", "∗", "⋆", "÷", "∘", "°":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpsShift.inputID = id
            shiftToggle = false
            toggleButtons()

            
            
            
        case "(":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            buttonOpen.inputID = "("
            buttonClose.inputID = ")"
            bracketTracker.append("(")
            shiftToggle = false
            toggleButtons()
            
        case ")":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            popBracketLabels()
            shiftToggle = false
            toggleButtons()
            
        case "[":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            bracketTracker.append("[")
            buttonOpen.inputID = "["
            buttonClose.inputID = "]"
            shiftToggle = false
            toggleButtons()
            
        case "]":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            popBracketLabels()
            shiftToggle = false
            toggleButtons()

        case "{":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            bracketTracker.append("{")
            buttonOpen.inputID = "{"
            buttonClose.inputID = "}"
            
        case "}":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            popBracketLabels()
            shiftToggle = false
            toggleButtons()
            
        case "〈":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            bracketTracker.append("〈")
            buttonOpen.inputID = "〈"
            buttonClose.inputID = "〉"
            
        case "〉":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            _ = popBracketLabels()
            shiftToggle = false
            toggleButtons()
            
        case "⎣":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            bracketTracker.append("⎣")
            buttonOpen.inputID = "⎣"
            buttonClose.inputID = "⎦"
            
        case "⎦":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            popBracketLabels()
            buttonOpen.inputID = "⎣"
            buttonClose.inputID = "⎦"
            
        case "⎡":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            bracketTracker.append("⎡")
            buttonOpen.inputID = "⎡"
            buttonClose.inputID = "⎤"
            
        case "⎤":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            popBracketLabels()
            buttonOpen.inputID = "⎡"
            buttonClose.inputID = "⎤"
            
        case "lvert":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            bracketTracker.append("|")
            buttonOpen.inputID = "lvert"
            buttonClose.inputID = "rvert"
            buttonOpen.displayLabel.text = "|"
            buttonClose.displayLabel.text = "|"
            
        case "rvert":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            popBracketLabels()
            buttonOpen.inputID = "lvert"
            buttonClose.inputID = "rvert"
            buttonOpen.displayLabel.text = "|"
            buttonClose.displayLabel.text = "|"
            
            
            
            
        case "sqrt":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('sqrt');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            buttonSqrt.inputID = id
            buttonSqrt.displayImageView.image = UIImage(named: "sqrt")
            shiftToggle = false
            toggleButtons()
            
        case "csqrt":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('nthroot');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('3');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Right');", completionHandler: nil)
            buttonSqrt.inputID = id
            buttonSqrt.displayImageView.image = UIImage(named: "csqrt")
            shiftToggle = false
            toggleButtons()
            
        case "nsqrt":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('nthroot');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            buttonSqrt.inputID = id
            buttonSqrt.displayImageView.image = UIImage(named: "nsqrt")
            shiftToggle = false
            toggleButtons()
            
        case "frac":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('/');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Up');", completionHandler: nil)
            buttonFrac.inputID = id
            buttonFrac.displayImageView.image = UIImage(named: "frac")
            shiftToggle = false
            toggleButtons()
            
            
        case "binom":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('binom');", completionHandler: nil)
            buttonFrac.inputID = id
            buttonFrac.displayImageView.image = UIImage(named: "binom")
            shiftToggle = false
            toggleButtons()
            
            
            
        case "Shift":
            
            if !shiftToggle {
                buttonShift.backgroundColor = SPECIAL_BUTTON_HIGHLIGHT_BG_COLOR
                buttonShift.displayLabel.text = "⬆︎"
            } else {
                buttonShift.backgroundColor = SPECIAL_BUTTON_BG_COLOR
                buttonShift.displayLabel.text = "⇧"
            }
            
            shiftToggle = !shiftToggle
            toggleButtons()
            buttonShift.setNeedsDisplay()
            
            
            
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()

            

        case "=", "<", ">", "∼", "≃", "≡", "∝":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonEquals.inputID = id
            
        case "≠", "≤", "≥", "≪", "≫", "≢":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonEqualsShift.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
            
            
        case "ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonBlackboard.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
        case "∅", "∪", "∩", "⊂", "⊃":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonSets.inputID = id
            
        case "∈":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('in');", completionHandler: nil)
            buttonSets.inputID = id
            
        case "setminus":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('∖');", completionHandler: nil)
            buttonSets.inputID = id
            buttonSets.displayLabel.text = "∖"
            
        case "mid":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('mid');", completionHandler: nil)
            buttonSets.inputID = id
            buttonSets.displayLabel.text = "|"
            
        case "⊆", "⊇":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonSetsShift.inputID = id
            shiftToggle = false
            toggleButtons()
            
        case "∉":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('notin');", completionHandler: nil)
            buttonSetsShift.inputID = id
            shiftToggle = false
            toggleButtons()
            
          
        case "←", "→", "↑", "↓", "↔︎", "↕︎", "↦":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonArrows.inputID = id
            
            
        case "⇐", "⇒", "⇑", "⇓", "⇔":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonDoubleArrows.inputID = id
            shiftToggle = false
            toggleButtons()

        case "↪":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('hookrightarrow');", completionHandler: nil)
            buttonDoubleArrows.inputID = id
            buttonDoubleArrows.displayLabel.text = "\u{21aa}\u{fe0e}"
            shiftToggle = false
            toggleButtons()
            
            
        case "∃", "∀", "¬", "∧", "∨", "⊥", "∠", "∡", "|", "∥":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLogGeom.inputID = id
            
            
        case "∄", "∀", "¬", "∧", "∨", "⊥", "∠", "∡", "∤", "∦":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLogGeomShift.inputID = id
            shiftToggle = false
            toggleButtons()

            
            
            
        case "Left", "Right", "Up", "Down":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            
            
        case "^", "_":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + id + "');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)

        case "^_":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('^{}_{}');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            
        case "^2":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('^2');", completionHandler: nil)
            
        case "^3":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('^3');", completionHandler: nil)
            
        case "^-1":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('^{-1}');", completionHandler: nil)
            
        case "_0":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('_0');", completionHandler: nil)
            
        case "_1":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('_1');", completionHandler: nil)
            
        case "_2":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('_2');", completionHandler: nil)
            
        case "∃", "∀", "∧", "∨", "⊥", "∠", "|", "∥":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLogGeom.inputID = id
            
            
        case "∄", "¬", "∡", "∤", "∦":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLogGeomShift.inputID = id
            shiftToggle = false
            toggleButtons()

            
        case "overline":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('overline');", completionHandler: nil)
            buttonOver.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
        case "vec":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('overrightarrow');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
            
        case "underline":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('underline');", completionHandler: nil)
            buttonOver.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
            
            
        case "∫":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('intop');", completionHandler: nil)
            buttonCalc.inputID = id
            
            
        case "∫ ̻":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('int');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            buttonCalc.inputID = id
            
            
        case "∬":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('iint');", completionHandler: nil)
            buttonCalc.inputID = id
            
            
            
            
        case "∮":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('oint');", completionHandler: nil)
            // don't forget this when ∫ ̻ becomes an image!
            //            buttonCalc.displayType = .Label
            buttonCalc.inputID = id
            
        case "∂", "∇", "∞":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            // don't forget this when ∫ ̻ becomes an image!
            //            buttonCalc.displayType = .Label
            buttonCalc.inputID = id
        
        case "sum":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('sum');", completionHandler: nil)
            buttonCalc.inputID = "sum"
            buttonCalc.displayLabel.text = "Σ"
            
        case "prod":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('prod');", completionHandler: nil)
            buttonCalc.inputID = "prod"
            buttonCalc.displayLabel.text = "Π"
            
        case "⊕", "⊗", "⊙", "⨿", "†", "ℏ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            // don't forget this when ∫ ̻ becomes an image!
            //            buttonCalc.displayType = .Label
            buttonCalcShift.inputID = id
            
        
        case "sin", "cos", "tan", "exp", "log":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write('" + id + "');", completionHandler: nil)
            buttonTrig.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
            
            
        case "Delete":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Backspace')", completionHandler: nil)
            shiftToggle = false
            toggleButtons()

            
        case "Copy":
            copyFormulaImage()
            shiftToggle = false
            toggleButtons()

            
        
        ////////////////////
        // ITALIC LETTERS //
        ////////////////////
            
        case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLower.inputID = id
            shiftToggle = false
            toggleButtons()

            

            
        case "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonUpper.inputID = id
            shiftToggle = false
            toggleButtons()
            
            
        /////////////////////////////
        // LOWERCASE GREEK LETTERS //
        /////////////////////////////
            
            
        case "\\alpha":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"alpha\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "α"
            shiftToggle = false
            toggleButtons()

            
        case  "\\beta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"beta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "β"
            shiftToggle = false
            toggleButtons()

            
        case "\\gamma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"gamma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "γ"
            shiftToggle = false
            toggleButtons()

            
        case "\\delta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"delta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "δ"
            shiftToggle = false
            toggleButtons()

            
        case "\\epsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"epsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ε"
            shiftToggle = false
            toggleButtons()

            
        case "\\zeta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"zeta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ζ"
            shiftToggle = false
            toggleButtons()

            
        case "\\eta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"eta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "η"
            shiftToggle = false
            toggleButtons()

            
        case "\\theta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"theta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "θ"
            shiftToggle = false
            toggleButtons()

            
        case "\\iota":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"iota\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ι"
            shiftToggle = false
            toggleButtons()

            
        case "\\kappa":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"kappa\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "κ"
            shiftToggle = false
            toggleButtons()

            
        case "\\lambda":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"lambda\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "λ"
            shiftToggle = false
            toggleButtons()

            
        case "\\mu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"mu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "μ"
            shiftToggle = false
            toggleButtons()

            
        case "\\nu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"nu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ν"
            shiftToggle = false
            toggleButtons()

            
        case "\\xi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"xi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ξ"
            shiftToggle = false
            toggleButtons()

            
        case "\\pi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"pi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "π"
            shiftToggle = false
            toggleButtons()

            
        case "\\rho":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"rho\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ρ"
            shiftToggle = false
            toggleButtons()

        case "\\sigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"sigma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "σ"
            shiftToggle = false
            toggleButtons()

        case "\\varsigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"varsigma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ς"
            shiftToggle = false
            toggleButtons()

        case "\\tau":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"tau\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "τ"
            shiftToggle = false
            toggleButtons()

        case "\\upsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"upsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "υ"
            shiftToggle = false
            toggleButtons()

        case "\\phi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"phi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "φ"
            shiftToggle = false
            toggleButtons()

        case "\\varphi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"varphi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ϕ"
            shiftToggle = false
            toggleButtons()

        case "\\chi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"chi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "χ"
            shiftToggle = false
            toggleButtons()

        case "\\psi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"psi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ψ"
            shiftToggle = false
            toggleButtons()

        case "\\omega":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"omega\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ω"
            shiftToggle = false
            toggleButtons()


        /////////////////////////////
        // UPPERCASE GREEK LETTERS //
        /////////////////////////////
            
            
            
        case "\\Gamma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Gamma\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Γ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Delta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Delta\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Δ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Theta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Theta\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Θ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Lambda":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Lambda\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Λ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Xi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Xi\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Ξ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Pi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Pi\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Π"
            shiftToggle = false
            toggleButtons()
            
        case "\\Sigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Sigma\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Σ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Upsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Upsilon\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Υ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Phi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Phi\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Φ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Psi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Psi\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Ψ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Omega":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Omega\");", completionHandler: nil)
            buttonUpperGreek.inputID = id
            buttonUpperGreek.displayLabel.text = "Ω"
            shiftToggle = false
            toggleButtons()
            
            
            
            
            
            
        /////////////////////////////
        // LOWERCASE ROMAN LETTERS //
        /////////////////////////////
            
        case "romanq":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tq');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanw":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tw');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romane":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\te');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanr":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tr');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romant":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tt');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romany":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ty');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tu');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romani":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ti');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romano":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\to');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanp":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tp');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romana":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ta');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romans":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ts');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romand":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\td');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanf":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tf');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romang":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tg');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanh":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\th');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanj":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tj');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romank":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tk');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanl":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tl');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanz":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tz');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanx":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tx');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanc":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tc');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanv":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tv');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanb":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tb');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romann":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tn');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        case "romanm":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tm');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()

            
            
            
            
        /////////////////////////////
        // UPPERCASE ROMAN LETTERS //
        /////////////////////////////
            
            
            
            
        case "romanQ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tQ');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "Q"
            shiftToggle = false
            toggleButtons()
        case "romanW":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tW');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "W"
            shiftToggle = false
            toggleButtons()
        case "romanE":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tE');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "E"
            shiftToggle = false
            toggleButtons()
        case "romanR":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tR');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "R"
            shiftToggle = false
            toggleButtons()
        case "romanT":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tT');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "T"
            shiftToggle = false
            toggleButtons()
        case "romanY":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tY');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "Y"
            shiftToggle = false
            toggleButtons()
        case "romanU":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tU');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "U"
            shiftToggle = false
            toggleButtons()
        case "romanI":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tI');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "I"
            shiftToggle = false
            toggleButtons()
        case "romanO":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tO');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "O"
            shiftToggle = false
            toggleButtons()
        case "romanP":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tP');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "P"
            shiftToggle = false
            toggleButtons()
        case "romanA":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tA');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "A"
            shiftToggle = false
            toggleButtons()
        case "romanS":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tS');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "S"
            shiftToggle = false
            toggleButtons()
        case "romanD":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tD');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "D"
            shiftToggle = false
            toggleButtons()
        case "romanF":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tF');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "F"
            shiftToggle = false
            toggleButtons()
        case "romanG":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tG');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "G"
            shiftToggle = false
            toggleButtons()
        case "romanH":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tH');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "H"
            shiftToggle = false
            toggleButtons()
        case "romanJ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tJ');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "J"
            shiftToggle = false
            toggleButtons()
        case "romanK":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tK');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "K"
            shiftToggle = false
            toggleButtons()
        case "romanL":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tL');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "L"
            shiftToggle = false
            toggleButtons()
        case "romanZ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tZ');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "Z"
            shiftToggle = false
            toggleButtons()
        case "romanX":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tX');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "X"
            shiftToggle = false
            toggleButtons()
        case "romanC":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tC');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "C"
            shiftToggle = false
            toggleButtons()
        case "romanV":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tV');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "V"
            shiftToggle = false
            toggleButtons()
        case "romanB":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tB');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "B"
            shiftToggle = false
            toggleButtons()
        case "romanN":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tN');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "N"
            shiftToggle = false
            toggleButtons()
        case "romanM":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tM');", completionHandler: nil)
            buttonUpperRoman.inputID = id
            buttonUpperRoman.displayLabel.text = "M"
            shiftToggle = false
            toggleButtons()
            
            
            
        default:
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            shiftToggle = false
            toggleButtons()
        }
    }
    
    
    
    
    func popBracketLabels() {
        
        _ = bracketTracker.popLast()
        if let currentBracketType = bracketTracker.last {
            
            switch currentBracketType {
                
            case "(":
                buttonOpen.inputID = "("
                buttonClose.inputID = ")"
                
            case "[":
                buttonOpen.inputID = "["
                buttonClose.inputID = "]"
                
            case "{":
                buttonOpen.inputID = "{"
                buttonClose.inputID = "}"
                
            case "〈":
                buttonOpen.inputID = "〈"
                buttonClose.inputID = "〉"
                
            case "⎣":
                buttonOpen.inputID = "⎣"
                buttonClose.inputID = "⎦"
                
            case "⎡":
                buttonOpen.inputID = "⎡"
                buttonClose.inputID = "⎤"
                
            case "|":
                buttonOpen.inputID = "lvert"
                buttonClose.inputID = "rvert"
                buttonOpen.displayLabel.text = "|"
                buttonClose.displayLabel.text = "|"
                
            default:
                NSLog("unrecognized bracket type")

            }
            
        }
        
    }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        //let typedSymbol = textView.text
        //_ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + typedSymbol! + "');", completionHandler: nil)
        //if (typedSymbol! == "\\sqrt") {
        //    _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
        //}
        //myTextView.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    
    func inputSelected(inputIdentifier: String) {
        NSLog(inputIdentifier)
    }
    
    
    func isOpenAccessGranted() -> Bool {
        if #available(iOS 10.0, iOSApplicationExtension 10.0, *) {
            let value = UIPasteboard.general.string
            UIPasteboard.general.string = "checkOpenedAccess"
            UIPasteboard.general.image = image()
            
            let hasString = UIPasteboard.general.string != nil
            if let _ = value, hasString {
                UIPasteboard.general.string = value
            }
            return hasString
        }
        else {
            return UIPasteboard(name: UIPasteboardName(rawValue: "checkOpenedAccess"), create: true) != nil
        }
    }
    
    
    func copyFormulaImage() {
        formulaWebView?.evaluateJavaScript("answerMathField.blur();", completionHandler: nil)
        self.perform(#selector(grabWebView), with: nil, afterDelay: 0.5)
        formulaWebView?.evaluateJavaScript("answerMathField.focus();", completionHandler: nil)
    }
    
    @objc func grabWebView() {
        let formulaImage = image()
        let imageData = UIImagePNGRepresentation(formulaImage)
        let pasteBoard = UIPasteboard.general
        pasteBoard.setData(imageData!, forPasteboardType:"public.image")
        
        if self.isOpenAccessGranted() {
            print("open access")
        } else {
            print("no open access")
        }
    }
    
    func image() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions((formulaWebView?.frame.size)!,false, UIScreen.main.scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(UIColor.white.cgColor)
        formulaWebView?.layer.render(in: ctx!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        let trimmedImage = (image?.trim())!
        let squaredImage = trimmedImage.padToSquare()//.imageWithColor(newColor: UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.5))!
        
        return squaredImage
    }
    
    
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0) //formulaWebView!.scrollView.contentSize, true, 0)
        var renderingFrame = formulaWebView!.scrollView.frame
        renderingFrame.size = formulaWebView!.scrollView.contentSize
        formulaWebView!.drawHierarchy(in: renderingFrame, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //UIImageWriteToSavedPhotosAlbum(snapshotImage, nil, nil, nil)
        
        return snapshotImage!
    }
    
    func snapshot2() -> UIImage {
    
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        formulaWebView?.clipsToBounds = false
        let image = renderer.image { ctx in
            formulaWebView?.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        formulaWebView?.clipsToBounds = true
        return image
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    
}

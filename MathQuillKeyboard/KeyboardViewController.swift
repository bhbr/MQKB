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
let ARROW_BUTTON_BG_COLOR: UIColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)

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
        formulaWebView?.frame = containerView.frame
        formulaWebView?.frame.origin = CGPoint(x: 0, y: 0)
        formulaWebView?.layer.borderWidth = 1.0
        formulaWebView?.layer.borderColor = UIColor.black.cgColor
        
        formulaWebView?.tintColor = .yellow
        
        let localfilePath = Bundle.main.url(forResource: "test", withExtension: "html")
        let myRequest = URLRequest(url: localfilePath!)
        _ = formulaWebView?.load(myRequest)
        
        view.setNeedsDisplay()
        
        myTextView = UITextView()
        myTextView.delegate = self
        
        
        
        
        // dummy default values
        
        let buttonXOffset: CGFloat = 5.0
        let buttonYOffset: CGFloat = 80.0
        
        let buttonWidth: CGFloat = 35.0
        let buttonHeight: CGFloat = 45.0
        
        
        /////////////////
        // NEXT BUTTON //
        /////////////////
        
        
        buttonNext = MuFuKeyboardButton(x: buttonXOffset, y: 10.0, style: .Phone)
        buttonNext.position = .Inner
        buttonNext.frame.size.width = 33.0
        buttonNext.inputID = "Next"
        buttonNext.displayLabel.text = "🌐"
        buttonNext.showMagnifier = false
        buttonNext.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonNext.displayType = .Label
        buttonNext.delegate = self
        view.addSubview(buttonNext)

        buttonNext.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        

        
 // MARK: - Upper Row
        
        
        buttonDot = MuFuKeyboardButton(x: buttonXOffset, y: buttonYOffset, style: .Phone)
        buttonDot.position = .Inner
        buttonDot.inputID = "."
        buttonDot.inputOptionsIDs = [".", ",", "'", "…", ":", ";", "!"]
        buttonDot.optionsRowLengths = [4, 3]
        buttonDot.optionsRowOffsets = [0.0, 0.5]
        buttonDot.displayType = .Label
        buttonDot.delegate = self

        
        buttonOps = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOps.position = .Inner
        buttonOps.inputID = "+"
        buttonOps.inputOptionsIDs = ["+", "–", "×", "·", "/", ":", "%"]
        buttonOps.optionsRowLengths = [4, 3]
        buttonOps.optionsRowOffsets = [0.0, 0.5]
        buttonOps.displayType = .Label
        buttonOps.delegate = self


        buttonOpsShift = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOpsShift.position = .Inner
        buttonOpsShift.inputID = "±"
        buttonOpsShift.inputOptionsIDs = ["±", "∓","∗", "·", "÷", "∘", "°"]
        buttonOpsShift.optionsRowLengths = [4, 3]
        buttonOpsShift.optionsRowOffsets = [0.0, 0.5]
        buttonOpsShift.displayType = .Label
        buttonOpsShift.delegate = self



        buttonOpen = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonOpen.position = .Inner
        buttonOpen.inputID = "("
        buttonOpen.inputOptionsIDs = ["(", "[", "{", "〈", "⎣", "⎡", "lvert"]
        buttonOpen.inputOptionsGlyphs = ["(", "[", "{", "〈", "⎣", "⎡", "|"]
        buttonOpen.displayLabel.text = "("
        buttonOpen.displayType = .Label
        buttonOpen.delegate = self



        buttonClose = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonClose.position = .Inner
        buttonClose.inputID = ")"
        buttonClose.inputOptionsIDs = [")", "]", "}", "〉", "⎦", "⎤", "rvert"]
        buttonClose.inputOptionsGlyphs = [")", "]", "}", "〉", "⎦", "⎤"]
        buttonClose.displayLabel.text = ")"
        buttonClose.displayType = .Label
        buttonClose.delegate = self



        buttonBlackboard = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonBlackboard.position = .Left
        buttonBlackboard.inputID = "ℕ"
        buttonBlackboard.inputOptionsIDs = ["ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ"]
        buttonBlackboard.inputOptionsGlyphs = ["ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ"]
        buttonBlackboard.optionsRowLengths = [4, 4]
        buttonBlackboard.optionsRowOffsets = [0.0, 0.0]
        buttonBlackboard.displayType = .Label
        buttonBlackboard.font? = .systemFont(ofSize: 14.0)
        buttonBlackboard.showMagnifier = false
        buttonBlackboard.optionsViewDelay = 0.0
        buttonBlackboard.delegate = self



        buttonSets = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonSets.position = .Inner
        buttonSets.inputID = "element"
        buttonSets.inputOptionsIDs = ["∈", "∅", "∪", "∩", "\\", "|", "⊂", "⊃"]
        buttonSets.inputOptionsGlyphs = ["∈", "∅", "∪", "∩", "\\", "|", "⊂", "⊃"]
        buttonSets.optionsRowLengths = [4, 4]
        buttonSets.optionsRowOffsets = [0.0, 0.0]
        buttonSets.displayType = .Label
        buttonSets.displayLabel.text = "∈"
        buttonSets.delegate = self


        buttonSetsShift = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonSetsShift.position = .Inner
        buttonSetsShift.inputID = "nelement"
        buttonSetsShift.inputOptionsIDs = ["∉", "∅", "∪", "∩", "\\", "|", "⊆", "⊇"]
        buttonSetsShift.inputOptionsGlyphs = ["∉", "∅", "∪", "∩", "\\", "|", "⊆", "⊇"]
        buttonSetsShift.optionsRowLengths = [4, 4]
        buttonSetsShift.optionsRowOffsets = [0.0, 0.0]
        buttonSetsShift.displayType = .Label
        buttonSetsShift.displayLabel.text = "∉"
        buttonSetsShift.delegate = self



        buttonShift = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset, style: .Phone)
        buttonShift.position = .Inner
        //buttonShift.frame.size.width = 60.0
        buttonShift.inputID = "Shift"
        buttonShift.displayLabel.text = "⇧"
        buttonShift.showMagnifier = false
        buttonShift.keyColor = SPECIAL_BUTTON_BG_COLOR
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
        buttonDelete.displayImageView.image = UIImage(named:"backspace_key")
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
        buttonDigit.displayImageView.image = UIImage(named: "digit_key")
        buttonDigit.delegate = self



        buttonEquals = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonEquals.position = .Inner
        buttonEquals.inputID = "="
        buttonEquals.inputOptionsIDs = ["=", "<", ">", "∼", "≃", "≡", "∝"]
        buttonEquals.labelIsPersistent = false
        buttonEquals.displayType = .Label
        buttonEquals.delegate = self



        buttonEqualsShift = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonEqualsShift.position = .Inner
        buttonEqualsShift.inputID = "≠"
        buttonEqualsShift.inputOptionsIDs = ["≠", "≤", "≥", "≪", "≫", "≢"]
        buttonEqualsShift.labelIsPersistent = false
        buttonEqualsShift.displayType = .Label
        buttonEqualsShift.delegate = self







        buttonSqrt = MuFuKeyboardButton(x: buttonXOffset + 2.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonSqrt.position = .Inner
        buttonSqrt.inputID = "sqrt"
        buttonSqrt.displayImageView.image = UIImage(named: "sqrt_key")
        buttonSqrt.magnifiedDisplayImageView.image = UIImage(named: "sqrt_key")
        buttonSqrt.inputOptionsIDs = ["csqrt", "nsqrt"]
        let csqrtImage = UIImage(named: "nsqrt_key")!
        let nsqrtImage = UIImage(named: "nsqrt_key")!
        buttonSqrt.inputOptionsImages = [csqrtImage,nsqrtImage]
        buttonSqrt.displayType = .Image
        buttonSqrt.labelIsPersistent = false
        buttonSqrt.delegate = self




        buttonFrac = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonFrac.position = .Inner
        buttonFrac.inputID = "frac"
        let fracImage = UIImage(named: "frac_key")
        let binomImage = UIImage(named: "frac_key")
        buttonFrac.displayImageView.image = fracImage
        buttonFrac.inputOptionsIDs = ["frac", "binom"]
        buttonFrac.inputOptionsImages = [fracImage!, binomImage!]
        buttonFrac.displayType = .Image
        buttonFrac.delegate = self


        buttonArrows = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonArrows.position = .Inner
        buttonArrows.inputID = "→"
        buttonArrows.inputOptionsIDs = ["←", "→", "↑", "↓", "↔︎", "↕︎", "↦"]
        buttonArrows.inputOptionsGlyphs = ["←", "→", "↑", "↓", "↔︎", "↕︎", "↦"]
        buttonArrows.displayType = .Label
        buttonArrows.displayLabel.text = "→"
        buttonArrows.labelIsPersistent = false
        buttonArrows.delegate = self


        buttonDoubleArrows = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonDoubleArrows.position = .Inner
        buttonDoubleArrows.inputID = "Rightarrow"
        buttonDoubleArrows.inputOptionsIDs = ["Leftarrow", "Rightarrow", "Uparrow", "Downarrow", "Leftrightarrow", "Updownarrow"]
        buttonDoubleArrows.inputOptionsGlyphs = ["⇐", "⇒", "⇑", "⇓", "⇔", "⇕"]
        buttonDoubleArrows.displayType = .Label
        buttonDoubleArrows.displayLabel.text = "→"
        buttonDoubleArrows.labelIsPersistent = false
        buttonDoubleArrows.delegate = self




        buttonLogGeom = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonLogGeom.position = .Inner
        buttonLogGeom.inputID = "forall"
        buttonLogGeom.inputOptionsIDs = ["forall", "exists", "not", "wedge", "vee", "perp", "angle", "mangle", "pipe", "parallel"]
        buttonLogGeom.inputOptionsGlyphs = ["∃", "∀", "¬", "∧", "∨", "⊥", "∠", "∡", "|", "∥"]
        buttonLogGeom.optionsRowLengths = [5, 5]
        buttonLogGeom.optionsRowOffsets = [0.0, 0.0]
        buttonLogGeom.displayType = .Label
        buttonLogGeom.displayLabel.text = "∀"
        buttonLogGeom.labelIsPersistent = false
        buttonLogGeom.delegate = self



        buttonLogGeomShift = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 1.0 * buttonHeight, style: .Phone)
        buttonLogGeomShift.position = .Inner
        buttonLogGeomShift.inputID = "forall"
        buttonLogGeomShift.inputOptionsIDs = ["forall", "nexists", "not", "wedge", "vee", "perp", "angle", "mangle", "npipe", "nparallel"]
        buttonLogGeomShift.inputOptionsGlyphs = ["∄", "∀", "¬", "∧", "∨", "⊥", "∠", "∡", "∤", "∦"]
        buttonLogGeomShift.optionsRowLengths = [5, 5]
        buttonLogGeomShift.optionsRowOffsets = [0.0, 0.0]
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
        buttonLowerGreek.optionsRowLengths = [10, 9, 7]
        buttonLowerGreek.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonLowerGreek.displayLabel.text = "α"
        buttonLowerGreek.displayLabel.font = UIFont.italicSystemFont(ofSize: 22.0)
        buttonLowerGreek.displayType = .Label
        buttonLowerGreek.delegate = self



        buttonUpperGreek = MuFuKeyboardButton(x: buttonXOffset + 1.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonUpperGreek.position = .Right
        buttonUpperGreek.inputID = "\\Alpha"
        buttonUpperGreek.inputOptionsIDs = ["\\Alpha", "\\Beta", "\\Gamma", "\\Delta", "\\Epsilon", "\\Zeta", "\\Eta", "\\Theta", "\\Iota", "\\Kappa", "\\Lambda", "\\Mu", "\\Nu", "\\Xi", "\\Omicron", "\\Pi", "\\Rho", "\\Sigma", "\\Tau", "\\Upsilon", "\\Phi", "\\Chi", "\\Psi", "\\Omega"]
        buttonUpperGreek.inputOptionsGlyphs = ["Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ", "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω"]
        buttonUpperGreek.inputOptionsFont = UIFont.italicSystemFont(ofSize: 22.0)
        buttonUpperGreek.optionsRowLengths = [9, 8, 7]
        buttonUpperGreek.optionsRowOffsets = [0.0, 10.0, 20.0]
        buttonUpperGreek.displayLabel.text = "Α"
        buttonUpperGreek.displayLabel.font = UIFont.italicSystemFont(ofSize: 22.0)
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
        buttonExponent.inputOptionsIDs = ["_", "^2", "^3", "^-1", "^_"]
        buttonExponent.displayImageView.image = UIImage(named:"exponent")
        buttonExponent.inputOptionsImages = [UIImage(named:"sub")!, UIImage(named:"subsup")!]
        buttonExponent.displayType = .Image
        buttonExponent.delegate = self


        buttonSubScript = MuFuKeyboardButton(x: buttonXOffset + 3.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonSubScript.position = .Inner
        buttonSubScript.inputID = "^"
        buttonSubScript.inputOptionsIDs = ["_", "^2", "^3", "^-1", "^_"]
        buttonSubScript.displayImageView.image = UIImage(named:"exponent")
        buttonSubScript.inputOptionsImages = [UIImage(named:"sub")!, UIImage(named:"subsup")!]
        buttonSubScript.displayType = .Image
        buttonSubScript.delegate = self


        buttonOver = MuFuKeyboardButton(x: buttonXOffset + 4.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonOver.position = .Inner
        buttonOver.inputID = "overline"
        buttonOver.inputOptionsIDs = ["overline", "overarrow", "underline"]
        buttonOver.inputOptionsGlyphs = ["¯", " ⃗", "_"]
        buttonOver.displayType = .Label
        buttonOver.displayLabel.text = "¯"
        buttonOver.delegate = self








        buttonCalc = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCalc.position = .Inner
        buttonCalc.inputID = "partial"
        buttonCalc.inputOptionsIDs = ["partial", "nabla", "sum", "prod", "infty", "int", "int_bounds", "oint"]
        buttonCalc.inputOptionsGlyphs = ["∂", "∇", "Σ", "Π", "∞", "∫", "∫'", "∮"]
        buttonCalc.displayType = .Label
        buttonCalc.displayLabel.text = "∂"
        buttonCalc.delegate = self



        buttonCalcShift = MuFuKeyboardButton(x: buttonXOffset + 5.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCalcShift.position = .Inner
        buttonCalcShift.inputID = "oplus"
        buttonCalcShift.inputOptionsIDs = ["oplus", "otimes", "odot", "amalg", "dagger", "hbar"]
        buttonCalcShift.inputOptionsGlyphs = ["⊕", "⊗", "⊙", "⨿", "†", "ℏ"]
        buttonCalcShift.displayType = .Label
        buttonCalcShift.displayLabel.text = "⊕"
        buttonCalcShift.delegate = self





        buttonTrig = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonTrig.position = .Inner
        buttonTrig.inputID = "sin"
        buttonTrig.inputOptionsIDs = ["sin", "cos", "tan"]
        buttonTrig.displayType = .Label
        buttonTrig.displayLabel.text = "sin"
        buttonTrig.displayLabel.font? = .systemFont(ofSize: 10.0)
        buttonTrig.delegate = self




        buttonTrigShift = MuFuKeyboardButton(x: buttonXOffset + 6.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonTrigShift.position = .Inner
        buttonTrigShift.inputID = "sin⁻¹"
        buttonTrigShift.inputOptionsIDs = ["sin⁻¹", "cos⁻¹", "tan⁻¹"]
        buttonTrigShift.displayType = .Label
        buttonTrigShift.displayLabel.text = "sin⁻¹"
        buttonTrigShift.displayLabel.font? = .systemFont(ofSize: 10.0)
        buttonTrigShift.delegate = self






        buttonCopy = MuFuKeyboardButton(x: buttonXOffset + 7.0 * buttonWidth, y: buttonYOffset + 2.0 * buttonHeight, style: .Phone)
        buttonCopy.frame.size.width = 65.0
        buttonCopy.position = .Inner
        buttonCopy.inputID = "Copy"
        buttonCopy.displayLabel.text = "Copy"
        buttonCopy.showMagnifier = false
        buttonCopy.keyColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)
        buttonCopy.displayLabel.textColor = .white
        buttonCopy.displayType = .Label
        buttonCopy.delegate = self
        
        
        
        
        
        
        
        
        
        view.addSubview(buttonDot)
        view.addSubview(buttonOpen)
        view.addSubview(buttonClose)
        view.addSubview(buttonBlackboard)
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
            view.addSubview(buttonTrigShift)
            
        } else {
            
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
            view.willRemoveSubview(buttonTrigShift)

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
            
            
        case "+", "–", "×", "∙", "/", "%":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOps.inputID = id
            shiftToggle = false

            
        case "±", "∓", "∗", "⋆", "÷", "∘", "°":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpsShift.inputID = id
            shiftToggle = true

            
            
            
        case "(", ")":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "("
            buttonClose.inputID = ")"
        case "[", "]":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "]"
            buttonClose.inputID = "]"
        case "{", "}":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "{"
            buttonClose.inputID = "}"
        case "〈", "〉":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "〈"
            buttonClose.inputID = "〉"
        case "⎣", "⎦":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "⎣"
            buttonClose.inputID = "⎦"
        case "⎡", "⎤":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "⎡"
            buttonClose.inputID = "⎤"
        case "lvert", "rvert":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + id + "');", completionHandler: nil)
            buttonOpen.inputID = "lvert"
            buttonClose.inputID = "rvert"
            
        case "ℕ", "ℤ", "ℚ", "ℝ", "ℂ", "ℍ", "ℙ", "ℵ":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonBlackboard.inputID = id
            shiftToggle = false

            
        case "∈", "∅", "∪", "∩", "|", "⊂", "⊃":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonSets.inputID = id
            shiftToggle = false

        case "∉", "∅", "∪", "∩", "\\", "|", "⊆", "⊇":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonSetsShift.inputID = id
            shiftToggle = false
            
            
            
        case "\\":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\setminus');", completionHandler: nil)
        case "∫":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\int');",
                                                   completionHandler: nil)
        case "sqrt":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\sqrt');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
        case "^", "_":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('" + id + "');", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
        case "^_":
            NSLog("combined sub+sup is not implemented yet")
        case "nsqrt":
            NSLog("nthroot not implemented yet")
        case "frac":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('/');", completionHandler: nil)
            //_ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Up');", completionHandler: nil)
            //_ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            
            
            
            
        case "=", "<", ">", "≤", "≥", "≪", "≫":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonEquals.inputID = id
            
            
        case "Left", "Right", "Up", "Down":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('" + id + "');", completionHandler: nil)
            
        case "Delete":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Backspace')", completionHandler: nil)
            
        case "Copy":
            copyFormulaImage()
            
        case "Shift":
            shiftToggle = !shiftToggle
            toggleButtons()
            
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
         
        
        ////////////////////
        // ITALIC LETTERS //
        ////////////////////
            
        case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
            buttonLower.inputID = id
            
            
        case "vec":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"overrightarrow\");", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke(\"Left\");", completionHandler: nil)
            _ = formulaWebView?.evaluateJavaScript("answerMathField.write(\"u\");", completionHandler: nil)
            
            
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
            
        case  "\\beta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"beta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "β"
            
        case "\\gamma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"gamma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "γ"
            
        case "\\delta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"delta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "δ"
            
        case "\\epsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"epsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ε"
            
        case "\\zeta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"zeta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ζ"
            
        case "\\eta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"eta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "η"
            
        case "\\theta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"theta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "θ"
            
        case "\\iota":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"iota\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ι"
            
        case "\\kappa":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"kappa\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "κ"
            
        case "\\lambda":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"lambda\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "λ"
            
        case "\\mu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"mu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "μ"
            
        case "\\nu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"nu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ν"
            
        case "\\xi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"xi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ξ"
            
        case "\\omicron":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"omicron\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ο"
            
        case "\\pi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"pi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "π"
            
        case "\\rho":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"rho\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ρ"
            
        case "\\sigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"sigma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "σ"
            
        case "\\varsigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"varsigma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ς"
            
        case "\\tau":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"tau\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "τ"
            
        case "\\upsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"upsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "υ"
            
        case "\\phi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"phi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "φ"
            
        case "\\varphi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"varphi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ϕ"
            
        case "\\chi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"chi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "χ"
            
        case "\\psi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"psi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ψ"
            
        case "\\omega":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"omega\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "ω"
            

        /////////////////////////////
        // UPPERCASE GREEK LETTERS //
        /////////////////////////////
            
            
            
        case "\\Alpha":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Alpha\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Α"
            shiftToggle = false
            toggleButtons()
            shiftToggle = false
            toggleButtons()
            
        case  "\\Beta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Beta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Β"
            shiftToggle = false
            toggleButtons()
            
        case "\\Gamma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Gamma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Γ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Delta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Delta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Δ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Epsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Epsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ε"
            shiftToggle = false
            toggleButtons()
            
        case "\\Zeta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Zeta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ζ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Eta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Eta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Η"
            shiftToggle = false
            toggleButtons()
            
        case "\\Theta":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Theta\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Θ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Iota":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Iota\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ι"
            shiftToggle = false
            toggleButtons()
            
        case "\\Kappa":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Kappa\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Κ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Lambda":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Lambda\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Λ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Mu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Mu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Μ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Nu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Nu\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ν"
            shiftToggle = false
            toggleButtons()
            
        case "\\Xi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Xi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ξ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Omicron":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Omicron\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ο"
            shiftToggle = false
            toggleButtons()
            
        case "\\Pi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Pi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Π"
            shiftToggle = false
            toggleButtons()
            
        case "\\Rho":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Rho\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ρ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Sigma":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Sigma\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Σ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Tau":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Tau\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Τ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Upsilon":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Upsilon\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Υ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Phi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Phi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Φ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Chi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Chi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Χ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Psi":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Psi\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ψ"
            shiftToggle = false
            toggleButtons()
            
        case "\\Omega":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd(\"Omega\");", completionHandler: nil)
            buttonLowerGreek.inputID = id
            buttonLowerGreek.displayLabel.text = "Ω"
            shiftToggle = false
            toggleButtons()
            
            
            
            
            
            
        /////////////////////////////
        // LOWERCASE ROMAN LETTERS //
        /////////////////////////////
            
        case "romanq":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tq');", completionHandler: nil)
        case "romanw":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tw');", completionHandler: nil)
        case "romane":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\te');", completionHandler: nil)
        case "romanr":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tr');", completionHandler: nil)
        case "romant":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tt');", completionHandler: nil)
        case "romany":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ty');", completionHandler: nil)
        case "romanu":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tu');", completionHandler: nil)
        case "romani":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ti');", completionHandler: nil)
        case "romano":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\to');", completionHandler: nil)
        case "romanp":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tp');", completionHandler: nil)
        case "romana":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ta');", completionHandler: nil)
        case "romans":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\ts');", completionHandler: nil)
        case "romand":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\td');", completionHandler: nil)
        case "romanf":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tf');", completionHandler: nil)
        case "romang":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tg');", completionHandler: nil)
        case "romanh":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\th');", completionHandler: nil)
        case "romanj":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tj');", completionHandler: nil)
        case "romank":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tk');", completionHandler: nil)
        case "romanl":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tl');", completionHandler: nil)
        case "romanz":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tz');", completionHandler: nil)
        case "romanx":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tx');", completionHandler: nil)
        case "romanc":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tc');", completionHandler: nil)
        case "romanv":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tv');", completionHandler: nil)
        case "romanb":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tb');", completionHandler: nil)
        case "romann":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tn');", completionHandler: nil)
        case "romanm":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\tm');", completionHandler: nil)
            
            
            
            
            
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
        
        formulaWebView?.layer.borderWidth = 0.0
        UIGraphicsBeginImageContextWithOptions((formulaWebView?.frame.size)!,false, UIScreen.main.scale)
        let ctx = UIGraphicsGetCurrentContext()
        formulaWebView?.layer.render(in: ctx!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        formulaWebView?.layer.borderWidth = 1.0
        
        let trimmedImage = (image?.trim())!
        let squaredImage = trimmedImage.padToSquare()//.imageWithColor(newColor: UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.5))!
        
        return squaredImage
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    
}

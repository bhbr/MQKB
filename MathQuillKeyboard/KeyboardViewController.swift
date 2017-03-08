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

extension UIImage {
    
    func padToSquare() -> UIImage {
        
        let sideLength = (size.width > size.height) ? size.width : size.height
        let newWidth = sideLength
        let newHeight = sideLength
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
    func imageWithColor (newColor: UIColor?) -> UIImage? {
        
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

    
}


class KeyboardViewController: UIInputViewController, UITextViewDelegate, MFKBDelegate {
    
    @IBOutlet var nextKeyboardButton: UIButton!
    
    @IBOutlet var containerView : UIView!
    var formulaWebView: WKWebView?
    var myView : UIView!
    var myTextView: UITextView!
    
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
        
//        let myButton = MuFuKeyboardButton(frame: CGRect(x:50,y:150,width:30,height:45))
//        // iPhone: 30x45, iPad: 57x56 // ???
//        myButton.translatesAutoresizingMaskIntoConstraints = false
//        myButton.inputID = "√"
//        let image = UIImage(named:"sqrt_key")
//        myButton.displayImageView.image = image
//        myButton.magnifiedDisplayImageView.image = image
//        myButton.displayType = .Image
//        myButton.delegate = self
//        myButton.inputOptionsIDs = ["√", "∫"]//, "omega"]
//        //myButton.rowCounts = [1, 2]
//        let optionImage1 = UIImage(named:"integral_key")!
//        let optionImage2 = UIImage(named:"sqrt_key")!
//        let optionImage3 = UIImage(named:"sqrt_key")!
//        //myButton.inputOptionsImages = [optionImage1, optionImage2, optionImage3]
//
//        //myButton.textInput = myTextView
//        
//        view.addSubview(myButton)
        
        let button7 = MuFuKeyboardButton(x: 10.0, y: 80.0, style: .Phone)
        button7.position = .Left
        button7.inputID = "7"
        button7.displayType = .Label
        button7.delegate = self
        view.addSubview(button7)
        
        let button8 = MuFuKeyboardButton(x: 10.0 + 30.0, y: 80.0, style: .Phone)
        button8.position = .Inner
        button8.inputID = "8"
        button8.displayType = .Label
        button8.delegate = self
        view.addSubview(button8)
        
        let button9 = MuFuKeyboardButton(x: 10.0 + 2.0 * 30.0, y: 80.0, style: .Phone)
        button9.position = .Inner
        button9.inputID = "9"
        button9.displayType = .Label
        button9.delegate = self
        view.addSubview(button9)
        
        let button4 = MuFuKeyboardButton(x: 10.0, y: 80.0 + 45.0, style: .Phone)
        button4.position = .Left
        button4.inputID = "4"
        button4.displayType = .Label
        button4.delegate = self
        view.addSubview(button4)
        
        let button5 = MuFuKeyboardButton(x: 10.0 + 30.0, y: 80.0 + 45.0, style: .Phone)
        button5.position = .Inner
        button5.inputID = "5"
        button5.displayType = .Label
        button5.delegate = self
        view.addSubview(button5)
        
        let button6 = MuFuKeyboardButton(x: 10.0 + 2.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        button6.position = .Inner
        button6.inputID = "6"
        button6.displayType = .Label
        button6.delegate = self
        view.addSubview(button6)
        
        let button1 = MuFuKeyboardButton(x: 10.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        button1.position = .Left
        button1.inputID = "1"
        button1.displayType = .Label
        button1.delegate = self
        view.addSubview(button1)
        
        let button2 = MuFuKeyboardButton(x: 10.0 + 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        button2.position = .Inner
        button2.inputID = "2"
        button2.displayType = .Label
        button2.delegate = self
        view.addSubview(button2)
        
        let button3 = MuFuKeyboardButton(x: 10.0 + 2.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        button3.position = .Inner
        button3.inputID = "3"
        button3.displayType = .Label
        button3.delegate = self
        view.addSubview(button3)
        
        let button0 = MuFuKeyboardButton(x: 10.0 + 3.0 * 30.0, y: 80.0, style: .Phone)
        button0.position = .Inner
        button0.inputID = "0"
        button0.displayType = .Label
        button0.delegate = self
        view.addSubview(button0)
        
        let buttonDot = MuFuKeyboardButton(x: 10.0 + 3.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonDot.position = .Inner
        buttonDot.inputID = "."
        buttonDot.inputOptionsIDs = [",", "'", ":", ";", "…"]
        buttonDot.displayType = .Label
        buttonDot.delegate = self
        view.addSubview(buttonDot)
        
        let buttonEquals = MuFuKeyboardButton(x: 10.0 + 3.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonEquals.position = .Inner
        buttonEquals.inputID = "="
        buttonEquals.inputOptionsIDs = ["<", "≤", ">", "≥",  "≠", "≪", "≫"]
        buttonEquals.displayType = .Label
        buttonEquals.delegate = self
        view.addSubview(buttonEquals)
        
        let buttonPlus = MuFuKeyboardButton(x: 10.0 + 4.0 * 30.0, y: 80.0, style: .Phone)
        buttonPlus.position = .Inner
        buttonPlus.inputID = "+"
        buttonPlus.inputOptionsIDs = ["±", "∓"]
        buttonPlus.displayType = .Label
        buttonPlus.delegate = self
        view.addSubview(buttonPlus)
        
        let buttonMinus = MuFuKeyboardButton(x: 10.0 + 4.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonMinus.position = .Inner
        buttonMinus.inputID = "-"
        buttonMinus.displayType = .Label
        buttonMinus.delegate = self
        view.addSubview(buttonMinus)
        
        
        let buttonTimes = MuFuKeyboardButton(x: 10.0 + 4.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonTimes.position = .Inner
        buttonTimes.inputID = "×"
        buttonTimes.inputOptionsIDs = ["∙", "∗", "∘"]
        buttonTimes.displayType = .Label
        buttonTimes.delegate = self
        view.addSubview(buttonTimes)
        
        let buttonDivision = MuFuKeyboardButton(x: 10.0 + 5.0 * 30.0, y: 80.0, style: .Phone)
        buttonDivision.position = .Inner
        buttonDivision.inputID = "÷"
        buttonDivision.displayImageView.image = UIImage(named: "frac_key")
        //buttonDivision.inputOptionsIDs = [":", "/", "\\"]
        buttonDivision.displayType = .Image
        buttonDivision.delegate = self
        view.addSubview(buttonDivision)
        
        let buttonSqrt = MuFuKeyboardButton(x: 10.0 + 5.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonSqrt.position = .Inner
        buttonSqrt.inputID = "sqrt"
        buttonSqrt.displayImageView.image = UIImage(named: "sqrt_key")
        buttonSqrt.magnifiedDisplayImageView.image = UIImage(named: "sqrt_key")
        buttonSqrt.inputOptionsIDs = ["nsqrt"]
        let nsqrtImage = UIImage(named: "nsqrt_key")!
        buttonSqrt.inputOptionsImages = [nsqrtImage]
        buttonSqrt.displayType = .Image
        buttonSqrt.delegate = self
        view.addSubview(buttonSqrt)
        
        
        let buttonExponent = MuFuKeyboardButton(x: 10.0 + 5.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonExponent.position = .Inner
        buttonExponent.inputID = "^"
        buttonExponent.inputOptionsIDs = ["_", "^_"]
        buttonExponent.displayImageView.image = UIImage(named:"exponent")
        buttonExponent.inputOptionsImages = [UIImage(named:"sub")!, UIImage(named:"subsup")!]
        buttonExponent.displayType = .Image
        buttonExponent.delegate = self
        view.addSubview(buttonExponent)
        
        
        let buttonLeft = MuFuKeyboardButton(x: 10.0 + 7.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonLeft.position = .Inner
        buttonLeft.inputID = "Left"
        buttonLeft.displayLabel.text = "←"
        buttonLeft.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonLeft.keyTextColor = .white
        buttonLeft.displayType = .Label
        buttonLeft.delegate = self
        view.addSubview(buttonLeft)

        let buttonRight = MuFuKeyboardButton(x: 10.0 + 9.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonRight.position = .Inner
        buttonRight.inputID = "Right"
        buttonRight.displayLabel.text = "→"
        buttonRight.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonRight.keyTextColor = .white
        buttonRight.displayType = .Label
        buttonRight.delegate = self
        view.addSubview(buttonRight)

        let buttonUp = MuFuKeyboardButton(x: 10.0 + 8.0 * 30.0, y: 80.0, style: .Phone)
        buttonUp.position = .Inner
        buttonUp.inputID = "Up"
        buttonUp.displayLabel.text = "↑"
        buttonUp.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonUp.keyTextColor = .white
        buttonUp.displayType = .Label
        buttonUp.delegate = self
        view.addSubview(buttonUp)

        let buttonDown = MuFuKeyboardButton(x: 10.0 + 8.0 * 30.0, y: 80.0 + 45.0, style: .Phone)
        buttonDown.position = .Inner
        buttonDown.inputID = "Down"
        buttonDown.displayLabel.text = "↓"
        buttonDown.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonDown.keyTextColor = .white
        buttonDown.displayType = .Label
        buttonDown.delegate = self
        view.addSubview(buttonDown)

        let buttonX = MuFuKeyboardButton(x: 10.0 + 6.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonX.position = .Inner
        buttonX.inputID = "x"
        buttonX.inputOptionsIDs = ["y", "z", "u", "v", "w"]
        buttonX.displayLabel.text = "x"
        buttonX.displayType = .Label
        buttonX.delegate = self
        view.addSubview(buttonX)
        
        let buttonA = MuFuKeyboardButton(x: 10.0 + 7.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonA.position = .Inner
        buttonA.inputID = "a"
        buttonA.inputOptionsIDs = ["b", "c", "d", "e", "f"]
        buttonA.displayLabel.text = "a"
        buttonA.displayType = .Label
        buttonA.delegate = self
        view.addSubview(buttonA)
        
        
        let buttonOpen = MuFuKeyboardButton(x: 10.0 + 6.0 * 30.0, y: 80.0, style: .Phone)
        buttonOpen.position = .Inner
        buttonOpen.inputID = "("
        buttonOpen.inputOptionsIDs = ["[", "{"]
        buttonOpen.displayLabel.text = "("
        buttonOpen.displayType = .Label
        buttonOpen.delegate = self
        view.addSubview(buttonOpen)
        
        let buttonClose = MuFuKeyboardButton(x: 10.0 + 7.0 * 30.0, y: 80.0, style: .Phone)
        buttonClose.position = .Inner
        buttonClose.inputID = ")"
        buttonClose.inputOptionsIDs = ["]", "}"]
        buttonClose.displayLabel.text = ")"
        buttonClose.displayType = .Label
        buttonClose.delegate = self
        view.addSubview(buttonClose)
        
        let buttonInsert = MuFuKeyboardButton(x: 10.0 + 8.0 * 30.0, y: 80.0 + 2.0 * 45.0, style: .Phone)
        buttonInsert.frame.size.width = 60.0
        buttonInsert.position = .Inner
        buttonInsert.inputID = "Copy"
        buttonInsert.displayLabel.text = "Copy"
        buttonInsert.showMagnifier = false
        buttonInsert.keyColor = UIColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
        buttonInsert.displayType = .Label
        buttonInsert.delegate = self
        view.addSubview(buttonInsert)
        
        let buttonDelete = MuFuKeyboardButton(x: 10.0 + 9.0 * 30.0, y: 80.0, style: .Phone)
        //buttonDelete.frame.size.width = 40.0
        buttonDelete.position = .Inner
        buttonDelete.inputID = "Delete"
        buttonDelete.displayImageView.image = UIImage(named:"backspace_key")
        buttonDelete.showMagnifier = false
        buttonDelete.keyColor = SPECIAL_BUTTON_BG_COLOR
        buttonDelete.displayType = .Image
        buttonDelete.delegate = self
        view.addSubview(buttonDelete)


        let buttonNext = MuFuKeyboardButton(x: 10.0, y: 10.0, style: .Phone)
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
        
        
        
        
        
        
    }
    
    func handleKeyboardEvent(_ id: String) {
        switch id {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "=", "<", "≤", ">", "≥",  "≠", "≪", "≫", ".", ",", ":", ";", "…", "+", "±", "∓", "-", "×", "∙", "∗", "∘", ":", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "(", ")", "[", "]":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + id + "');", completionHandler: nil)
        case "'":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\prime');", completionHandler: nil)
        case "{", "}":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText(\\'" + id + "');", completionHandler: nil)
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
        case "÷":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('/');", completionHandler: nil)
            //_ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Up');", completionHandler: nil)
            //_ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
        case "Left", "Right", "Up", "Down":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('" + id + "');", completionHandler: nil)
            
        case "Delete":
            _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Backspace')", completionHandler: nil)
            
        case "Copy":
            copyFormulaImage()
            
        default:
            break
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
    
    
    @IBAction func copyFormulaImage() {
        formulaWebView?.evaluateJavaScript("answerMathField.blur();", completionHandler: nil)
        self.perform(#selector(grabWebView), with: nil, afterDelay: 0.5)
        formulaWebView?.evaluateJavaScript("answerMathField.focus();", completionHandler: nil)
    }
    
    func grabWebView() {
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
    
    @IBAction func interrupt() {
        
    }
    
}

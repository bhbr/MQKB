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
        
        return CGRect(x: 0, y: 0, width: CGFloat(widthInt), height: highY + lowY)
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
    
}


class KeyboardViewController: UIInputViewController, UITextViewDelegate {
    
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
        
        containerView.addSubview(formulaWebView!)
        formulaWebView?.frame = containerView.frame
        formulaWebView?.frame.origin = CGPoint(x: 0, y: 0)
        
        
        let localfilePath = Bundle.main.url(forResource: "test", withExtension: "html")
        let myRequest = URLRequest(url: localfilePath!)
        _ = formulaWebView?.load(myRequest)
        
        view.setNeedsDisplay()
        
        myTextView = UITextView()
        myTextView.delegate = self
        
        let myButton = CYRKeyboardButton.init(frame: CGRect(x:50,y:50,width:30,height:45))
        myButton.translatesAutoresizingMaskIntoConstraints = false
        myButton.input = "a"
        myButton.inputOptions = ["a", "b", "&"]
        myButton.textInput = myTextView
        view.addSubview(myButton)
        
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let typedSymbol = textView.text
        _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('" + typedSymbol! + "');", completionHandler: nil)
        myTextView.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    //override func textDidChange(_ textInput: UITextInput?) {
    //    // The app has just changed the document's contents, the document context has been updated.
    //}
    
    @IBAction func buttonTap(button: UIButton!) {
        if let char = button.titleLabel?.text {
            if char == "Left" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Left');", completionHandler: nil)
            } else if char == "Right" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Right');", completionHandler: nil)
            } else if char == "Up" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Up');", completionHandler: nil)
            } else if char == "Down" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Down');", completionHandler: nil)
            } else if char == "Back" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.keystroke('Backspace');", completionHandler: nil)
            } else if char == "√" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.cmd('\\sqrt');", completionHandler: nil)
            } else if char == "0" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('0');", completionHandler: nil)
                
            } else if char == "1" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('1');", completionHandler: nil)
                
            } else if char == "2" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('2');", completionHandler: nil)
                
            } else if char == "3" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('3');", completionHandler: nil)
                
            } else if char == "4" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('4');", completionHandler: nil)
                
            } else if char == "5" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('5');", completionHandler: nil)
                
            } else if char == "6" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('6');", completionHandler: nil)
                
            } else if char == "7" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('7');", completionHandler: nil)
                
            } else if char == "8" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('8');", completionHandler: nil)
                
            } else if char == "9" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('9');", completionHandler: nil)
                
            } else if char == "+" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('+');", completionHandler: nil)
                
            } else if char == "–" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('-');", completionHandler: nil)
                
            } else if char == "*" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('*');", completionHandler: nil)
                
            } else if char == "/" {
                _ = formulaWebView?.evaluateJavaScript("answerMathField.typedText('/');", completionHandler: nil)
            }
        }
        
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
    }
    
    func grabWebView() {
        let formulaImage = image()
        let imageData = UIImagePNGRepresentation(formulaImage)
        let pasteBoard = UIPasteboard.general
        pasteBoard.setData(imageData!, forPasteboardType:"public.image")
        formulaWebView?.evaluateJavaScript("answerMathField.focus();", completionHandler: nil)
        
        if self.isOpenAccessGranted() {
            print("open access")
        } else {
            print("no open access")
        }
    }
    
    func image() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions((formulaWebView?.frame.size)!,false, UIScreen.main.scale)
        let ctx = UIGraphicsGetCurrentContext()
        formulaWebView?.layer.render(in: ctx!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        let trimmedImage = (image?.trim())!
        return trimmedImage
    }
    
    
    
}

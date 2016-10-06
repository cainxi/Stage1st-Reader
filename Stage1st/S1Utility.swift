//
//  S1Utility.swift
//  Stage1st
//
//  Created by Zheng Li on 3/26/16.
//  Copyright © 2016 Renaissance. All rights reserved.
//

import Foundation
import WebKit
import UIKit

func ensureMainThread(_ block: @escaping () -> Void) {
    if Thread.current.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: {
            block()
        })
    }
}

class S1Utility: NSObject {
    class func valuesAreEqual(_ value1: AnyObject?, _ value2: AnyObject?) -> Bool {

        if let value1 = value1, let value2 = value2 {
            return value1.isEqual(value2)
        }
        if value1 == nil && value2 == nil {
            return true
        }
        return false
    }
}

extension Date {
    func s1_gracefulDateTimeString() -> String {
        let interval = -self.timeIntervalSinceNow
        if interval < 60 { return "刚刚" }
        if interval < 60 * 60 { return "\(UInt(interval / 60.0))分钟前" }
        if interval < 60 * 60 * 2 { return "1小时前" }
        if interval < 60 * 60 * 3 { return "2小时前" }
        if interval < 60 * 60 * 4 { return "3小时前" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        if formatter.string(from: self) == formatter.string(from: Date(timeIntervalSinceNow: 0.0)) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        }
        if formatter.string(from: self) == formatter.string(from: Date(timeIntervalSinceNow: -60 * 60 * 24.0)) {
            formatter.dateFormat = "昨天HH:mm"
            return formatter.string(from: self)
        }
        if formatter.string(from: self) == formatter.string(from: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2.0)) {
            formatter.dateFormat = "前天HH:mm"
            return formatter.string(from: self)
        }
        formatter.dateFormat = "yyyy"
        if formatter.string(from: self) == formatter.string(from: Date(timeIntervalSinceNow: 0.0)) {
            formatter.dateFormat = "M-d HH:mm"
            return formatter.string(from: self)
        }
        formatter.dateFormat = "yyyy-M-d HH:mm"
        return formatter.string(from: self)
    }
}

extension UIView {
    func s1_screenShot(rect: CGRect) -> UIImage? {
        // https://chromium.googlesource.com/chromium/src.git/+/46.0.2478.0/ios/chrome/browser/snapshots/snapshot_manager.mm
        func viewHierarchyContainsWKWebView(_ view: UIView) -> Bool {
            if view is WKWebView {
                return true
            }

            for subview in view.subviews {
                if viewHierarchyContainsWKWebView(subview) {
                    return true
                }
            }

            return false
        }

        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }

        if viewHierarchyContainsWKWebView(self) {
            self.drawHierarchy(in: rect, afterScreenUpdates: true)
        } else {
            self.layer.render(in: currentContext)
        }

        let viewScreenShot: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return viewScreenShot
    }

    func s1_screenShot() -> UIImage? {
        return s1_screenShot(rect: self.bounds)
    }
    // TODO:
    //    - (UIImage *)screenShot {
    //    //clip
    //    CGImageRef imageRef = CGImageCreateWithImageInRect([viewImage CGImage], CGRectMake(0.0, 20.0 * viewImage.scale, viewImage.size.width * viewImage.scale, viewImage.size.height * viewImage.scale - 20.0 * viewImage.scale));
    //    viewImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:viewImage.imageOrientation];
    //    CGImageRelease(imageRef);
    //    return viewImage;
    //    }
}

extension UIViewController {
    func s1_presentAlertView(_ title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Message_OK", comment: "OK"), style: .default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated:true, completion:nil)
    }
}

extension UIWebView {
    func s1_positionOfElementWithId(_ elementID: String) -> CGRect? {
        let script = "function f(){ var r = document.getElementById('\(elementID)').getBoundingClientRect(); return '{{'+r.left+','+r.top+'},{'+r.width+','+r.height+'}}'; } f();"
        if let result = self.stringByEvaluatingJavaScript(from: script) {
            let rect = CGRectFromString(result)
            return rect == CGRect.zero ? nil : rect
        } else {
            return nil
        }
    }

    func s1_atBottom() -> Bool {
        let offsetY = self.scrollView.contentOffset.y
        let maxOffsetY = self.scrollView.contentSize.height - self.bounds.size.height
        return offsetY >= maxOffsetY
    }
}

extension WKWebView {
    func s1_atBottom() -> Bool {
        let offsetY = self.scrollView.contentOffset.y
        let maxOffsetY = self.scrollView.contentSize.height - self.bounds.size.height
        return offsetY >= maxOffsetY
    }
}

extension UIImage {
    func s1_tintWithColor(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        color.setFill()
        let rect = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
        UIRectFill(rect)
        self.draw(in: rect, blendMode: .sourceIn, alpha: 1.0)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension CGFloat {
    func limit(_ from: CGFloat, to: CGFloat) -> CGFloat {
        assert(to >= from)
        let result = self < to ? self : to
        return result > from ? result : from
    }
}

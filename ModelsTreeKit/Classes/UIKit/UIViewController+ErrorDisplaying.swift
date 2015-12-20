//
//  UIViewController+ErrorDisplaying.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

//TODO: нужно ли это в ките

import UIKit

public protocol ErrorDisplaying {
    func displayError(error: Error) -> Void
}

extension UIViewController: ErrorDisplaying {
    public func displayError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription(), preferredStyle: .Alert)
        let action = UIAlertAction(title: "ok", style: .Cancel) {[weak self] alert in self?.dismissViewControllerAnimated(true, completion: nil)}
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}

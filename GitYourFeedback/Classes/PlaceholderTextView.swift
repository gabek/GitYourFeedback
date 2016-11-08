//
//  PlaceholderTextView.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 11/8/16.
//
//
// NOTE: This is stealing the UITextView Delegate.  If you need the delegate
// in the future you should proxy the delegate methods from here to those who
// want the callbacks.
//

import Foundation

class PlaceholderTextView: UITextView, UITextViewDelegate {
    
    init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        
        setup()
    }
    
    fileprivate func setup() {
        delegate = self
        addSubview(placeholderLabel)
        placeholderLabel.isHidden = !text.isEmpty
        
        placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
    }
    
    fileprivate let placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Detailed description (optional)"
        label.textColor = UIColor(white: 0, alpha: 0.2)
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !text.isEmpty
    }
 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

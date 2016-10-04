//
//  FeedbackViewController.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/11/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

class FeedbackInterfaceViewController: UIViewController {
    
    var reporter: FeedbackManager?
    
    init(reporter: FeedbackManager?) {
        super.init(nibName: nil, bundle: nil)
        
        self.reporter = reporter
    }
    
    var image: UIImage? {
        didSet {
            imagePreviewButton.setImage(image, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        
        setupConstraints()
        
        stack.addArrangedSubview(emailField)
        stack.addArrangedSubview(titleField)
        stack.addArrangedSubview(bodyField)
        stack.addArrangedSubview(imagePreviewButton)
        stack.addArrangedSubview(footerLabel)
                
        // Navbar
        let bundle = Bundle(for: type(of: self))
        let saveImage = UIImage(named: "save.png", in: bundle, compatibleWith: nil)
        let saveButton = UIBarButtonItem(image: saveImage, style: .plain, target: self, action: #selector(save))
        saveButton.tintColor = UIColor.black
        navigationItem.rightBarButtonItem = saveButton

        let closeImage = UIImage(named: "close.png", in: bundle, compatibleWith: nil)
        let closeButton = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(close))
        closeButton.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = closeButton
        
        title = "Submit Feedback"
        
        handleScreenshot()
        listenForKeyboardNotifications()
        
        populateEmailField()
        imagePreviewButton.addTarget(self, action: #selector(selectNewImage), for: .touchUpInside)
    }
    
    private func handleScreenshot() {
        if !MediaQuery.hasPhotosAccess() {
            MediaQuery.requestPhotosAccess(completionHandler: { (status) in
                if !MediaQuery.hasPhotosAccess() {
                    // Throw error
                    self.showNotification(title: "Photo Access", message: "Access must be granted to the photo library in order to import the screenshot")
                } else {
                    self.handleScreenshot()
                }
            })
            return
        }
        
        MediaQuery.fetchLastImage { (image) in
            OperationQueue.main.addOperation({ 
                if let image = image {
                    self.image = image
                }
            })
        }
    }
    
    func selectNewImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func showNotification(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(vc, animated: true, completion: nil)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        vc.addAction(ok)
    }
    
    private func listenForKeyboardNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: stack.frame.size.height)
    }
    
    private func setupConstraints() {
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        stack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20).isActive = true
        stack.leftAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.rightAnchor).isActive = true
    }
    
    func save() {
        var imageData: Data?
        if let image = image {
            imageData = UIImageJPEGRepresentation(image, 20)
        }
        
        var titleText = "Feedback"
        if let text = titleField.text {
            titleText = "Feedback: \(text)"
        }
        
        var bodyText = "No description"
        if let email = emailField.text {
            bodyText = "From: \(email)"
        }
        
        if let bodyFieldText = bodyField.text {
            bodyText += "\n\n\(bodyFieldText)"
        }
        
        bodyText += Helpers.templateText()
		
		if let additionalDataString = reporter?.datasource?.additionalData?() {
			bodyText += additionalDataString
		}
		
        reporter?.submit(title: titleText, body: bodyText, screenshotData: imageData, completionHandler: { (complete) in
            self.close()
        })
		
		// Save the email address for next time
        Helpers.saveEmail(email: emailField.text)
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let stack: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 10
        return view
    }()
    
    private let titleField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.placeholder = "Short description of issue"
        textField.keyboardType = .asciiCapable
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let emailField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.placeholder = "Your email"
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let bodyField: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        textView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.font = UIFont.systemFont(ofSize: 15)
        return textView
    }()
    
    private let imagePreviewButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let height = button.heightAnchor.constraint(equalToConstant: 200)
        height.priority = 999
        height.isActive = true
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.blue
        button.setTitle("Submit", for: .normal)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.layer.cornerRadius = 5
        return button
    }()
    
    private let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = Helpers.appDisplayVersion()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor(white: 0.8, alpha: 1.0)
        return label
    }()
    
    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == NSNotification.Name.UIKeyboardWillHide {
            scrollView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
    
    private func populateEmailField() {
        let defaults = UserDefaults(suiteName: "com.gabekangas.gityourfeedback")
        if let email = Helpers.email() {
            emailField.text = email
        }
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedbackInterfaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            image = pickedImage
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

class FeedbackViewController: UINavigationController {
    weak var reporter: FeedbackManager?
    
    init(reporter: FeedbackManager) {
        super.init(nibName: nil, bundle: nil)
        
        self.reporter = reporter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControllers = [FeedbackInterfaceViewController(reporter: reporter)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

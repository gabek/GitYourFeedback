//
//  FeedbackViewController.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/11/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit
import CLImageEditor

class FeedbackInterfaceViewController: UIViewController {
    
    fileprivate let bundle = Bundle(for: FeedbackInterfaceViewController.self)
    
    var reporter: FeedbackReporter?
    var shouldFetchScreenshot: Bool
    
    internal init(reporter: FeedbackReporter?, shouldFetchScreenshot: Bool) {
        self.reporter = reporter
        self.shouldFetchScreenshot = shouldFetchScreenshot
        
        super.init(nibName: nil, bundle: nil)
    }
    
    fileprivate var image: UIImage? {
        didSet {
            UIView.transition(with: imagePreviewButton, duration: 0.3, options: .transitionCrossDissolve, animations: {
                
                self.imagePreviewButton.setImage(self.image, for: .normal)
                if self.image == nil {
                    
                    let addPhoto = UIImage(named: "add_photo", in: self.bundle, compatibleWith: nil)
                    self.imagePreviewButton.setImage(addPhoto, for: .normal)
                }
                
                }, completion: nil)

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        
        stack.addArrangedSubview(emailField)
        stack.addArrangedSubview(titleField)
        stack.addArrangedSubview(bodyField)
        stack.addArrangedSubview(footerLabel)
        
        view.addSubview(imagePreviewButton)
        view.addSubview(activitySpinner)
        setupConstraints()
        
        // Navbar
        let saveImage = UIImage(named: "save", in: bundle, compatibleWith: nil)
        
        let saveButton = UIBarButtonItem(image: saveImage, style: .plain, target: self, action: #selector(save))
        saveButton.tintColor = UIColor.black
        navigationItem.rightBarButtonItem = saveButton

        let closeImage = UIImage(named: "close", in: bundle, compatibleWith: nil)
        
        let closeButton = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(close))
        closeButton.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = closeButton
        
        title = "Submit Feedback"
        
        // Set the default image button state
        image = nil

        if shouldFetchScreenshot {
            handleScreenshot()
        }
		
        populateEmailField()
        imagePreviewButton.addTarget(self, action: #selector(imageButtonPressed), for: .touchUpInside)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        if let _ = Helpers.email() {
            titleField.becomeFirstResponder()
        } else {
            emailField.becomeFirstResponder()
        }
    }
    
    private func handleScreenshot() {
        if !MediaQuery.hasPhotosAccess() {
            MediaQuery.requestPhotosAccess(completionHandler: { (status) in
                if !MediaQuery.hasPhotosAccess() {
                    // Throw error
                    self.showNotification(title: "Photo Access", message: "Access must be granted to the photo library in order to import the screenshot")
                    DispatchQueue.main.async {
                        let addPhoto = UIImage(named: "add_photo", in: self.bundle, compatibleWith: nil)
                        self.imagePreviewButton.setImage(addPhoto, for: .normal)
                    }
                } else {
                    self.handleScreenshot()
                }
            })
            return
        }
        
        // This is a hack to fix the fact that getting a screenshot notification
        // does not mean the screenshot has saved yet.  This artificial delay
        // gives iOS the moment required to store the image before we query
        // the image library for it.
        let delayTime = DispatchTime.now() + 0.5
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).asyncAfter(deadline: delayTime) {
            MediaQuery.fetchLastImage { (image) in
                DispatchQueue.main.async {
                    if let image = image {
                        self.image = image
                    } else {
                        let addPhoto = UIImage(named: "add_photo", in: self.bundle, compatibleWith: nil)
                        self.imagePreviewButton.setImage(addPhoto, for: .normal)
                    }
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(vc, animated: true, completion: nil)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        vc.addAction(ok)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: stack.frame.size.height)
        
        let buttonFrame = view.convert(imagePreviewButton.frame, to: bodyField).insetBy(dx: -10, dy: -10)
        let exclusionPath = UIBezierPath(rect: buttonFrame)
        bodyField.textContainer.exclusionPaths = [exclusionPath]
    }
    
    private func setupConstraints() {
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        stack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 20).isActive = true
        stack.leftAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.rightAnchor).isActive = true
        
        imagePreviewButton.trailingAnchor.constraint(equalTo: bodyField.trailingAnchor, constant: -8).isActive = true
        imagePreviewButton.bottomAnchor.constraint(equalTo: bodyField.bottomAnchor, constant: -8).isActive = true
        
        bodyField.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true

        activitySpinner.centerXAnchor.constraint(equalTo: bodyField.centerXAnchor).isActive = true
        activitySpinner.centerYAnchor.constraint(equalTo: bodyField.centerYAnchor).isActive = true
    }
    
    // MARK: - Actions
    
    private func selectNewImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func showImageOptions() {
        let actionSheet = UIAlertController(title: "Screenshot", message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            let editor = CLImageEditor(image: self.image, delegate: self)!
            editor.setup()
            self.present(editor, animated: true, completion: nil)
        }
        actionSheet.addAction(editAction)

        let replaceAction = UIAlertAction(title: "Replace", style: .default) { (action) in
            self.selectNewImage()
        }
        actionSheet.addAction(replaceAction)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { (action) in
            self.image = nil
        }
        actionSheet.addAction(removeAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            // No action needed...
        }
        actionSheet.addAction(cancelAction)

        
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc private func imageButtonPressed() {
        if image == nil {
            selectNewImage()
        } else {
            showImageOptions()
        }
    }
    
    @objc private func save() {
		
        guard let titleText = titleField.text else {
            showRequiredFieldAlert()
            return
        }
        
        guard let emailText = emailField.text else {
            showRequiredFieldAlert()
            return
        }
        
        // Validate that we have a title and a valid email adddress
		if titleText.isEmpty || !emailText.isValidEmail {
            showRequiredFieldAlert()
            return
		}
				
        activitySpinner.startAnimating()
        
        var imageData: Data?
        if let image = image {
            let resizedImage = image.resizeToUploadingSize()
            imageData = resizedImage.jpegData(compressionQuality: 20)
        }
        
        reporter?.submit(title: titleText, body: bodyField.text, email: emailText, screenshotData: imageData, completionHandler: { (result) in
            do {
                _ = try result.resolve()
                self.close()
            } catch GitYourFeedbackError.GithubSaveError(let errorMessage) {
                self.handleError(title: "Error saving to GitHub", errorMessage: errorMessage)
            } catch GitYourFeedbackError.ImageUploadError(let errorMessage) {
                let message = "The image could not be uploaded.  Try again or remove the image.  \(errorMessage)"
                self.handleError(title: "Error uploading image", errorMessage: message)
            } catch {
                self.handleError(title: "Error", errorMessage: error.localizedDescription)
            }
            
        })
		
		// Save the email address for next time
        Helpers.saveEmail(email: emailField.text)
    }
    
    private func showRequiredFieldAlert() {
        let alert = UIAlertController(title: "Information Required", message: "Your email address and a description is required.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func close() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func handleError(title: String, errorMessage: String) {
        let vc = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        vc.addAction(ok)
        
        present(vc, animated: true, completion: nil)
        stopActivitySpinner()
    }
    
    @objc private func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }

        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
    // MARK - Views
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
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
        let textView = PlaceholderTextView()
        textView.isScrollEnabled = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        
        return textView
    }()
    
    private let imagePreviewButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let height = button.heightAnchor.constraint(equalToConstant: 80)
        height.priority = UILayoutPriority(rawValue: 999)
        height.isActive = true
        
        let width = button.widthAnchor.constraint(equalToConstant: 80)
        width.priority = UILayoutPriority(rawValue: 999)
        width.isActive = true
        
        button.imageView?.contentMode = .scaleAspectFill
        
        button.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        button.layer.borderWidth = 1

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
    
    private let activitySpinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private func populateEmailField() {
        if let email = Helpers.email() {
            emailField.text = email
        }
    }
    
    internal func stopActivitySpinner() {
        activitySpinner.stopAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedbackInterfaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            image = pickedImage
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension FeedbackInterfaceViewController: CLImageEditorDelegate {
    func imageEditor(_ editor: CLImageEditor!, didFinishEdittingWith image: UIImage!) {
        self.image = image
        editor.dismiss(animated: true, completion: nil)
    }
}

class FeedbackViewController: UINavigationController {
    
    weak var reporter: FeedbackReporter?
    var shouldFetchScreenshot: Bool
    
    init(reporter: FeedbackReporter, shouldFetchScreenshot: Bool = false) {
        self.reporter = reporter
        self.shouldFetchScreenshot = shouldFetchScreenshot
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let navigationTitleFont = UIFont.systemFont(ofSize: 18, weight: .thin)
		navigationBar.titleTextAttributes = [.font: navigationTitleFont]
		navigationBar.barTintColor = UIColor.white
        
        viewControllers = [FeedbackInterfaceViewController(reporter: reporter, shouldFetchScreenshot: shouldFetchScreenshot)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

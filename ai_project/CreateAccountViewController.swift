
import Foundation

import UIKit

class CreateAccountViewController: UIViewController {

    // MARK: - UI Components

    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocapitalizationType = .none
        return tf
    }()

    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let password1TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let password2TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Account", for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let viewModel = CreateAccountViewModel()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    // MARK: - Setup UI

    func setupUI() {
        view.addSubview(emailTextField)
        view.addSubview(usernameTextField)
        view.addSubview(password1TextField)
        view.addSubview(password2TextField)
        view.addSubview(createAccountButton)

        NSLayoutConstraint.activate([
            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            emailTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),

            usernameTextField.centerXAnchor.constraint(equalTo: emailTextField.centerXAnchor),
            usernameTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            usernameTextField.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            usernameTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            password1TextField.centerXAnchor.constraint(equalTo: emailTextField.centerXAnchor),
            password1TextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            password1TextField.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            password1TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            password2TextField.centerXAnchor.constraint(equalTo: emailTextField.centerXAnchor),
            password2TextField.topAnchor.constraint(equalTo: password1TextField.bottomAnchor, constant: 20),
            password2TextField.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            password2TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            createAccountButton.centerXAnchor.constraint(equalTo: emailTextField.centerXAnchor),
            createAccountButton.topAnchor.constraint(equalTo: password2TextField.bottomAnchor, constant: 30),
            createAccountButton.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            createAccountButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc func createAccountTapped() {
        guard let email = emailTextField.text,
              let username = usernameTextField.text,
              let password1 = password1TextField.text,
              let password2 = password2TextField.text else {
            return
        }

        guard password1 == password2 else {
            print("Passwords do not match")
            return
        }
        
        viewModel.CreateAccount(
            username: username,
            email: email,
            password1: password1,
            password2: password2)

        // TODO: Call ViewModel or API to create account
        print("Creating account for \(username) with email \(email)")
    }
}

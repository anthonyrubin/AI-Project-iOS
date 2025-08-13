
import Foundation

import UIKit

class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    var email: String? = nil
    // MARK: - UI Components
    let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false

        tf.keyboardType = .emailAddress
        tf.textContentType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()

    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .username
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let password1TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.textContentType = .password
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let password2TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.textContentType = .password
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let createAccountButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Create Account"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let viewModel = CreateAccountViewModel()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        setupUI()
        viewModel.onCreateAccountFailure = ({ [weak self] response in
            print("Create Account Failure")
            self?.setLoading(false)
        })
        
        viewModel.onCreateAccountSuccess = ({ [weak self] in
            print("Create Account Success")
            self?.setLoading(false)
            let vc = VerifyAccountViewController(email: self!.email!)
            self?.navigationController?.pushViewController(vc, animated: true)
            print("Pushed view controller")
            
        })
        usernameTextField.delegate = self
        password2TextField.delegate = self
        password1TextField.delegate = self
    }

    // MARK: - Setup UI

    func setupUI() {
        view.addSubview(topLabel)
        view.addSubview(emailTextField)
        view.addSubview(usernameTextField)
        view.addSubview(password1TextField)
        view.addSubview(password2TextField)
        view.addSubview(createAccountButton)

        NSLayoutConstraint.activate([
            
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topLabel.heightAnchor.constraint(equalToConstant: 44),
            
            emailTextField.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),

            usernameTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            usernameTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            usernameTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            usernameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            password1TextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            password1TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            password1TextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            password1TextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            password2TextField.topAnchor.constraint(equalTo: password1TextField.bottomAnchor, constant: 20),
            password2TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            password2TextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            password2TextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            createAccountButton.topAnchor.constraint(equalTo: password2TextField.bottomAnchor, constant: 30),
            createAccountButton.heightAnchor.constraint(equalToConstant: 50),
            createAccountButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            createAccountButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])

        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc func createAccountTapped() {
        email = emailTextField.text
        setLoading(true)
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
            password2: password2
        )

    }
    
    // call when starting/ending the API request
    func setLoading(_ loading: Bool) {
        var c = createAccountButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Create Account"   // spinner only while loading
        createAccountButton.configuration = c
        createAccountButton.isEnabled = !loading
    }

}

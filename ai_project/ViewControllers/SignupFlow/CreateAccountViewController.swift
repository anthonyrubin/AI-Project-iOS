import Foundation
import UIKit
import Combine

final class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Deps
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    private let viewModel = CreateAccountViewModel(
        signupRepository: SignupRepositoryImpl(
            signupAPI: NetworkManager(
                tokenManager: TokenManager()
            ),
            userDataStore: RealmUserDataStore(),
        )
    )
    private var cancellables = Set<AnyCancellable>()
    var email: String?

    // MARK: - UI

    private let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Email
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.textContentType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let emailErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var emailStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [emailTextField, emailErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Username
    private let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .username
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let usernameErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var usernameStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [usernameTextField, usernameErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Password
    private let password1TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.textContentType = .newPassword
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let password1ErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var password1Stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [password1TextField, password1ErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Confirm Password
    private let password2TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.textContentType = .newPassword
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let password2ErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var password2Stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [password2TextField, password2ErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Parent stack to hold all field stacks
    private lazy var fieldsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [emailStack, usernameStack, password1Stack, password2Stack])
        s.axis = .vertical
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let createAccountButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        b.isEnabled = false
        c.title = "Create Account"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        setupUI()
        setupViewModelBindings()
        usernameTextField.delegate = self
        password1TextField.delegate = self
        password2TextField.delegate = self
        let textFields = [
            emailTextField,
            usernameTextField,
            password1TextField,
            password2TextField
        ]
        textFields.forEach({ textField in
            textField.addTarget(self, action: #selector(onFieldChanged(_:)), for: .editingChanged)
        })
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(topLabel)
        view.addSubview(fieldsStack)
        view.addSubview(createAccountButton)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topLabel.heightAnchor.constraint(equalToConstant: 44),

            fieldsStack.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
            fieldsStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            fieldsStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            usernameTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            password1TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            password2TextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),

            createAccountButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 30),
            createAccountButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            createAccountButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            createAccountButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    
    
    @objc private func onFieldChanged(_ sender: UITextField) {


        if sender === emailTextField {
           clearEmailError()
        } else if sender === usernameTextField {
            clearUsernameError()
        } else if sender === password1TextField {
            clearPassword1Error()
        } else if sender === password2TextField {
            clearPassword2Error()
        }

        updateCreateButtonEnabled()
    }

    @objc private func createAccountTapped() {
        email = emailTextField.text
        
        if !isValidEmail(email ?? "") {
            showEmailError("Email is not valid")
            return
        }
        
        if email!.hasAnyWhitespace() {
            showEmailError("Email cannot contain any spaces")
            return
        }
        
        if usernameTextField.text?.hasAnyWhitespace() == true {
            showUsernameError("Username cannot contain any spaces")
            return
        }
        
        if password1TextField.text?.hasAnyWhitespace() == true {
            showPassword1Error("Password cannot contain any spaces")
            return
        }
        
        if password2TextField.text?.hasAnyWhitespace() == true {
            showPassword2Error("Password cannot contain any spaces")
            return
        }
        
        guard
            let email = emailTextField.text,
            let username = usernameTextField.text,
            let password1 = password1TextField.text,
            let password2 = password2TextField.text
        else { return }

        guard password1 == password2 else {
            showPassword2Error("Passwords do not match")
            return
        }
        clearPassword2Error()

        viewModel.createAccount(
            username: username,
            email: email,
            password1: password1,
            password2: password2
        )
    }

    // MARK: - ViewModel Bindings

    private func setupViewModelBindings() {
        // Loading
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in self?.setLoading(isLoading) }
            .store(in: &cancellables)

        // General error
        viewModel.$modalError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                if let msg = msg {
                    self?.errorModalManager.showError(msg)
                    self?.viewModel.clearModalError()
                    self?.viewModel.clearFieldError()
                }
            }
            .store(in: &cancellables)

        // Field-specific API errors (expects .apiError with field name)
        viewModel.$networkError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] netErr in
                guard let self else { return }
                guard case .apiError(let apiError)? = netErr, let field = apiError.field else { return }
                switch field {
                case "email": self.showEmailError(apiError.message)
                case "username": self.showUsernameError(apiError.message)
                case "password1": self.showPassword1Error(apiError.message)
                case "password2": self.showPassword2Error(apiError.message)
                default: break
                }
            }
            .store(in: &cancellables)

        // Success
        viewModel.$isAccountCreated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ok in
                guard let self, ok else { return }
                if let email = self.email {
                    let vc = VerifyAccountViewController(email: email)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                self.viewModel.resetAccountCreated()
            }
            .store(in: &cancellables)
    }

    // MARK: - Field Error Helpers
    
    private func updateCreateButtonEnabled() {
        let hasEmail = !(emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasUsername = !(usernameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPassword1 = !(password1TextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPassword2 = !(password2TextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        createAccountButton.isEnabled = !viewModel.isLoading && hasEmail && hasUsername && hasPassword1 && hasPassword2
    }

    private func setFieldError(label: UILabel, textField: UITextField, message: String?) {
        if let message, !message.isEmpty {
            label.text = message
            label.isHidden = false
            textField.layer.borderColor = UIColor.systemRed.cgColor
            textField.layer.borderWidth = 1.0
            textField.layer.cornerRadius = 5
        } else {
            label.text = nil
            label.isHidden = true
            textField.layer.borderColor = UIColor.clear.cgColor
            textField.layer.borderWidth = 0.0
        }
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    private func showEmailError(_ msg: String)      { setFieldError(label: emailErrorLabel,     textField: emailTextField,     message: msg) }
    private func clearEmailError()                   { setFieldError(label: emailErrorLabel,     textField: emailTextField,     message: nil) }
    private func showUsernameError(_ msg: String)    { setFieldError(label: usernameErrorLabel,  textField: usernameTextField,  message: msg) }
    private func clearUsernameError()                { setFieldError(label: usernameErrorLabel,  textField: usernameTextField,  message: nil) }
    private func showPassword1Error(_ msg: String)   { setFieldError(label: password1ErrorLabel, textField: password1TextField, message: msg) }
    private func clearPassword1Error()               { setFieldError(label: password1ErrorLabel, textField: password1TextField, message: nil) }
    private func showPassword2Error(_ msg: String)   { setFieldError(label: password2ErrorLabel, textField: password2TextField, message: msg) }
    private func clearPassword2Error()               { setFieldError(label: password2ErrorLabel, textField: password2TextField, message: nil) }

    // MARK: - Loading Button State

    private func setLoading(_ loading: Bool) {
        var c = createAccountButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Create Account"
        createAccountButton.configuration = c
        updateCreateButtonEnabled()
    }
    
    private func isValidEmail(_ input: String) -> Bool {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, s.count <= 254 else { return false }       // length sanity

        // Basic quick rejects
        if s.hasPrefix("." ) || s.hasSuffix(".") || s.contains("..") { return false }
        guard s.contains("@") else { return false }

        // Require at least one dot in the domain part (pragmatic constraint)
        let parts = s.split(separator: "@", maxSplits: 1)
        guard parts.count == 2, parts[1].contains(".") else { return false }

        // Let NSDataDetector decide if it's an email
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let range = NSRange(s.startIndex..<s.endIndex, in: s)
            guard let match = detector.firstMatch(in: s, options: [], range: range),
                  match.range == range,
                  match.url?.scheme == "mailto" else {
                return false
            }
            return true
        } catch {
            return false
        }
    }
}

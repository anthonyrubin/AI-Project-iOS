import UIKit

class LoginViewController: UIViewController {

    // MARK: - UI Components

    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create New Account", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    // ViewModel instance
    private let viewModel = LoginViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupViewModelBindings()
    }

    // MARK: - Setup UI

    func setupUI() {
        // Add subviews
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(createAccountButton)  // NEW


        // Constraints
        NSLayoutConstraint.activate([
            // Username TextField
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            usernameTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),

            // Password TextField
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            passwordTextField.widthAnchor.constraint(equalTo: usernameTextField.widthAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: usernameTextField.heightAnchor),

            // Login Button
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.widthAnchor.constraint(equalTo: usernameTextField.widthAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15)
        ])

        // Button Action
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside) // NEW

    }

    // MARK: - ViewModel Bindings

    func setupViewModelBindings() {
        viewModel.onLoginSuccess = { user in
            print("Logged in")
            // Navigate to next screen
            let uploadVC = UploadImageViewController()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(uploadVC, animated: true)
            }
        }

        viewModel.onLoginFailure = { error in
            print("Login failed: \(error)")
            // Show alert if needed
        }
    }

    // MARK: - Actions

    @objc func loginButtonTapped() {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else {
            return
        }

        viewModel.login(username: username, password: password)
    }
    
    @objc func createAccountTapped() {
        let createAccountVC = CreateAccountViewController()
        print(navigationController)
        navigationController?.pushViewController(createAccountVC, animated: true)
    }

}

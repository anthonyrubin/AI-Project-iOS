import UIKit
import Combine

class LoginViewController: UIViewController {
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
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
    private let viewModel = LoginViewModel(
        authRepository: AuthRepositoryImpl(
            authAPI: NetworkManager(
                tokenManager: TokenManager(),
                userService: UserService()
            ),
            tokenManager: TokenManager(),
            realmUserDataStore: RealmUserDataStore()
        )
    )
    private var cancellables = Set<AnyCancellable>()

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
        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.loginButton.isEnabled = !isLoading
                if isLoading {
                    self?.loginButton.configuration?.showsActivityIndicator = true
                } else {
                    self?.loginButton.configuration?.showsActivityIndicator = false
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorModalManager.showError(errorMessage)
                    self?.viewModel.clearError()
                }
            }
            .store(in: &cancellables)
        
        // Bind navigation states
        viewModel.$email
            .receive(on: DispatchQueue.main)
            .sink { [weak self] email in
                if !email.isEmpty {
                    self?.navigateToVerify()
                    self?.viewModel.resetNavigationFlags()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$shouldNavigateToName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToName()
                    self?.viewModel.resetNavigationFlags()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$shouldNavigateToBirthday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToBirthday()
                    self?.viewModel.resetNavigationFlags()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$shouldNavigateToHome
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldNavigate in
                if shouldNavigate {
                    self?.navigateToHome()
                    self?.viewModel.resetNavigationFlags()
                }
            }
            .store(in: &cancellables)
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
        navigationController?.pushViewController(createAccountVC, animated: true)
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToVerify() {
        let vc = VerifyAccountViewController(email: viewModel.email)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToName() {
        let vc = SetNameViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToBirthday() {
        let vc = SetBirthdayViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToHome() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        NotificationCenter.default.post(name: .authDidSucceed, object: nil)
    }

}

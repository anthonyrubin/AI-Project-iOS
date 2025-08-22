import UIKit
import Combine
import AuthenticationServices // Added for Apple Sign-In

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
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Login"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create New Account", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Social Login Buttons
    let googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Continue with Google"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "globe")
        config.imagePadding = 8
        button.configuration = config
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // ViewModel instance
    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        let socialLoginManager = SocialLoginManager(
            googleClientID: "YOUR_GOOGLE_CLIENT_ID", // Replace with actual client ID
            appleClientID: "YOUR_APPLE_CLIENT_ID"    // Replace with actual client ID
        )
        
        self.viewModel = LoginViewModel(
            authRepository: AuthRepositoryImpl(
                authAPI: NetworkManager(
                    tokenManager: TokenManager()
                ),
                tokenManager: TokenManager(),
                realmUserDataStore: RealmUserDataStore()
            ),
            socialLoginManager: socialLoginManager
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupViewModelBindings()
        hideNavBarHairline()
    }

    // MARK: - Setup UI

    func setupUI() {
        // Add subviews
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(createAccountButton)
        view.addSubview(googleSignInButton)
        view.addSubview(appleSignInButton)
        view.addSubview(orLabel)


        // Constraints
        NSLayoutConstraint.activate([
            // Username TextField
            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
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
            createAccountButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15),
            
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.topAnchor.constraint(equalTo: createAccountButton.bottomAnchor, constant: 20),
            googleSignInButton.widthAnchor.constraint(equalTo: usernameTextField.widthAnchor),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            appleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleSignInButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
            appleSignInButton.widthAnchor.constraint(equalTo: usernameTextField.widthAnchor),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orLabel.topAnchor.constraint(equalTo: appleSignInButton.bottomAnchor, constant: 20)
        ])

        // Button Action
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        appleSignInButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
    }

    // MARK: - ViewModel Bindings

    func setupViewModelBindings() {
        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
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
    
    private func setLoading(_ loading: Bool) {
        var c = loginButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Login"
        loginButton.configuration = c
        loginButton.isEnabled = !loading
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
    
    @objc func googleSignInTapped() {
        viewModel.signInWithGoogle()
    }
    
    @objc func appleSignInTapped() {
        viewModel.signInWithApple()
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

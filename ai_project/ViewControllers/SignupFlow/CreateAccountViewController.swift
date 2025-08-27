import Foundation
import UIKit
import Combine
import AuthenticationServices

final class CreateAccountViewController: BaseSignupViewController {
    
    // The screen before this is the StartAnalysisViewController where ther uer can submit
    // a video to be analyzed during the signup flow. However, they can also skip this step.
    // This boolean indicates whether or not they submitted a video for analysis during signup
    private var didUploadVideoForAnalysis = false
    
    init(didUploadVideoForAnalysis: Bool) {
        self.didUploadVideoForAnalysis = didUploadVideoForAnalysis
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    
    let viewModel = CreateAccountViewModel(
        authRepository: AuthRepositoryImpl(
            authAPI: NetworkManager(tokenManager: TokenManager()),
            tokenManager: TokenManager(),
            realmUserDataStore: RealmUserDataStore()
        ),
        socialLoginManager: SocialLoginManager()
    )

    
    private lazy var loadingOverlay = LoadingOverlay()
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    private var cancellables = Set<AnyCancellable>()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.text = "Get tailored insights in seconds. Your data stays secure and private."
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Continue with Google"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        config.image = UIImage(named: "GoogleIcon")
        config.imagePadding = 8
        button.configuration = config
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let disclaimerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.text = "By continuing, you agree to our Terms & Conditions and Privacy Policy."
        return l
    }()

    private lazy var stack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [googleSignInButton, appleSignInButton, disclaimerLabel])
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 15
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    override func viewDidLoad() {
        killDefaultLayout = true
        super.viewDidLoad()
        buildUI()
        setProgress(0.55, animated: false)
        wireActions()
    }
    
    func buildUI() {
        if didUploadVideoForAnalysis {
            titleLabel.text = "Create an account to start your analysis"
        } else {
            titleLabel.text = "Create an account to begin your coaching journey"
        }
    }
    
    override func layout() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stack)
        super.layout()
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }
    
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
//        viewModel.$email
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] email in
//                if !email.isEmpty {
//                    self?.navigateToVerify()
//                    self?.viewModel.resetNavigationFlags()
//                }
//            }
//            .store(in: &cancellables)
        
        viewModel.$checkpoint
            .receive(on: DispatchQueue.main)
            .sink { [weak self] checkpoint in
                if let _checkpoint = checkpoint {
                    self?.handleCheckpoint(checkpoint: _checkpoint)
                    self?.viewModel.resetNavigationFlags()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleCheckpoint(checkpoint: Checkpoint) {
        switch checkpoint {
        case .name:
            navigateToName()
        case .birthday:
            navigateToBirthday()
        case .home:
            navigateToHome()
        case .verify_code:
            break
        }
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
    
    private func setLoading(_ loading: Bool) {
        (navigationController ?? self).isModalInPresentation = loading
        navigationItem.rightBarButtonItem?.isEnabled = !loading
        loading ? loadingOverlay.show(in: navigationController!.view) : loadingOverlay.hide()
        
        // disable the close button
        navigationItem.rightBarButtonItem?.isEnabled = !loading

        // hard block swipe-to-dismiss too, even though the
        // presentationControllerShouldDismiss function should do this
        (navigationController ?? self).isModalInPresentation = loading
    }

    @objc func googleSignInTapped() {
        viewModel.signInWithGoogle()
    }
    
    @objc func appleSignInTapped() {
        viewModel.signInWithApple()
    }

    private func wireActions() {
        googleSignInButton.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        appleSignInButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
    }
}

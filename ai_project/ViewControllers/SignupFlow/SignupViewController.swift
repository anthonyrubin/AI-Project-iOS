import UIKit
import AuthenticationServices
import Combine

final class SignupViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    private lazy var loadingOverlay = LoadingOverlay()
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    
    let viewModel = SignupViewModel(
        authRepository: AuthRepositoryImpl(
            authAPI: NetworkManager(tokenManager: TokenManager()),
            tokenManager: TokenManager(),
            realmUserDataStore: RealmUserDataStore()
        ),
        socialLoginManager: SocialLoginManager()
    )

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
        wireActions()
        setupNavBar()
        setupViewModelBindings()
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !viewModel.isLoading
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
    
    private func setupNavBar() {
        title = "Sign In"
        // Create a UIButton
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.applyTactileTap()
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        // Wrap in UIBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor.separator        // this draws the hairline
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    
    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),

            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
    
    private func handleCheckpoint(checkpoint: Checkpoint) {
        dismissSelf()
        switch checkpoint {
        case .name:
            navigateToName()
        case .birthday:
            navigateToBirthday()
        case .home:
            navigateToHome()
        case .verify_code:
            break
        case .videoAnalysis:
            fatalError("Video analysis should never be an option from here")

        }
    }
    
    private func navigateToName() {
//        let vc = SetNameViewController()
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToBirthday() {
        let vc = BirthdayViewController()
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

    // MARK: - Actions
    
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

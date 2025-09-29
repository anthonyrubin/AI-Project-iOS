import Foundation
import UIKit
import Combine
import AuthenticationServices

final class CreateAccountViewController: BaseSignupViewController {

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
        button.applyTactileTap()
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
        setProgress(1.0, animated: false)
        
        // Debug: Print current signup data
        UserDefaultsManager.shared.debugPrintSignupData()
        wireActions()
        
        setupViewModelBindings()
    }
    
    func buildUI() {
        if UserDefaultsManager.shared.getDidUploadVideo() {
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
        case .home:
            navigateToHome()
        case .videoAnalysis:
            navigateToVideoAnalysis()
        case .startSignupFlow:
            fatalError("Unable to handle startSignupFlow checkpoint from CreateAccountViewController")
        }
    }
    
    private func navigateToBirthday() {
        let vc = BirthdayViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToHome() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        NotificationCenter.default.post(name: .authDidSucceed, object: nil)
    }
    
    private func navigateToVideoAnalysis() {
        // Get video data from UserDefaults
        let (videoURL, videoSnapshot, liftType) = UserDefaultsManager.shared.getVideoData()
        
        guard let videoURL = videoURL else {
            print("❌ No video URL found for analysis")
            navigateToHome()
            return
        }
        
        guard let liftType = liftType else {
            fatalError("Lift type is nil")
        }
        
        UserDefaultsManager.shared.completeSignupSession()

        
        // Navigate to video analysis loading screen
        let videoAnalysisVC = VideoAnalysisLoadingViewController(
            videoURL: videoURL,
            videoSnapshot: videoSnapshot,
            liftType: liftType
        )
        navigationController?.pushViewController(videoAnalysisVC, animated: true)
    }
    
    private func setLoading(_ loading: Bool) {
        (navigationController ?? self).isModalInPresentation = loading
        navigationItem.rightBarButtonItem?.isEnabled = !loading
        loading ? loadingOverlay.show(in: navigationController!.view) : loadingOverlay.hide()
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

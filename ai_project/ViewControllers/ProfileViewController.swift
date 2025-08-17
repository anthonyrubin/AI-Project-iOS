import Foundation
import UIKit
import Combine

class ProfileViewController: UIViewController {
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    // MARK: - UI Components
    let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Logout"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - ViewModel
    private let viewModel = ProfileViewModel(
        networkManager: NetworkManager(
            tokenManager: TokenManager(),
            userService: UserService()),
        userService: UserService()
        
    )
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        setupUI()
        setupBindings()
    }

    func setupUI() {
        view.addSubview(topLabel)
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topLabel.heightAnchor.constraint(equalToConstant: 44),

            logoutButton.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            logoutButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])

        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    }


    private func setupBindings() {
        // Bind loading state to button
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.logoutButton.isEnabled = !isLoading
                if isLoading {
                    self?.logoutButton.configuration?.showsActivityIndicator = true
                } else {
                    self?.logoutButton.configuration?.showsActivityIndicator = false
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
    }
    
    @objc func logoutButtonTapped() {
        viewModel.logout()
    }
    
    deinit {
        cancellables.removeAll()
    }

    // loading also locks the button
//    func setLoading(_ loading: Bool) {
//        isLoading = loading
//        var c = nextButton.configuration ?? .filled()
//        c.showsActivityIndicator = loading
//        c.title = loading ? nil : "Next"
//        nextButton.configuration = c
//        updateNextEnabled()
//    }
}

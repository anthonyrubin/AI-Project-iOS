import UIKit
import Combine

final class SetBirthdayViewController: UIViewController {
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "What's Your Birthday?"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.maximumDate = Date()              // no future dates
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    private let nextButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Next"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let viewModel = SetBirthdayViewModel(
        signupRepository: SignupRepositoryImpl(
            signupAPI: NetworkManager(tokenManager: TokenManager()),
            userDataStore: RealmUserDataStore()
        )
    )
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViewModelBindings()

        view.addSubview(titleLabel)
        view.addSubview(datePicker)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nextButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 30),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func setupViewModelBindings() {
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
        
        // Bind name set success
        viewModel.$isBirthdaySet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBirthdaySet in
                if isBirthdaySet {
                    self?.finishOnboarding()
                }
            }
            .store(in: &cancellables)
    }

    @objc private func nextButtonTapped() {
        let birthday = datePicker.date
        
        // Save to UserDefaults before making API call
        UserDefaultsManager.shared.updateBasicInfo(birthday: birthday)
        
        setLoading(true)
        viewModel.setBirthday(birthday: birthday)
    }
    
    private func finishOnboarding() {
        // mark logged in (your SceneDelegate checks this at launch)
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.synchronize()

        // tell SceneDelegate to mount the tab bar and drop the signup flow
        NotificationCenter.default.post(name: .authDidSucceed, object: nil)
    }

    private func setLoading(_ loading: Bool) {
        var c = nextButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Save"
        nextButton.configuration = c
        nextButton.isEnabled = !loading
        datePicker.isEnabled = !loading
    }
}

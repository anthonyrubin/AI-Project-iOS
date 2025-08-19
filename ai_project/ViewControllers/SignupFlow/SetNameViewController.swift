import UIKit
import Combine

class SetNameViewController: UIViewController {

    private let viewModel = SetNameViewModel(
        signupRepository: SignupRepositoryImpl(
            signupAPI: NetworkManager(tokenManager: TokenManager()),
            userDataStore: RealmUserDataStore()
        )
    )
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    let topLabel: UILabel = {
        let label = UILabel()
        label.text = "What's Your Name?"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let firstNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "First Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.keyboardType = .default
        tf.textContentType = .givenName
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()
    
    private let firstNameErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var firstNameStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [firstNameTextField, firstNameErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    let lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Last Name"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textContentType = .familyName
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let lastNameErrorLabel: UILabel = {
        let l = UILabel()
        l.text = nil
        l.font = .systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var lastNameStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [lastNameTextField, lastNameErrorLabel])
        s.axis = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private lazy var fieldsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [firstNameStack, lastNameStack])
        s.axis = .vertical
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    let nextButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Next"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isEnabled = false                               // start disabled
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        setupUI()
        setupViewModelBindings()

        // update state on text change
        firstNameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        lastNameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        updateNextEnabled()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    func setupUI() {
        view.addSubview(topLabel)
        view.addSubview(fieldsStack)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topLabel.heightAnchor.constraint(equalToConstant: 44),

            fieldsStack.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
            fieldsStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            fieldsStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            firstNameTextField.heightAnchor.constraint(equalToConstant: 44),
            lastNameTextField.heightAnchor.constraint(equalTo: firstNameTextField.heightAnchor),

            nextButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 30),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])

        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }

    @objc private func textDidChange() {
        updateNextEnabled()
    }

    private func updateNextEnabled() {
        let hasFirst = !(firstNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLast  = !(lastNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        nextButton.isEnabled = !viewModel.isLoading && hasFirst && hasLast
    }

    @objc func nextButtonTapped() {
        guard let firstName = firstNameTextField.text,
              let lastName = lastNameTextField.text else { return }
        viewModel.setName(firstName: firstName, lastName: lastName)
    }
    
    // MARK: - ViewModel Bindings
    
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
        viewModel.$isNameSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isNameSet in
                if isNameSet {
                    let vc = SetBirthdayViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                    self?.viewModel.resetNameSet()
                }
            }
            .store(in: &cancellables)
    }

    // loading also locks the button
    func setLoading(_ loading: Bool) {
        var c = nextButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Next"
        nextButton.configuration = c
        updateNextEnabled()
    }
}

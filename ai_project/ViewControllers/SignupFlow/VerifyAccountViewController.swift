import UIKit
import Combine

// Minimal addition: detect backspace on an empty box so we can move left.
final class OTPTextField: UITextField {
    var onDeleteBackward: (() -> Void)?
    override func deleteBackward() {
        let wasEmpty = (text ?? "").isEmpty
        super.deleteBackward()
        if wasEmpty { onDeleteBackward?() }
    }
}

final class VerifyAccountViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Inputs
    private let email: String
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private let viewModel = VerifyAccountViewModel(
        networkManager: NetworkManager(
            tokenManager: TokenManager(),
            userService: UserService()
        )
    )
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "We sent you a code"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Modified: use OTPTextField instead of UITextField
    private lazy var codeFields: [OTPTextField] = (0..<6).map { _ in
        let tf = OTPTextField()
        tf.delegate = self
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 24, weight: .semibold)
        tf.keyboardType = .numberPad
        tf.textContentType = .oneTimeCode
        tf.layer.cornerRadius = 8
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.separator.cgColor
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.widthAnchor.constraint(equalToConstant: 48).isActive = true
        tf.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return tf
    }

    private lazy var stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: codeFields)
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .equalSpacing
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let resendButton: UIButton = {
        var c = UIButton.Configuration.plain()
        c.title = "Get a new code"
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let continueButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Continue"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.isEnabled = false
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavBarHairline()
        setupViewModelBindings()
        
        view.backgroundColor = .systemBackground
        let tap = UITapGestureRecognizer(target: self, action: #selector(focusFirstEditableBox))
        tap.cancelsTouchesInView = false
        stack.addGestureRecognizer(tap)

        // subtitle with dynamic email
        let text = "Please enter the 6-digit code we sent to \(email)"
        let att = NSMutableAttributedString(string: text)
        if let r = text.range(of: email) {
            let nsr = NSRange(r, in: text)
            att.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: nsr)
        }
        subtitleLabel.attributedText = att

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stack)
        view.addSubview(resendButton)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            stack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            resendButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            resendButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            continueButton.topAnchor.constraint(equalTo: resendButton.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)
//        resendButton.addTarget(self, action: #selector(tapResend), for: .touchUpInside)

        // Wire delete-left behavior
        for tf in codeFields {
            tf.onDeleteBackward = { [weak self, weak tf] in
                guard
                    let self = self,
                    let tf = tf,
                    let idx = self.codeFields.firstIndex(of: tf),
                    idx > 0
                else { return }
                let prev = self.codeFields[idx - 1]
                prev.text = ""
                prev.becomeFirstResponder()
                self.updateContinueState()
            }
        }

        codeFields.first?.becomeFirstResponder()
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
        viewModel.$isAccountVerified
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBirthdaySet in
                if isBirthdaySet {
                    let vc = SetNameViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    @objc private func tapContinue() {
        let code = currentCode()
        guard code.count == 6 else { return }
        setLoading(true)
        viewModel.verifyAccount(email: email, code: code)
    }

//    @objc private func tapResend() {
//        onResend?()
//    }
    
    @objc private func focusFirstEditableBox() {
        let i = codeFields.firstIndex { ($0.text ?? "").isEmpty } ?? 5
        codeFields[i].becomeFirstResponder()
    }

    private func setLoading(_ loading: Bool) {
        var c = continueButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Continue"
        continueButton.configuration = c
        continueButton.isEnabled = !loading ? currentCode().count == 6 : false
    }

    private func currentCode() -> String {
        codeFields.map { $0.text ?? "" }.joined()
    }

    private func updateContinueState(forceDisable: Bool = false) {
        continueButton.isEnabled = (currentCode().count == 6) && !forceDisable
    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        guard let idx = codeFields.firstIndex(where: { $0 === textField }) else { return true }

        // Paste / autofill
        if string.count > 1 {
            let digits = string.filter { $0.isNumber }.prefix(6)
            for i in 0..<6 { codeFields[i].text = "" }
            for (i, ch) in digits.enumerated() { codeFields[i].text = String(ch) }
            codeFields[max(0, digits.count - 1)].becomeFirstResponder()
            updateContinueState()
            return false
        }

        // Backspace
        if string.isEmpty {
            // If this box has a char, let the system delete it.
            if let t = textField.text, !t.isEmpty {
                // Force disable is neccessary in the situation where all 6 digits are
                // filled out, and the very last one is deleted. The system calls
                // updateContinueState before the character deletion happens, and
                // therefore you have a situation where a char is missing but the
                // nextButton is enabled.
                updateContinueState(forceDisable: true)
                return true
            }
            // If already empty, OTPTextField.deleteBackward will move left.
            return false
        }

        // Only digits
        guard string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else { return false }

        // Set and advance; keep focus on last to allow backspace
        (textField as? UITextField)?.text = String(string.prefix(1))
        if idx < 5 {
            codeFields[idx + 1].becomeFirstResponder()
        } else {
            codeFields[5].becomeFirstResponder()
        }
        updateContinueState()
        return false
    }
}


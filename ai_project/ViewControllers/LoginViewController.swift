import UIKit

class LoginViewController: UIViewController {
    
    private let videoArea: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Your personal coach\nin your pocket"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        // keep it tight
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let getStartedButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Get Started"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .capsule
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        b.applyTactileTap()
        return b
    }()

    private let alreadyHaveAccountButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .clear
        b.contentHorizontalAlignment = .center

        let baseFont   = UIFont.systemFont(ofSize: 14, weight: .regular)
        let strongFont = UIFont.systemFont(ofSize: 14, weight: .bold)

        let prefix = NSAttributedString(
            string: "Already have an account? ",
            attributes: [.font: baseFont, .foregroundColor: UIColor.secondaryLabel]
        )
        let signIn = NSAttributedString(
            string: "Sign in",
            attributes: [.font: strongFont, .foregroundColor: UIColor.label]
        )

        let title = NSMutableAttributedString()
        title.append(prefix)
        title.append(signIn)

        // same look for all states so nothing changes on touch
        [UIControl.State.normal, .highlighted, .selected, .focused].forEach {
            b.setAttributedTitle(title, for: $0)
        }
        b.applyTactileTap()

        return b
    }()

    private lazy var bottomStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, getStartedButton, alreadyHaveAccountButton])
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        hideNavBarHairline()
    }

    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubview(videoArea)
        view.addSubview(bottomStack)
        
        // Button height
        NSLayoutConstraint.activate([
            getStartedButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Pin the stack to the bottom; videoArea fills the remaining space above
        NSLayoutConstraint.activate([
            // video area
            videoArea.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            videoArea.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            videoArea.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            videoArea.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -20),
            
            // bottom stack
            bottomStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bottomStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        alreadyHaveAccountButton.addTarget(self, action: #selector(presentSocialSignInSheet), for: .touchUpInside)
    }

    // MARK: - Actions
    
    @objc private func presentSocialSignInSheet() {
        let signup = SignupViewController()
        let nav = UINavigationController(rootViewController: signup)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.selectedDetentIdentifier = .medium
            sheet.preferredCornerRadius = 12           // optional
        }
        
        nav.presentationController?.delegate = signup

        present(nav, animated: true)
    }
}

import UIKit
import UserNotifications

final class AllowNotificationsViewController: BaseSignupViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Enable notifications to get the most out of CoachAI"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - UI
    private let card = UIView()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = "Coach AI would like to send you notifications"
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let buttonsContainer = UIStackView()

    // LEFT HALF: static, non-interactive
    private let dontAllowContainer = UIView()
    private let dontAllowLabel: UILabel = {
        let l = UILabel()
        l.text = "Don’t Allow"
        l.textColor = .systemBlue
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // RIGHT HALF: actionable
    private let allowButton = UIButton(type: .system)

    private let hSeparator = UIView()
    private let vSeparator = UIView()

    private let finger = UILabel()
    private var didInstallConstraints = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        buildUI()
        super.viewDidLoad()

        setProgress(0.95, animated: false)
        wire()
        startFingerAnimation()
    }

    // MARK: - Build
    private func buildUI() {
        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.label.withAlphaComponent(0.6).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.10
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(card)

        card.addSubview(messageLabel)

        // Separators
        hSeparator.translatesAutoresizingMaskIntoConstraints = false
        hSeparator.backgroundColor = UIColor.label.withAlphaComponent(0.2)
        card.addSubview(hSeparator)

        vSeparator.translatesAutoresizingMaskIntoConstraints = false
        vSeparator.backgroundColor = UIColor.label.withAlphaComponent(0.2)
        card.addSubview(vSeparator)

        // Buttons row
        buttonsContainer.axis = .horizontal
        buttonsContainer.alignment = .fill
        buttonsContainer.distribution = .fillEqually
        buttonsContainer.spacing = 0
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(buttonsContainer)

        // Left (static view)
        dontAllowContainer.backgroundColor = .secondarySystemBackground
        dontAllowContainer.layer.cornerRadius = 20
        dontAllowContainer.layer.maskedCorners = [.layerMinXMaxYCorner]
        dontAllowContainer.translatesAutoresizingMaskIntoConstraints = false
        dontAllowContainer.isAccessibilityElement = true
        dontAllowContainer.accessibilityLabel = "Don’t Allow" // announced but not tappable
        dontAllowContainer.addSubview(dontAllowLabel)
        NSLayoutConstraint.activate([
            dontAllowLabel.centerXAnchor.constraint(equalTo: dontAllowContainer.centerXAnchor),
            dontAllowLabel.centerYAnchor.constraint(equalTo: dontAllowContainer.centerYAnchor)
        ])

        // Right (button)
        allowButton.setTitle("Allow", for: .normal)
        allowButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        allowButton.setTitleColor(.systemBlue, for: .normal)
        allowButton.backgroundColor = .systemGray3
        allowButton.layer.cornerRadius = 20
        allowButton.layer.maskedCorners = [.layerMaxXMaxYCorner]

        buttonsContainer.addArrangedSubview(dontAllowContainer)
        buttonsContainer.addArrangedSubview(allowButton)

        // Pointer
        finger.translatesAutoresizingMaskIntoConstraints = false
        finger.text = "👆"
        finger.font = .systemFont(ofSize: 48)
        view.addSubview(finger)
        view.addSubview(titleLabel)
    }

    override func layout() {
        super.layout()
        guard !didInstallConstraints else { return }
        didInstallConstraints = true

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            
            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80),
            card.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -30),

            hSeparator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            hSeparator.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            hSeparator.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            hSeparator.heightAnchor.constraint(equalToConstant: 1),

            buttonsContainer.topAnchor.constraint(equalTo: hSeparator.bottomAnchor),
            buttonsContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 56),
            buttonsContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            vSeparator.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            vSeparator.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            vSeparator.topAnchor.constraint(equalTo: hSeparator.bottomAnchor),
            vSeparator.widthAnchor.constraint(equalToConstant: 1),

            finger.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 22),
            finger.centerXAnchor.constraint(equalTo: allowButton.centerXAnchor)
        ])
    }

    private func wire() {
        allowButton.addTarget(self, action: #selector(didTapAllow), for: .touchUpInside)
        allowButton.applyTactileTap()
        // no action for the left side
    }

    // MARK: - Actions
    @objc private func didTapAllow() {
        requestSystemNotificationPermission()
    }

    // MARK: - Permission flow
    private func requestSystemNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                        DispatchQueue.main.async {
                            self.stopFingerAnimation()
                            self.finger.isHidden = true
                            self.didTapContinue()
                        }
                    }
                case .denied:
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                case .authorized, .provisional, .ephemeral:
                    self.stopFingerAnimation()
                    self.finger.isHidden = true
                    self.didTapContinue()
                @unknown default:
                    self.didTapContinue()
                }
            }
        }
    }

    // MARK: - Finger animation
    private func startFingerAnimation() {
        finger.alpha = 1
        finger.transform = .identity
        UIView.animate(withDuration: 0.75,
                       delay: 0.2,
                       options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut]) {
            self.finger.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }

    private func stopFingerAnimation() {
        finger.layer.removeAllAnimations()
        finger.transform = .identity
    }

    // MARK: - Continue
    override func didTapContinue() {
        super.didTapContinue()
        
        let vc = StartAnalysisViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

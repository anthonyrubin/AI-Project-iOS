import UIKit

/*
 Alert modals in the app
 */

/// Renders a white modal with accent-colored actions
enum AlertType: Int {
    case primary = 0   // blue accent
    case warning = 1   // orange accent
    case danger  = 2   // red accent (destructive)
}

/**
 Handles rendering the alert modal
 */
public class Alert {

    var viewController: UIViewController!

    public init(_ viewController: UIViewController!) {
        self.viewController = viewController
    }

    // Blue accent (primary)
    public func primary(titleText: String, bodyText: String!, buttonText: String!,
                        canCancel: Bool = false, cancelText: String = "Cancel",
                        errorCompletion: @escaping () -> Void = {},
                        completion: @escaping () -> Void = {}) {

        show(titleText: titleText, bodyText: bodyText, buttonText: buttonText,
             canCancel: canCancel, cancelText: cancelText, alertType: .primary,
             errorCompletion: errorCompletion, completion: completion)
    }

    // Orange accent (warning/confirm)
    public func warning(titleText: String, bodyText: String!, buttonText: String!,
                        canCancel: Bool = false, cancelText: String = "Cancel",
                        errorCompletion: @escaping () -> Void = {},
                        completion: @escaping () -> Void = {}) {

        show(titleText: titleText, bodyText: bodyText, buttonText: buttonText,
             canCancel: canCancel, cancelText: cancelText, alertType: .warning,
             errorCompletion: errorCompletion, completion: completion)
    }

    // Red accent (destructive)
    public func danger(titleText: String, bodyText: String!, buttonText: String!,
                       canCancel: Bool = false, cancelText: String = "Cancel",
                       errorCompletion: @escaping () -> Void = {},
                       completion: @escaping () -> Void = {}) {

        show(titleText: titleText, bodyText: bodyText, buttonText: buttonText,
             canCancel: canCancel, cancelText: cancelText, alertType: .danger,
             errorCompletion: errorCompletion, completion: completion)
    }

    func show(titleText: String, bodyText: String!, buttonText: String!,
              canCancel: Bool = false, cancelText: String = "Cancel", alertType: AlertType = .primary,
              errorCompletion: @escaping () -> Void, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let vc = AlertViewController()
            vc.alertType = alertType
            vc.titleText = titleText
            vc.bodyText = bodyText
            vc.buttonText = buttonText
            vc.completion = completion
            vc.errorCompletion = errorCompletion
            vc.canCancel = canCancel
            vc.cancelText = cancelText
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.viewController.present(vc, animated: true, completion: nil)
        }
    }
}

/**
 The view controller for the alert modal
 */
class AlertViewController: BaseViewController {

    // MARK: - Properties
    var alertType: AlertType!
    private var backgroundColor: UIColor!     // modal background (white)
    private var accentColor: UIColor!         // button accent (blue/orange/red)
    private var fontColor: UIColor!           // title text color

    var containerView: UIView!
    var titleText: String!
    var bodyText: String!
    var buttonText: String!
    var canCancel = false
    var cancelText = "Cancel"

    var isModalOpen = false
    var completion:(()->Void)!
    var errorCompletion:(()->Void)!

    private var centerYConstraint: NSLayoutConstraint?
    private let padding: CGFloat = 24
    private let buttonHeight: CGFloat = 50

    override func viewDidLoad() {
        super.viewDidLoad()
        // overlay
        view.backgroundColor = UIColor(netHex: 0x000000, alpha: 0.7)
        setParams()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isModalOpen {
            drawModalAutoLayout()
        }
    }

    // MARK: - Actions

    @objc func dismissModal(_ sender: UIButton) {
        // Slide down by moving centerY
        guard let centerY = centerYConstraint else { return }
        centerY.constant = view.bounds.height
        UIView.animate(withDuration: 0.30,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut],
                       animations: { self.view.layoutIfNeeded() },
                       completion: { _ in
            self.dismiss(animated: true) {
                if sender.tag == 0 {
                    self.completion?()       // primary
                } else if sender.tag == 1 {
                    self.errorCompletion?()  // secondary/cancel
                }
            }
        })
    }

    // MARK: - Rendering

    private func setParams() {
        // White modal, dark text
        backgroundColor = UIColor(netHex: 0xFFFFFF)
        fontColor = UIColor(netHex: 0x0A0A0A)

        // Accent per alert type
        switch alertType {
        case .primary: accentColor = UIColor(netHex: 0x004DBF) // blue
        case .warning: accentColor = UIColor(netHex: 0xFB8E0E) // orange
        case .danger:  accentColor = UIColor(netHex: 0xEF0400) // red (destructive)
        case .none:    accentColor = UIColor(netHex: 0x004DBF)
        }
    }

    private func drawModalAutoLayout() {
        isModalOpen = true

        // Container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = backgroundColor
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        view.addSubview(container)
        self.containerView = container

        // Width = screen - 40 (20 per side), centered
        let leading = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        let trailing = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        let centerX = container.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let centerY = container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        self.centerYConstraint = centerY
        NSLayoutConstraint.activate([leading, trailing, centerX, centerY])

        // Content stack
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 0
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 32, leading: padding, bottom: padding, trailing: padding)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = fontColor
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.text = titleText
        stack.addArrangedSubview(titleLabel)
        stack.setCustomSpacing(12, after: titleLabel)

        // Body
        if let bodyText, !bodyText.isEmpty {
            let bodyLabel = UILabel()
            bodyLabel.numberOfLines = 0
            bodyLabel.textAlignment = .center
            bodyLabel.textColor = UIColor(netHex: 0x59595B)
            bodyLabel.font = .systemFont(ofSize: 16, weight: .regular)
            bodyLabel.text = bodyText
            stack.addArrangedSubview(bodyLabel)
            stack.setCustomSpacing(24, after: bodyLabel)
        } else {
            stack.setCustomSpacing(24, after: titleLabel)
        }

        // Buttons
        let primary = makePrimaryButton(title: buttonText)
        primary.accessibilityIdentifier = "id_alert_accept"

        if canCancel {
            let secondary = makeSecondaryButton(title: cancelText)
            secondary.accessibilityIdentifier = "id_alert_cancel"

            let buttonRow = UIStackView(arrangedSubviews: [secondary, primary])
            buttonRow.axis = .horizontal
            buttonRow.alignment = .fill
            buttonRow.distribution = .fillEqually
            buttonRow.spacing = 12
            stack.addArrangedSubview(buttonRow)

            primary.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            secondary.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        } else {
            stack.addArrangedSubview(primary)
            primary.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        }

        // Animate in: start above screen, then settle to center
        view.layoutIfNeeded()
        centerY.constant = -view.bounds.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.50,
                       delay: 0.01,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut],
                       animations: {
            centerY.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Buttons (iOS 15+ configurations)

    private func makePrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applyTactileTap()
        button.tag = 0
        button.addTarget(self, action: #selector(AlertViewController.dismissModal(_:)), for: .touchUpInside)

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.title = title
        config.baseForegroundColor = .white
        config.baseBackgroundColor = accentColor
        config.titleAlignment = .center
        config.contentInsets = .init(top: 14, leading: 18, bottom: 14, trailing: 18)
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]))
        button.configuration = config

        // Press feedback only (no disabled state handling per your note)
        button.configurationUpdateHandler = { [weak self] btn in
            guard let self = self else { return }
            var cfg = btn.configuration!
            if btn.isHighlighted {
                cfg.baseBackgroundColor = self.adjustBrightness(self.accentColor, amount: 0.92)
            } else {
                cfg.baseBackgroundColor = self.accentColor
            }
            btn.configuration = cfg
        }
        return button
    }

    private func makeSecondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applyTactileTap()
        button.tag = 1
        button.addTarget(self, action: #selector(AlertViewController.dismissModal(_:)), for: .touchUpInside)

        var config = UIButton.Configuration.bordered()
        config.cornerStyle = .capsule
        config.title = title
        config.baseForegroundColor = accentColor
        config.titleAlignment = .center
        config.contentInsets = .init(top: 14, leading: 18, bottom: 14, trailing: 18)
        // 1pt outline
        config.background.strokeColor = accentColor
        config.background.strokeWidth = 1
        config.background.backgroundColor = .clear
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]))
        button.configuration = config

        button.configurationUpdateHandler = { [weak self] btn in
            guard let self = self else { return }
            var cfg = btn.configuration!
            if btn.isHighlighted {
                cfg.background.backgroundColor = self.accentColor.withAlphaComponent(0.08)
            } else {
                cfg.background.backgroundColor = .clear
            }
            btn.configuration = cfg
        }
        return button
    }

    // MARK: - Helpers

    func adjustBrightness(_ color: UIColor, amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            var b = brightness + (amount - 1.0)
            b = max(min(b, 1.0), 0.0)
            return UIColor(hue: hue, saturation: saturation, brightness: b, alpha: alpha)
        }
        return color
    }
}

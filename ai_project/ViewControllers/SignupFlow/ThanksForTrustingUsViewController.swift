import UIKit

// MARK: - Reusable card with floating badge
final class PrivacyBadgeCardView: UIView {

    // MARK: Public API
    var title: String { didSet { titleLabel.text = title } }
    var subtitle: String { didSet { subtitleLabel.text = subtitle } }

    /// Change to "gearshape.fill" if you want a gear outline instead of a rosette.
    var badgeBaseSymbolName: String = "seal.fill" {
        didSet { badgeBase.image = UIImage(systemName: badgeBaseSymbolName)?.withRenderingMode(.alwaysTemplate) }
    }

    /// Emoji shown in the center of the badge.
    var badgeEmoji: String = "🔒" {
        didSet { badgeIcon.text = badgeEmoji }
    }

    // MARK: Subviews
    private let card = UIView()
    private let badgeContainer = UIView()
    private let badgeBase = UIImageView()
    private let badgeIcon = UILabel()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: Init
    init(title: String,
         subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        super.init(frame: .zero)
        buildUI()
    }

    required init?(coder: NSCoder) {
        self.title = ""
        self.subtitle = ""
        super.init(coder: coder)
        buildUI()
    }

    // MARK: Setup
    private func buildUI() {
        translatesAutoresizingMaskIntoConstraints = false

        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor
        addSubview(card)

        // Badge container overlaps card top
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeContainer)

        // Badge base (SF symbol)
        badgeBase.translatesAutoresizingMaskIntoConstraints = false
        badgeBase.contentMode = .scaleAspectFit
        badgeBase.image = UIImage(systemName: badgeBaseSymbolName)?.withRenderingMode(.alwaysTemplate)
        badgeBase.tintColor = .systemBackground
        badgeBase.layer.shadowColor = UIColor.black.cgColor
        badgeBase.layer.shadowOpacity = 0.12
        badgeBase.layer.shadowRadius = 8
        badgeBase.layer.shadowOffset = CGSize(width: 0, height: 3)
        badgeContainer.addSubview(badgeBase)

        // Inner emoji
        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badgeIcon.textAlignment = .center
        badgeIcon.text = badgeEmoji
        badgeIcon.font = .systemFont(ofSize: 28, weight: .regular)  // tweak 26–30 to taste
        badgeContainer.addSubview(badgeIcon)

        // Labels
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        // Constraints
        let badgeSize: CGFloat = 56
        NSLayoutConstraint.activate([
            // Card fills our bounds; top has space for badge overlap
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Badge centered horizontally, overlapping the top edge of the card
            badgeContainer.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            badgeContainer.centerYAnchor.constraint(equalTo: card.topAnchor),
            badgeContainer.widthAnchor.constraint(equalToConstant: badgeSize),
            badgeContainer.heightAnchor.constraint(equalToConstant: badgeSize),

            badgeBase.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor),
            badgeBase.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor),
            badgeBase.topAnchor.constraint(equalTo: badgeContainer.topAnchor),
            badgeBase.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor),

            badgeIcon.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),

            // Card content
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        // Accessibility
        isAccessibilityElement = false
        badgeContainer.isAccessibilityElement = true
        badgeContainer.accessibilityLabel = "Private and secure"
    }
}

// MARK: - Screen
final class ThanksForTrustingUsViewController: BaseSignupViewController {
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Thank you for trusting us"
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let animationPanel: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.label.withAlphaComponent(0.05)
        v.layer.cornerRadius = 22
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let midBlurb: UILabel = {
        let l = UILabel()
        l.text = "Now let’s start coaching you."
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 20, weight: .medium)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let privacyCard = PrivacyBadgeCardView(
        title: "Your privacy and security matter to us.",
        subtitle: "We promise to always keep your personal information private and secure."
    )

    private var didInstallConstraints = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.64, animated: false)
    }

    override func layout() {
        view.addSubview(titleLabel)
        view.addSubview(animationPanel)
        view.addSubview(midBlurb)
        view.addSubview(privacyCard)
        super.layout()
        guard !didInstallConstraints else { return }
        didInstallConstraints = true

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            
            // Animation box (put your Lottie, CAAnimation, etc. inside)
            animationPanel.topAnchor.constraint(equalTo: g.bottomAnchor, constant: 60),
            animationPanel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            animationPanel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            animationPanel.heightAnchor.constraint(equalToConstant: 180),

            // Mid blurb
            midBlurb.topAnchor.constraint(equalTo: animationPanel.bottomAnchor, constant: 28),
            midBlurb.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 24),
            midBlurb.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -24),

            // Privacy card above the fixed Continue button
            privacyCard.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            privacyCard.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            privacyCard.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -28)
        ])
    }

    override func didTapContinue() {
        super.didTapContinue()
        
        let vc = AllowNotificationsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}


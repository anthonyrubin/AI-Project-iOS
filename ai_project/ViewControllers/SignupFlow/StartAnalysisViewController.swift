import UIKit

// MARK: - Row with left circular SF icon + multiline text
private final class TipRowView: UIView {
    private let circle = UIView()
    private let icon   = UIImageView()
    private let label  = UILabel()

    init(text: String, symbol: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        circle.layer.cornerRadius = 22
        circle.layer.cornerCurve = .continuous
        addSubview(circle)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.image = UIImage(systemName: symbol)?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = .label
        circle.addSubview(icon)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        addSubview(label)

        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            circle.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 44),
            circle.heightAnchor.constraint(equalToConstant: 44),

            icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Image card (light container with rounded image inside)
private final class MediaCardView: UIView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.label.withAlphaComponent(0.05)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.cornerCurve = .continuous
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0) // pleasant aspect
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Screen
final class StartAnalysisViewController: BaseSignupViewController {

    // Title (scrolls with content)
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Let’s analyze your performance"
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Scroll content
    private let scrollView = UIScrollView()
    private let content    = UIStackView()

    private let mediaCard  = MediaCardView()
    private let tipsStack  = UIStackView()
    private let skipButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.90, animated: false)

        buildUI()
        layoutUI()
        configureData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep content clear of the fixed Continue button
        let pad = continueButton.bounds.height + 32
        if scrollView.contentInset.bottom != pad {
            scrollView.contentInset.bottom = pad
            scrollView.verticalScrollIndicatorInsets.bottom = pad
        }
    }

    // MARK: UI
    private func buildUI() {
        // Scroll view + content stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        view.addSubview(scrollView)

        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        content.addArrangedSubview(titleLabel)
        content.setCustomSpacing(16, after: titleLabel)

        // Image card
        content.addArrangedSubview(mediaCard)

        // Tips
        tipsStack.axis = .vertical
        tipsStack.alignment = .fill
        tipsStack.spacing = 18
        tipsStack.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(tipsStack)

        // Skip for now
        skipButton.setTitle("Skip for now", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        skipButton.tintColor = .label
        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
        content.addArrangedSubview(skipButton)
    }

    private func layoutUI() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),

            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Make content match scroll width so it only scrolls when needed
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),

            mediaCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        // Center the "Skip" text
        skipButton.contentHorizontalAlignment = .center
    }

    private func configureData() {
        // Use your real image asset here
        mediaCard.imageView.image = UIImage(named: "golfPreview") // fallback
        if mediaCard.imageView.image == nil {
            mediaCard.imageView.backgroundColor = .tertiarySystemFill
        }

        // Tips (icons chosen to be available and clear)
        let tips: [(String, String)] = [
            ("Ensure that you are well lit and completely in frame.", "viewfinder"),
            ("Don’t stand too far away from the camera.", "magnifyingglass.circle"),
            ("Use a high frame rate for the best analysis. Most smartphones can film at 60 fps.", "speedometer")
        ]
        tips.forEach { tipsStack.addArrangedSubview(TipRowView(text: $0.0, symbol: $0.1)) }
    }

    // MARK: Actions
    @objc private func didTapSkip() {
        // Handle skip – navigate to the capture/upload screen or next step
        didTapContinue()
    }

    override func didTapContinue() {
        super.didTapContinue()
        // Push your capture/upload VC here
        // navigationController?.pushViewController(NextVC(), animated: true)
    }
}

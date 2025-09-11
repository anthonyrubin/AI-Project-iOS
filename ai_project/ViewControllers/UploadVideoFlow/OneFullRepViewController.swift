import UIKit

final class OneFullRepViewController: UIViewController {

    // MARK: - Callback
    var onContinue: (() -> Void)?

    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "One full rep"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scannerContainer = UIView()
    private let stepsView: FreeTrialStepsView
    private let scannerView: LoadingScannerView

    // Aspect constraints
    private var arEqual: NSLayoutConstraint?
    private var arMax: NSLayoutConstraint?

    // Keep a reference for aspect calculation
    private let baseImage: UIImage?

    // Start animation once
    private var hasStartedScan = false

    // MARK: - Init
    init() {
        let base = UIImage(named: "weightlifting_preview")
        let overlay = UIImage(named: "weightlifting_overlay")

        self.baseImage = base
        self.scannerView = LoadingScannerView(base: base ?? UIImage(),
                                              overlay: overlay ?? UIImage())
        self.scannerView.contentCornerRadius = 14

        self.stepsView = FreeTrialStepsView(steps: [
            .init(icon: "1.circle",
                  title: nil,
                  subtitle: "Film a single rep from start to finish"),
            .init(icon: "hand.raised",
                  title: nil,
                  subtitle: "Make a full stop at lockout and descent")
        ])
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        layoutUI()

        // Build aspect constraints from the image’s ratio (H/W); fallback to 9:16 if missing
        let aspect = (baseImage?.size.height ?? 9) / (baseImage?.size.width ?? 16)
        setScannerAspect(aspect)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasStartedScan {
            hasStartedScan = true
            scannerView.startScan(duration: 6)
        }
    }

    // MARK: - Build / Layout
    private func buildUI() {
        scannerContainer.translatesAutoresizingMaskIntoConstraints = false
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        stepsView.translatesAutoresizingMaskIntoConstraints = false

        // Stack: [scanner (flex), title, steps] above the button
        let stack = UIStackView(arrangedSubviews: [scannerContainer, titleLabel, stepsView])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        // Scanner fills its container
        scannerContainer.addSubview(scannerView)
        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: scannerContainer.topAnchor),
            scannerView.leadingAnchor.constraint(equalTo: scannerContainer.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: scannerContainer.trailingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: scannerContainer.bottomAnchor)
        ])

        // Title/steps should never clip; scanner shrinks first
        [titleLabel, stepsView].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        scannerContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        scannerContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.addSubview(continueButton)

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: g.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            continueButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Optional: keep some scanner presence on short screens
        let minH = scannerContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        minH.priority = .defaultHigh
        minH.isActive = true
    }

    private func layoutUI() {
        // All constraints set in buildUI
    }

    /// Rebuild aspect constraints using the given H/W ratio.
    private func setScannerAspect(_ aspect: CGFloat) {
        arEqual?.isActive = false
        arMax?.isActive   = false

        // Prefer exact aspect when there is room…
        arEqual = scannerContainer.heightAnchor.constraint(
            equalTo: scannerContainer.widthAnchor,
            multiplier: aspect
        )
        arEqual?.priority = .defaultHigh   // 750
        arEqual?.isActive = true

        // …but never exceed it if vertical space is tight
        arMax = scannerContainer.heightAnchor.constraint(
            lessThanOrEqualTo: scannerContainer.widthAnchor,
            multiplier: aspect
        )
        arMax?.priority = .required        // 1000
        arMax?.isActive = true

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Continue button
    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .label
        config.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)

        var attrs = AttributeContainer()
        attrs.font = .systemFont(ofSize: 18, weight: .semibold)
        attrs.foregroundColor = UIColor.systemBackground
        config.attributedTitle = AttributedString("Analyze", attributes: attrs)

        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapContinue()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applyTactileTap()
        return button
    }()

    @objc private func didTapContinue() {
        onContinue?()
    }
}


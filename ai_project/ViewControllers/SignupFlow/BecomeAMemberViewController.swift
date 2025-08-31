import UIKit

import UIKit

final class Laurel5StarsView: UIView {

    // MARK: - Config
    var laurelWidth: CGFloat = 35 {
        didSet { laurelWidthConstraints.forEach { $0.constant = laurelWidth } }
    }
    var laurelSpacing: CGFloat = 12 {
        didSet {
            leftToCenter.constant = -laurelSpacing
            centerToRight.constant =  laurelSpacing
        }
    }
    var titleText: String = "The #1 AI Coaching App" {
        didSet { title.text = titleText }
    }
    var starSize: CGFloat = 20 {
        didSet {
            starSizeConstraints.forEach {
                $0.firstAttribute == .width ? ($0.constant = starSize) : ($0.constant = starSize)
            }
        }
    }
    var starColor: UIColor = UIColor(red: 0xE2/255, green: 0x9C/255, blue: 0x69/255, alpha: 1) {
        didSet { starImageViews.forEach { $0.tintColor = starColor } }
    }

    // MARK: - Subviews
    private let title: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stars: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 5
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let centerStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let leftLaurel: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "laurel.leading"))
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let rightLaurel: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "laurel.trailing"))
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Stored constraint refs
    private var laurelWidthConstraints: [NSLayoutConstraint] = []
    private var starSizeConstraints: [NSLayoutConstraint] = []
    private var starImageViews: [UIImageView] = []
    private var leftToCenter: NSLayoutConstraint!
    private var centerToRight: NSLayoutConstraint!

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }

    // MARK: - Build
    private func build() {
        // Title text
        title.text = titleText

        // Stars
        for _ in 0..<5 {
            let iv = UIImageView(image: UIImage(systemName: "star.fill"))
            iv.tintColor = starColor
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            starImageViews.append(iv)
            stars.addArrangedSubview(iv)

            let w = iv.widthAnchor.constraint(equalToConstant: starSize)
            let h = iv.heightAnchor.constraint(equalToConstant: starSize)
            starSizeConstraints.append(contentsOf: [w, h])
            NSLayoutConstraint.activate([w, h])
        }

        centerStack.addArrangedSubview(stars)
        centerStack.addArrangedSubview(title)

        addSubview(leftLaurel)
        addSubview(rightLaurel)
        addSubview(centerStack)

        // Priorities: laurels resist; center compresses first if needed
        leftLaurel.setContentHuggingPriority(.required, for: .horizontal)
        rightLaurel.setContentHuggingPriority(.required, for: .horizontal)
        centerStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        centerStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Constraints
        leftToCenter = leftLaurel.trailingAnchor.constraint(equalTo: centerStack.leadingAnchor, constant: -laurelSpacing)
        centerToRight = centerStack.trailingAnchor.constraint(equalTo: rightLaurel.leadingAnchor, constant: -laurelSpacing)

        let leftW = leftLaurel.widthAnchor.constraint(equalToConstant: laurelWidth)
        let rightW = rightLaurel.widthAnchor.constraint(equalToConstant: laurelWidth)
        laurelWidthConstraints = [leftW, rightW]

        NSLayoutConstraint.activate([
            // Hard-center the middle block
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),

            // Laurels pulled in close to center stack
            leftToCenter,                       // left ↔ center
            centerToRight,                      // center ↔ right

            // Keep laurels inside the view vertically centered
            leftLaurel.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightLaurel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Edge guards so laurels don't escape on tiny widths
            leftLaurel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            rightLaurel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),

            // Fixed widths + preserved aspect ratios
            leftW, rightW,
            leftLaurel.heightAnchor.constraint(equalTo: leftLaurel.widthAnchor, multiplier: aspectRatio(of: leftLaurel)),
            rightLaurel.heightAnchor.constraint(equalTo: rightLaurel.widthAnchor, multiplier: aspectRatio(of: rightLaurel))
        ])
    }

    private func aspectRatio(of iv: UIImageView) -> CGFloat {
        guard let img = iv.image, img.size.width > 0 else { return 1 }
        return img.size.height / img.size.width
    }
}


/// Circular score indicator like the mockup:
/// - Outer gray track + colored progress arc (starts at 12 o'clock)
/// - Solid inner disk
/// - Centered label counting up during animation
final class ScoreRingView: UIView {

    // MARK: - Tunables
    var ringWidth: CGFloat = 6 { didSet { setNeedsLayout() } }
    var innerInset: CGFloat = 0 { didSet { setNeedsLayout() } } // gap between ring and inner disk
    var trackColor: UIColor = UIColor(white: 0.90, alpha: 1) { didSet { trackLayer.strokeColor = trackColor.cgColor } }
    var innerDiskColor: UIColor = UIColor(white: 0.30, alpha: 1) { didSet { innerDiskLayer.fillColor = innerDiskColor.cgColor } }
    var font: UIFont = .systemFont(ofSize: 25, weight: .heavy) { didSet { valueLabel.font = font } }
    var textColor: UIColor = .white { didSet { valueLabel.textColor = textColor } }

    /// Color thresholds for the progress ring
    var lowColor: UIColor = .systemRed
    var midColor: UIColor = .systemYellow
    var highColor: UIColor = .systemGreen

    // MARK: - Layers & Views
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let innerDiskLayer = CAShapeLayer()
    private let valueLabel = UILabel()

    // MARK: - State
    private(set) var score: Int = 0
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var targetScore: Int = 0
    private var animationDuration: TimeInterval = 1.2

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = lowColor.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        innerDiskLayer.fillColor = innerDiskColor.cgColor
        layer.addSublayer(innerDiskLayer)

        valueLabel.textAlignment = .center
        valueLabel.textColor = textColor
        valueLabel.font = font
        valueLabel.text = "0"
        addSubview(valueLabel)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Circle rect (centered square)
        let side = min(bounds.width, bounds.height)
        let circleRect = CGRect(x: (bounds.width - side)/2,
                                y: (bounds.height - side)/2,
                                width: side,
                                height: side)

        // Paths
        let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
        let radius = side/2 - ringWidth/2
        let startAngle = -CGFloat.pi/2
        let endAngle = startAngle + 2*CGFloat.pi

        let ringPath = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: true)

        trackLayer.frame = bounds
        trackLayer.path = ringPath.cgPath
        trackLayer.lineWidth = ringWidth

        progressLayer.frame = bounds
        progressLayer.path = ringPath.cgPath
        progressLayer.lineWidth = ringWidth

        // Inner disk
        let innerRadius = radius - ringWidth/2 - innerInset
        let innerPath = UIBezierPath(arcCenter: center,
                                     radius: max(innerRadius, 0),
                                     startAngle: 0,
                                     endAngle: 2*CGFloat.pi,
                                     clockwise: true)
        innerDiskLayer.frame = bounds
        innerDiskLayer.path = innerPath.cgPath

        valueLabel.frame = bounds.insetBy(dx: ringWidth, dy: ringWidth)
        bringSubviewToFront(valueLabel)
    }

    // MARK: - Public API

    /// Set the score instantly without animation (0...100).
    func setScore(_ value: Int) {
        let clamped = max(0, min(100, value))
        score = clamped
        valueLabel.text = "\(clamped)"
        progressLayer.strokeEnd = CGFloat(clamped) / 100.0
        progressLayer.strokeColor = ringColor(for: clamped).cgColor
    }

    /// Animate the ring from 0% and the label from 0 up to `value`.
    /// Duration defaults to ~1.2s; set 0.8–1.6s per your spec.
    // Replace your animate(to:duration:) with this version
    func animate(to value: Int, duration: TimeInterval = 1.2) {
        let clamped = max(0, min(100, value))
        targetScore = clamped
        animationDuration = max(0.3, min(2.0, duration))

        // Stop any prior work
        stopDisplayLink()
        progressLayer.removeAllAnimations()
        valueLabel.layer.removeAllAnimations()

        // Set starting state WITHOUT implicit animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        valueLabel.text = "0"
        progressLayer.strokeColor = ringColor(for: clamped).cgColor
        progressLayer.strokeEnd = 0
        CATransaction.commit()

        // Explicit ring animation
        let to = CGFloat(clamped) / 100.0
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = to
        anim.duration = animationDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)

        // Keep the visual state at the end of the animation
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        progressLayer.add(anim, forKey: "strokeEnd")

        // Update the model layer to final value WITHOUT implicit animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = to
        CATransaction.commit()

        // Label count-up in sync
        animationStartTime = CACurrentMediaTime()
        startDisplayLink()
    }


    // MARK: - Helpers

    private func ringColor(for score: Int) -> UIColor {
        if score <= 35 { return lowColor }
        if score < 75  { return midColor }
        return highColor
    }


    private func startDisplayLink() {
        let dl = CADisplayLink(target: self, selector: #selector(step))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step() {
        let now = CACurrentMediaTime()
        let t = max(0, min(1, (now - animationStartTime) / animationDuration)) // 0...1
        // Ease to match the arc
        let eased = CGFloat(CAMediaTimingFunction(name: .easeInEaseOut).value(at: Float(t)))
        let current = Int(round(eased * CGFloat(targetScore)))
        valueLabel.text = "\(current)"
        if t >= 1 {
            stopDisplayLink()
            score = targetScore
        }
    }
}

// MARK: - CAMediaTimingFunction sampling helper
private extension CAMediaTimingFunction {
    /// Samples the Bezier at progress `x` (0...1)
    func value(at x: Float) -> Float {
        var c1 = [Float](repeating: 0, count: 2)
        var c2 = [Float](repeating: 0, count: 2)
        getControlPoint(at: 1, values: &c1)
        getControlPoint(at: 2, values: &c2)
        // cubic Bezier y given x ≈ use x as t (good enough for UI), map to y
        let t = x
        let oneMinusT = 1 - t
        // y(t) with P0=(0,0), P1=(c1.x,c1.y), P2=(c2.x,c2.y), P3=(1,1)
        let y =
            3 * oneMinusT * oneMinusT * t * c1[1] +
            3 * oneMinusT * t * t * c2[1] +
            t * t * t
        return y
    }
}













// Optional: keep this here for a self-contained file.
// You can move it to its own file if you prefer.
private final class StickyCTAView: UIView {
    let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Join 5+ million users worldwide"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start Free Trial", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .label
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.layer.cornerRadius = 28
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    let finePrint: UILabel = {
        let l = UILabel()
        l.text = "First 3 days free, then $29.99 / year"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 24
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 20
        layer.shadowOffset = .init(width: 0, height: -2)

        addSubview(titleLabel)
        addSubview(ctaButton)
        addSubview(finePrint)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            ctaButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            ctaButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 56),

            finePrint.topAnchor.constraint(equalTo: ctaButton.bottomAnchor, constant: 10),
            finePrint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            finePrint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            finePrint.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class BecomeAMemberViewController: BaseSignupViewController {

    // MARK: - Deps
    private let viewModel = BecomeAMemberViewModel(
        repository: VideoAnalysisRepository(
            analysisAPI: NetworkManager(tokenManager: TokenManager())
        )
    )

    // MARK: - UI
    private let laurel5StarsView = Laurel5StarsView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let scoreRingView = ScoreRingView()

    private let summaryView: UIView = {
        let v = UIView()
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 12
        v.layer.borderColor = UIColor.systemGray.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let summarySectionTitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.text = "AI Analysis Summary"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let summaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Subscribe to unlock your full potential"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Get instant AI analysis and feedback, track your progress over time, and more."
        l.font = .systemFont(ofSize: 18)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Sticky card
    private let stickyCard = StickyCTAView()
    private var stickyBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        hideBackButton = true
        hidesProgressBar = true
        buildUI()
        super.viewDidLoad()

        // Add sticky card as sibling above scroll view
        view.addSubview(stickyCard)
        view.bringSubviewToFront(stickyCard)

        stickyBottomConstraint = stickyCard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            stickyCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyBottomConstraint!
        ])
    }

    private var didAnimate = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAnimate {
            didAnimate = true
            let aiScore = Int(viewModel.getLastUpload()?.professionalScore ?? 0)
            scoreRingView.animate(to: aiScore, duration: 0.6)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make room so content scrolls behind the sticky card without being obscured
        let cardHeight = stickyCard.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let inset = cardHeight + 12
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    // MARK: - Build / Layout
    private func buildUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, subtitleLabel, laurel5StarsView, summarySectionTitle, summaryView]
            .forEach { contentView.addSubview($0) }

        summaryView.addSubview(summaryStack)
        summaryStack.addArrangedSubview(scoreRingView)
        summaryStack.addArrangedSubview(summaryLabel)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        laurel5StarsView.translatesAutoresizingMaskIntoConstraints = false
        scoreRingView.translatesAutoresizingMaskIntoConstraints = false

        summaryLabel.text = viewModel.getLastUpload()?.clipSummary
        summaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        layoutUI()
    }

    private func layoutUI() {
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            // Scroll view frame
            frame.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            frame.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frame.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frame.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Scroll content
            contentView.topAnchor.constraint(equalTo: content.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Title / subtitle
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Laurels
            laurel5StarsView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            laurel5StarsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            laurel5StarsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            // Summary title
            summarySectionTitle.topAnchor.constraint(equalTo: laurel5StarsView.bottomAnchor, constant: 60),
            summarySectionTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summarySectionTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Summary container
            summaryView.topAnchor.constraint(equalTo: summarySectionTitle.bottomAnchor, constant: 15),
            summaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Summary stack fills container with insets
            summaryStack.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 10),
            summaryStack.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 10),
            summaryStack.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -10),
            summaryStack.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -10),

            // Ring size
            scoreRingView.widthAnchor.constraint(equalToConstant: 70),
            scoreRingView.heightAnchor.constraint(equalToConstant: 70),

            // Content bottom follows summaryView
            contentView.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 40)
        ])
    }
}
















private struct FreeTrialStepsData {
    let icon: String
    let title: String
    let subtitle: String
}

class FreeTrialStepsView: UIView {
    
    private var data: [FreeTrialStepsData]
    
    private var steps: [UIStackView] = []
    
    init(sportIcon: String) {
        
        let firstStep = FreeTrialStepsData(
            icon: sportIcon,
            title: "Today: Get Instant Access",
            subtitle: "Immediately up your game with AI analysis and coaching."
        )
        
        let secondStep = FreeTrialStepsData(
            icon: "bell.circle.fill",
            title: "In 2 days: Trial Reminder Sent",
            subtitle: "We will let you know before your trial ends."
        )
        
        let thirdStep = FreeTrialStepsData(
            icon: "star.circle.fill",
            title: "In 3 days: Subscription Begins",
            subtitle: "Unlock your full potential with a CoachAI in your pocket."
        )
        
        data = [
            firstStep, secondStep, thirdStep
        ]
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // clean if re-called
        subviews.forEach { $0.removeFromSuperview() }
        steps.removeAll()

        var previousRow: UIStackView?

        for step in data {
            // Icon
            let icon = UIImageView(image: UIImage(systemName: step.icon))
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .systemBlue
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 40),
                icon.heightAnchor.constraint(equalToConstant: 40)
            ])
            icon.tintColor = .black

            // Icon container (gives the row a real left column width)
            let iconContainer = UIView()
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(icon)
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
                icon.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor), // <-- gives container width
                icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
            ])
            iconContainer.setContentHuggingPriority(.required, for: .horizontal)
            iconContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

            // Title + subtitle
            let title = UILabel()
            title.text = step.title
            title.font = .systemFont(ofSize: 18, weight: .medium)
            title.numberOfLines = 0
            title.lineBreakMode = .byWordWrapping
            title.setContentCompressionResistancePriority(.required, for: .vertical)

            let subtitle = UILabel()
            subtitle.text = step.subtitle
            subtitle.font = .systemFont(ofSize: 14, weight: .regular)
            subtitle.textColor = .secondaryLabel
            subtitle.numberOfLines = 0
            subtitle.lineBreakMode = .byWordWrapping
            subtitle.setContentCompressionResistancePriority(.required, for: .vertical)

            let textStack = UIStackView(arrangedSubviews: [title, subtitle])
            textStack.axis = .vertical
            textStack.alignment = .fill
            textStack.spacing = 4
            textStack.translatesAutoresizingMaskIntoConstraints = false
            textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

            // Row
            let row = UIStackView(arrangedSubviews: [iconContainer, textStack])
            row.axis = .horizontal
            row.alignment = .fill            // icon is centered via container constraint
            row.spacing = 15
            row.translatesAutoresizingMaskIntoConstraints = false
            addSubview(row)

            // Vertical chain
            if let prev = previousRow {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 12).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            }

            // Horizontal insets + ensure text has a concrete width so it wraps
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            previousRow = row
            steps.append(row)
        }

        // Bottom inset
        if let last = previousRow {
            last.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        }
    }
}

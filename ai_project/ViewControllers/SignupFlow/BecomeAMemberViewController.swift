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
        l.text = "Join elite athletes worldwide"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(
            "Become a member",
            for: .normal
        )
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .label
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.layer.cornerRadius = 28
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    let finePrint: UILabel = {
        let l = UILabel()
        l.text = "Elite coaching in your pocket for only $19.99 / month"
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







import UIKit

// =======================================================
// MARK: EventsPaywallOverlay (view)
// =======================================================

/// Overlay that hides everything *after a pixel cutoff* inside a card.
/// The overlay has two vertical regions:
///  1) A top scrim (transparent → white) to softly fade out underlying content.
///  2) A solid-white block that contains a lock + message.
///
/// HOW TO USE (pixel-based cutoff):
///  - Add this overlay as a subview of your card (e.g., eventsView).
///  - Pin overlay.leading/trailing/bottom to the card.
///  - Keep a reference to the overlay's TOP constraint and set its `constant` to the
///    **cutoff in points** (the amount of content you want to leave visible at the top).
///  - Separately, make sure the *card’s height* is:  cutoff + requiredOverlayHeight(for: cardWidth)
///    so the scrim + lock/message have room to render below the cutoff.
///
/// NOTES:
///  - The overlay itself doesn’t decide the cutoff—YOU pass the pixel amount via the top constraint.
///  - `requiredOverlayHeight(for:)` guarantees the lock/message are fully below the faded region.
///  - The overlay never darkens content (it fades to white).
final class EventsPaywallOverlay: UIView {

    // MARK: - Public knobs

    /// Clear gap (pts) before the scrim fade starts.
    /// Increase if you want a bit of fully-clear area right under your cutoff.
    var clearHeadroom: CGFloat = 8 { didSet { scrimTop.constant = clearHeadroom } }

    /// Height (pts) of the fade from clear → white.
    var fadeHeight: CGFloat = 80 { didSet { scrimHeight.constant = fadeHeight } }

    /// Minimum overall height for the overlay (scrim + solid block).
    var minOverlayHeight: CGFloat = 200

    /// Bottom padding (pts) from the message to the overlay’s bottom.
    var bottomMargin: CGFloat = 30 { didSet { stackBottom?.constant = -bottomMargin } }

    /// Horizontal text padding (pts) inside the solid block.
    var horizontalPadding: CGFloat = 20 {
        didSet {
            content.layoutMargins = UIEdgeInsets(
                top: 0, left: horizontalPadding, bottom: bottomMargin, right: horizontalPadding
            )
        }
    }

    // MARK: - Subviews

    private let scrim = FadeScrimView()   // transparent → white gradient
    private let content = UIView()        // solid white region for lock/message
    let lockLabel = UILabel()
    let textLabel = UILabel()
    private let stack = UIStackView()

    // MARK: - Adjustable constraints (internal)

    private var scrimTop: NSLayoutConstraint!
    private var scrimHeight: NSLayoutConstraint!
    private var stackBottom: NSLayoutConstraint?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }

    // MARK: - Build

    private func build() {
        backgroundColor = .clear

        // Scrim
        scrim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)

        // Solid content
        content.backgroundColor = .white
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        // Lock + message stack
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false

        lockLabel.text = "🔒"
        lockLabel.font = .systemFont(ofSize: 42, weight: .regular)
        lockLabel.textAlignment = .center

        textLabel.text = "Unlock the full timestamped analysis of your performance."
        textLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        textLabel.textAlignment = .center
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        content.addSubview(stack)
        stack.addArrangedSubview(lockLabel)
        stack.addArrangedSubview(textLabel)
        content.layoutMargins = UIEdgeInsets(top: 0, left: horizontalPadding, bottom: bottomMargin, right: horizontalPadding)

        // Constraints (internal)
        scrimTop = scrim.topAnchor.constraint(equalTo: topAnchor, constant: clearHeadroom)
        scrimHeight = scrim.heightAnchor.constraint(equalToConstant: fadeHeight)
        stackBottom = stack.bottomAnchor.constraint(equalTo: content.layoutMarginsGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            // Scrim spans width; top/height adjustable via knobs
            scrimTop,
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrimHeight,

            // Solid content fills below scrim down to bottom
            content.topAnchor.constraint(equalTo: scrim.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Center stack; wrap by margins; honor bottom padding
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: content.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.layoutMarginsGuide.trailingAnchor),
            stackBottom!
        ])
    }

    // MARK: - Sizing

    /// Calculates how tall the overlay must be (scrim + solid) for a given width.
    /// Use this to size the *card* height:  cardHeight = cutoff (pts visible) + requiredOverlayHeight(for: width)
    func requiredOverlayHeight(for width: CGFloat) -> CGFloat {
        let textWidth = max(0, width - 2 * horizontalPadding)
        let lockH = lockLabel.intrinsicContentSize.height
        let textH = textLabel.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        let contentH = lockH + 12 + textH + bottomMargin + 12 // tiny safety
        return max(minOverlayHeight, clearHeadroom + fadeHeight + contentH)
    }
}

/// Gradient view (clear → white). We resize the gradient layer on layout
/// so it always matches the view’s bounds after Auto Layout changes.
private final class FadeScrimView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        let g = layer as! CAGradientLayer
        g.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.cgColor
        ]
        g.locations = [0.0, 0.6, 1.0]
        g.startPoint = CGPoint(x: 0.5, y: 0.0)
        g.endPoint   = CGPoint(x: 0.5, y: 1.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as! CAGradientLayer).frame = bounds
    }
}



// =======================================================
// MARK: BecomeAMemberViewController (pixel-cutoff version)
// =======================================================
//
// WHAT CHANGED:
//  • We no longer compute the cutoff by counting rows.
//  • You set a single number: `freeRevealHeight` (in points). That’s how much of the top
//    of the card stays visible. The overlay starts exactly at that y-offset.
//  • The card’s height is set to  freeRevealHeight + overlay.requiredOverlayHeight(for: cardWidth).
//
// HOW IT WORKS:
//  1) overlay.top = freeRevealHeight (pts from the card’s top).
//  2) eventsView.height = freeRevealHeight + requiredOverlayHeight
//     (so the scrim + lock/message fully fit).
//  3) The overlay is never hidden. If your content is shorter than the cutoff, you’ll
//     simply see no fade/lock until content grows past it (by design).
//
final class BecomeAMemberViewController: BaseSignupViewController {

    // MARK: - Dependencies
    private let viewModel = BecomeAMemberViewModel(
        repository: VideoAnalysisRepository(
            analysisAPI: NetworkManager(tokenManager: TokenManager())
        )
    )

    // MARK: - Header / summary
    private let laurel5StarsView = Laurel5StarsView()

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

    private let summarySectionTitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.text = "AI Analysis Summary"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

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
        l.font = .systemFont(ofSize: 18)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreRingView = ScoreRingView()

    private let summaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Scroll container
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Events card + overlay
    private let eventsView = UIView()
    private let eventsStack = UIStackView()
    private let overlay = EventsPaywallOverlay()

    // Constraints we mutate
    private var overlayTopConstraint: NSLayoutConstraint!
    private var eventsHeightConstraint: NSLayoutConstraint!

    // MARK: - Sticky CTA + spacer
    private let stickyCard = StickyCTAView()
    private let bottomSpacer = UIView()
    private var spacerHeight: NSLayoutConstraint!
    private let spacerExtra: CGFloat = 12

    // MARK: - Pixel-based cutoff (in points)
    /// Amount of content (in points) to leave visible at the top of the card.
    /// The overlay starts exactly after this many points.
    var freeRevealHeight: CGFloat = 100 {
        didSet {
            freeRevealHeight = max(0, freeRevealHeight)
            if isViewLoaded { repositionOverlay() }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        hideBackButton = true
        hidesProgressBar = true
        buildUI()
        super.viewDidLoad()

        buildEventsRows()
        repositionOverlay()

        // Sticky CTA (sibling of scroll view)
        view.addSubview(stickyCard)
        NSLayoutConstraint.activate([
            stickyCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyCard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Control indicator insets manually
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false

        stickyCard.ctaButton.addTarget(self, action: #selector(didTapStartFreeTrial), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let aiScore = Int(viewModel.getLastUpload()?.professionalScore ?? 0)
        scoreRingView.animate(to: aiScore, duration: 0.6)
        updateCardInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardInsets()
        repositionOverlay() // handle rotations / width changes
    }

    // MARK: - Build UI

    private func buildUI() {
        view.backgroundColor = .systemBackground

        summaryLabel.text = viewModel.getLastUpload()?.clipSummary
        summaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // Scroll + content
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Header/summary
        [titleLabel, subtitleLabel, laurel5StarsView, summarySectionTitle, summaryView, eventsView, bottomSpacer]
            .forEach { contentView.addSubview($0) }
        laurel5StarsView.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false

        summaryView.addSubview(summaryStack)
        summaryStack.addArrangedSubview(scoreRingView)
        summaryStack.addArrangedSubview(summaryLabel)
        scoreRingView.translatesAutoresizingMaskIntoConstraints = false

        // Events card
        eventsView.layer.borderWidth = 1
        eventsView.layer.cornerRadius = 12
        eventsView.layer.borderColor = UIColor.systemGray.cgColor
        eventsView.backgroundColor = .systemBackground
        eventsView.clipsToBounds = true
        eventsView.translatesAutoresizingMaskIntoConstraints = false

        // Events stack (your rows)
        eventsStack.axis = .vertical
        eventsStack.alignment = .fill
        eventsStack.spacing = 16
        eventsStack.translatesAutoresizingMaskIntoConstraints = false
        eventsView.addSubview(eventsStack)

        // Overlay
        overlay.translatesAutoresizingMaskIntoConstraints = false
        eventsView.addSubview(overlay)
        eventsView.bringSubviewToFront(overlay)
    }

    override func layout() {
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        spacerHeight = bottomSpacer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Scroll frame (full screen)
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

            // Header
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            laurel5StarsView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            laurel5StarsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            laurel5StarsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            summarySectionTitle.topAnchor.constraint(equalTo: laurel5StarsView.bottomAnchor, constant: 60),
            summarySectionTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summarySectionTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Summary card
            summaryView.topAnchor.constraint(equalTo: summarySectionTitle.bottomAnchor, constant: 15),
            summaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            summaryStack.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 10),
            summaryStack.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 10),
            summaryStack.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -10),
            summaryStack.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -10),

            scoreRingView.widthAnchor.constraint(equalToConstant: 70),
            scoreRingView.heightAnchor.constraint(equalToConstant: 70),

            // Events card
            eventsView.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 20),
            eventsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Rows inside card
            eventsStack.topAnchor.constraint(equalTo: eventsView.topAnchor, constant: 16),
            eventsStack.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor, constant: 16),
            eventsStack.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor, constant: -16),

            // Overlay pinned sides + bottom (we only move TOP)
            overlay.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: eventsView.bottomAnchor),

            // Bottom spacer so content doesn’t hide behind sticky card
            bottomSpacer.topAnchor.constraint(equalTo: eventsView.bottomAnchor, constant: 20),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            spacerHeight
        ])

        // Mutable constraints we update at runtime
        eventsHeightConstraint = eventsView.heightAnchor.constraint(equalToConstant: 260)
        eventsHeightConstraint.priority = .required
        eventsHeightConstraint.isActive = true

        overlayTopConstraint = overlay.topAnchor.constraint(equalTo: eventsView.topAnchor)
        overlayTopConstraint.isActive = true
    }

    // MARK: - Build event rows (your data)
    private func buildEventsRows() {
        eventsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for e in viewModel.getEvents() {
            let row = EventElement()
            row.configure(with: e)
            eventsStack.addArrangedSubview(row)
        }
        if let last = eventsStack.arrangedSubviews.last {
            // Helps the stack’s intrinsic height match the last row.
            last.bottomAnchor.constraint(equalTo: eventsStack.bottomAnchor).isActive = true
        }
    }

    // MARK: - Overlay placement (pixel cutoff)

    /// Places the overlay at `freeRevealHeight` points from the top of the card and
    /// resizes the card so the overlay (scrim + lock/message) fully fits below that cutoff.
    private func repositionOverlay() {
        eventsView.layoutIfNeeded()

        let width = eventsView.bounds.width
        guard width > 0 else { return } // need width to measure label wrapping

        overlay.isHidden = false // always show the paywall area

        let cutoffY = freeRevealHeight
        let overlayH = overlay.requiredOverlayHeight(for: width)

        overlayTopConstraint.constant = cutoffY
        eventsHeightConstraint.constant = cutoffY + overlayH

        eventsView.bringSubviewToFront(overlay)
        overlay.setNeedsLayout()
    }

    // MARK: - Sticky CTA spacing & indicator

    /// Makes space for the sticky card at the bottom of the scroll content,
    /// and makes the scroll indicator stop exactly at the sticky card’s top.
    private func updateCardInsets() {
        let cardHeight = stickyCard.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

        // Content spacer (so last content isn’t under the card)
        spacerHeight.constant = cardHeight + spacerExtra

        // Scrollbar track ends at the card’s top
        scrollView.verticalScrollIndicatorInsets.bottom = cardHeight
    }

    // MARK: - CTA action
    @objc private func didTapStartFreeTrial() {
        // Hook into your purchase flow
        print("Start Free Trial tapped")
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

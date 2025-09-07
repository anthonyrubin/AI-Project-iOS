import UIKit

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


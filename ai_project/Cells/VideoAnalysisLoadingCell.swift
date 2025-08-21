import UIKit

// MARK: - Helpers

/// Simple shimmering bar used as a skeleton line
final class ShimmerBar: UIView {
    private let gradient = CAGradientLayer()
    private let animationKey = "shimmer"

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        backgroundColor = UIColor(white: 0.92, alpha: 1)
        gradient.colors = [
            UIColor(white: 0.92, alpha: 1).cgColor,
            UIColor(white: 0.98, alpha: 1).cgColor,
            UIColor(white: 0.92, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.locations  = [0.0, 0.5, 1.0]
        layer.addSublayer(gradient)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        layer.cornerRadius = bounds.height / 2
    }

    func start() {
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1.0, -0.5, 0.0]
        anim.toValue   = [1.0, 1.5, 2.0]
        anim.duration  = 1.2
        anim.repeatCount = .infinity
        gradient.add(anim, forKey: animationKey)
    }
    func stop() { gradient.removeAnimation(forKey: animationKey) }
}

/// Circular progress ring + % label (white ring, rounded cap)
final class CircularProgressView: UIView {
    private let track = CAShapeLayer()
    private let ring  = CAShapeLayer()
    let percentLabel  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        track.strokeColor = UIColor(white: 1, alpha: 0.25).cgColor
        track.fillColor   = UIColor.clear.cgColor
        track.lineWidth   = 6
        layer.addSublayer(track)

        ring.strokeColor  = UIColor.white.cgColor
        ring.fillColor    = UIColor.clear.cgColor
        ring.lineWidth    = 6
        ring.lineCap      = .round
        ring.strokeEnd    = 0
        layer.addSublayer(ring)

        percentLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        percentLabel.textColor = UIColor(white: 1.0, alpha: 0.95)
        percentLabel.textAlignment = .center
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(percentLabel)
        NSLayoutConstraint.activate([
            percentLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let r = min(bounds.width, bounds.height) / 2 - ring.lineWidth/2
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: r,
                                startAngle: -.pi/2,
                                endAngle: 1.5 * .pi,
                                clockwise: true)
        track.path = path.cgPath
        ring.path  = path.cgPath
    }

    func setProgress(_ p: CGFloat) {
        ring.strokeEnd = max(0, min(1, p))
        percentLabel.text = "\(Int(round(p * 100)))%"
    }
}

// MARK: - The loading cell

final class VideoAnalysisLoadingCell: UITableViewCell {

    static let reuseId = "VideoAnalysisLoadingCell"

    // Card
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Left side (image + ring)
    private let leftImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = nil
        iv.backgroundColor = UIColor(white: 0.1, alpha: 0.15)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iv.setContentHuggingPriority(.defaultLow, for: .vertical)
        return iv
    }()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let progress = CircularProgressView()

    // Right side
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 2
        l.text = "Starting…"
        l.adjustsFontSizeToFitWidth = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let bar1 = ShimmerBar()
    private let bar2 = ShimmerBar()
    private let bar3 = ShimmerBar()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .tertiaryLabel
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Timers
    private var progressTimer: Timer?
    private var messageTimer: Timer?
    private var currentProgress: CGFloat = 0
    private let messages = [
        "Extracting keyframes...",
        "Calibrating motion...",
        "Detecting joints...",
        "Computing kinematics...",
        "Scoring technique...",
    ]
    private var messageIndex = 0

    // MARK: init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
        titleLabel.text = "Starting…"
        currentProgress = 0
        progress.setProgress(0)
        leftImageView.image = nil
        leftImageView.backgroundColor = UIColor(white: 0.1, alpha: 0.15)
    }

    // MARK: layout
    private func buildLayout() {
        contentView.addSubview(cardView)

        cardView.addSubview(leftImageView)
        leftImageView.addSubview(blur)
        leftImageView.addSubview(progress)
        blur.translatesAutoresizingMaskIntoConstraints = false
        progress.translatesAutoresizingMaskIntoConstraints = false

        // Title + chevron
        let titleAndChevron = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        titleAndChevron.axis = .horizontal
        titleAndChevron.alignment = .top
        titleAndChevron.spacing = 8
        titleAndChevron.translatesAutoresizingMaskIntoConstraints = false

        // Skeleton containers (avoid stack width fights)
        let s1 = UIView(); s1.translatesAutoresizingMaskIntoConstraints = false
        let s2 = UIView(); s2.translatesAutoresizingMaskIntoConstraints = false
        let s3 = UIView(); s3.translatesAutoresizingMaskIntoConstraints = false

        // Put bars inside containers
        for (container, bar) in [(s1, bar1), (s2, bar2), (s3, bar3)] {
            bar.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bar)
        }

        // Vertical stack of containers
        let skeletonStack = UIStackView(arrangedSubviews: [s1, s2, s3])
        skeletonStack.axis = .vertical
        skeletonStack.spacing = 12
        skeletonStack.alignment = .fill
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false

        // Right column
        let rightStack = UIStackView(arrangedSubviews: [titleAndChevron, skeletonStack])
        rightStack.axis = .vertical
        rightStack.spacing = 14
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rightStack)
        rightStack.setContentHuggingPriority(.required, for: .vertical)
        rightStack.setContentCompressionResistancePriority(.required, for: .vertical)
        
        
        leftImageView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        leftImageView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)  

        // Heights for skeleton rows
        NSLayoutConstraint.activate([
            s1.heightAnchor.constraint(equalToConstant: 12),
            s2.heightAnchor.constraint(equalTo: s1.heightAnchor),
            s3.heightAnchor.constraint(equalTo: s1.heightAnchor),

            // Bars fill first two rows
            bar1.topAnchor.constraint(equalTo: s1.topAnchor),
            bar1.leadingAnchor.constraint(equalTo: s1.leadingAnchor),
            bar1.trailingAnchor.constraint(equalTo: s1.trailingAnchor),
            bar1.bottomAnchor.constraint(equalTo: s1.bottomAnchor),

            bar2.topAnchor.constraint(equalTo: s2.topAnchor),
            bar2.leadingAnchor.constraint(equalTo: s2.leadingAnchor),
            bar2.trailingAnchor.constraint(equalTo: s2.trailingAnchor),
            bar2.bottomAnchor.constraint(equalTo: s2.bottomAnchor),

            // Third bar is short inside its container (no stack conflicts)
            bar3.topAnchor.constraint(equalTo: s3.topAnchor),
            bar3.leadingAnchor.constraint(equalTo: s3.leadingAnchor),
            bar3.bottomAnchor.constraint(equalTo: s3.bottomAnchor),
            bar3.widthAnchor.constraint(equalTo: s3.widthAnchor, multiplier: 0.3),
        ])

        // Core constraints (single vertical chain, no equal-heights)
        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Left image column follows card height
            leftImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            leftImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            leftImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            leftImageView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.30),

            // Blur & progress inside image
            blur.topAnchor.constraint(equalTo: leftImageView.topAnchor),
            blur.leadingAnchor.constraint(equalTo: leftImageView.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: leftImageView.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: leftImageView.bottomAnchor),

            progress.centerXAnchor.constraint(equalTo: leftImageView.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: leftImageView.centerYAnchor),
            progress.widthAnchor.constraint(equalTo: leftImageView.widthAnchor, multiplier: 0.55),
            progress.heightAnchor.constraint(equalTo: progress.widthAnchor),

            // Right column drives the height (top/bottom insets)
            rightStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            rightStack.leadingAnchor.constraint(equalTo: leftImageView.trailingAnchor, constant: 10),
            rightStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            rightStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            chevronView.widthAnchor.constraint(equalToConstant: 14)
        ])

        // Safety cap so the ring never drives a giant row
        let cap = progress.widthAnchor.constraint(lessThanOrEqualToConstant: 120)
        cap.priority = .defaultHigh
        cap.isActive = true
    }

    // MARK: - Public controls

    func configure(with snapshot: UIImage?) {
        if let snapshot = snapshot {
            leftImageView.image = snapshot
            leftImageView.backgroundColor = .clear
        } else {
            leftImageView.image = nil
            leftImageView.backgroundColor = UIColor(white: 0.1, alpha: 0.15)
        }
    }

    func startLoading() {
        [bar1, bar2, bar3].forEach { $0.start() }

        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            if currentProgress < 0.80 { currentProgress += 0.01 }
            else if currentProgress < 0.96 { currentProgress += 0.007 }
            else if currentProgress < 0.98 { currentProgress += 0.001 }
            else if currentProgress < 1.00 { currentProgress += 0.000001 }
            progress.setProgress(currentProgress)
        }

        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if messageIndex < messages.count - 1 {
                UIView.transition(with: titleLabel, duration: 0.25, options: .transitionCrossDissolve) {
                    self.titleLabel.text = self.messages[self.messageIndex]
                }
                messageIndex += 1
            }
        }
    }

    func updateProgress(_ progress: Double) {
        currentProgress = CGFloat(progress)
        self.progress.setProgress(currentProgress)
    }

    func stopLoading() {
        progressTimer?.invalidate()
        messageTimer?.invalidate()
        progressTimer = nil
        messageTimer = nil
        [bar1, bar2, bar3].forEach { $0.stop() }
    }
}

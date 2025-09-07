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


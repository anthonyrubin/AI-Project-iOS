import UIKit
import SkeletonView

final class VideoAnalysisCellNew1: UITableViewCell {

    static let reuseId = "VideoAnalysisCellNew1"

    // MARK: - Views
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let thumbView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner)
        iv.layer.cornerRadius = 16
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Top row: Lift name (left) + Stars (left) ... Chevron (right)
    private let sportLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .secondaryLabel
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let starLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .tertiaryLabel
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Middle row: Positive / Negative or "Perfect lift"
    private let verdictLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()

    // Bottom row: Date
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Init
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
        thumbView.image = nil
        sportLabel.text = nil
        starLabel.text = nil
        verdictLabel.text = nil
        dateLabel.text = nil
    }

    // MARK: - Layout
    private func buildLayout() {
        contentView.addSubview(cardView)
        cardView.addSubview(thumbView)

        // TOP: [ sportLabel | starLabel | spacer | chevron ]
        let topRow = UIStackView(arrangedSubviews: [sportLabel, starLabel, UIView(), chevronView])
        topRow.axis = .horizontal
        topRow.alignment = .firstBaseline
        topRow.spacing = 6

        // MIDDLE: verdict (Positive / Negative) or "Perfect lift"
        let verdictRow = UIStackView(arrangedSubviews: [verdictLabel, UIView()])
        verdictRow.axis = .horizontal
        verdictRow.alignment = .firstBaseline
        verdictRow.spacing = 6

        // BOTTOM: date
        let dateRow = UIStackView(arrangedSubviews: [dateLabel, UIView()])
        dateRow.axis = .horizontal
        dateRow.alignment = .firstBaseline
        dateRow.spacing = 6

        let rightStack = UIStackView(arrangedSubviews: [topRow, verdictRow, dateRow])
        rightStack.axis = .vertical
        rightStack.alignment = .fill
        rightStack.spacing = 8
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rightStack)

        NSLayoutConstraint.activate([
            // Card insets
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Thumbnail (≈30% width of card, full height)
            thumbView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.3),
            thumbView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            thumbView.topAnchor.constraint(equalTo: cardView.topAnchor),
            thumbView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Right stack constraints
            rightStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            rightStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            rightStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            rightStack.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: 10),

            chevronView.widthAnchor.constraint(equalToConstant: 14)
        ])
    }

    // MARK: - API
    /// Assumes VideoAnalysisObject has at least:
    /// - sport: String
    /// - liftScore: Int? (used as 0..5 stars)
    /// - strengths: [Item]? where Item has `title: String?`
    /// - areasForImprovement: [Item]?
    /// - createdAt: Date
    /// - video?.signedThumbnailUrl: String
    func configure(with analysis: VideoAnalysisObject) {
        // Top row: Lift name + stars (left of chevron)
        sportLabel.text = analysis.sport.capitalized

        let raw = analysis.liftScore ?? 0
        let stars = max(0, min(5, Int(raw)))
        starLabel.text = stars > 0 ? String(repeating: "⭐️", count: stars) : ""

        // Middle row: Positive / Negative, or "Perfect lift" if no negative
        let positiveTitle = analysis.strengthsArray?.first?.title
        let negativeTitle = analysis.areasForImprovementArray?.first?.title

        if let neg = negativeTitle {
            if let pos = positiveTitle {
                verdictLabel.text = "\(pos) • \(neg)"
            } else {
                verdictLabel.text = "Form review • \(neg)"
            }
        } else {
            verdictLabel.text = "Perfect lift"
        }

        // Bottom row: Date
        dateLabel.text = analysis.createdAt.longOrdinalString()

        // Thumbnail
        if let video = analysis.video {
            loadThumbnail(from: video.signedThumbnailUrl)
        } else {
            showSkeleton()
        }

        // Accessibility
        accessibilityLabel = "\(sportLabel.text ?? ""), \(stars) stars. \(verdictLabel.text ?? "")"
    }

    // MARK: - Helpers
    private func trimmedNonEmpty(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
              !t.isEmpty else { return nil }
        return t
    }

    // MARK: - Image loading
    private func loadThumbnail(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showPlaceholderImage()
            return
        }
        showSkeleton()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)
        session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error != nil { self?.showPlaceholderImage(); return }
                if let data = data, let image = UIImage(data: data) {
                    self?.hideSkeleton()
                    self?.thumbView.image = image
                } else {
                    self?.showPlaceholderImage()
                }
            }
        }.resume()
    }

    private func showPlaceholderImage() {
        hideSkeleton()
        thumbView.image = UIImage(named: "EmptyStateThumbnail")
        thumbView.alpha = 1.0
    }

    private func showSkeleton() { thumbView.showAnimatedGradientSkeleton() }
    private func hideSkeleton() { thumbView.hideSkeleton() }
}


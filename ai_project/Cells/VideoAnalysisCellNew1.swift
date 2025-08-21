import UIKit
import SkeletonView

enum SFScoreIcon: String {
    case zero       = "gauge.with.dots.needle.0percent"
    case thirtyThree = "gauge.with.dots.needle.33percent"
    case fifty      = "gauge.with.dots.needle.50percent"
    case sixtySix   = "gauge.with.dots.needle.67percent"
    case oneHundred = "gauge.with.dots.needle.100percent"
}

extension SFScoreIcon {
    /// Soft, eye-friendly red→green palette.
    var tintColor: UIColor {
        UIColor { trait in
            // Slightly dim in dark mode
            let dim: CGFloat = (trait.userInterfaceStyle == .dark) ? 0.88 : 1.0

            // HSB palette (hue in 0...1, gentle saturation/brightness)
            switch self {
            case .zero:        // soft red
                return UIColor(hue: 0.00, saturation: 0.58, brightness: 0.90 * dim, alpha: 1)
            case .thirtyThree: // coral
                return UIColor(hue: 0.06, saturation: 0.55, brightness: 0.92 * dim, alpha: 1) // ~20°
            case .fifty:       // amber/ochre
                return UIColor(hue: 0.12, saturation: 0.50, brightness: 0.92 * dim, alpha: 1) // ~45°
            case .sixtySix:    // olive-y green
                return UIColor(hue: 0.22, saturation: 0.45, brightness: 0.88 * dim, alpha: 1) // ~80°
            case .oneHundred:  // soft green (less harsh than systemGreen)
                return UIColor(hue: 0.33, saturation: 0.40, brightness: 0.85 * dim, alpha: 1) // ~120°
            }
        }
    }
}

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
        iv.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner,.layerMinXMaxYCorner)
        iv.layer.cornerRadius = 16
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 2
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .secondaryLabel
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()
    
    private let sportIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.tintColor = .secondaryLabel
        return iv
    }()
    
    private let sportLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let scoreBubble: UIView = {
        let v = UIView()
        v.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let scoreCaptionLabel: UILabel = {
        let l = UILabel()
        l.text = "AI Score"
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let scoreIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.tintColor = .secondaryLabel
        return iv
    }()
    
    private let scoreValueLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
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
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scoreBubble.layer.cornerRadius = scoreBubble.bounds.width / 2
        scoreBubble.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbView.image = nil
        sportIconView.image = nil
        titleLabel.text = nil
        sportLabel.text = nil
        scoreValueLabel.text = nil
        dateLabel.text = nil
    }
    
    // MARK: - Layout
    private func buildLayout() {
        contentView.addSubview(cardView)
        scoreBubble.addSubview(scoreValueLabel)
        
        // Top row: thumbnail + (title + chevron)
        let titleAndChevron = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        titleAndChevron.axis = .horizontal
        titleAndChevron.alignment = .top
        titleAndChevron.spacing = 8

        // Meta row: sport + score
        let sportRow = UIStackView(arrangedSubviews: [sportLabel, sportIconView])
        sportRow.axis = .horizontal
        sportRow.alignment = .center
        sportRow.spacing = 6
        
        let scoreRow = UIStackView(arrangedSubviews: [scoreCaptionLabel, scoreIconView])
        scoreRow.axis = .horizontal
        scoreRow.alignment = .center
        scoreRow.spacing = 8
        
        let metaRow = UIStackView(arrangedSubviews: [sportRow, scoreRow, UIView()])
        metaRow.axis = .horizontal
        metaRow.alignment = .center
        metaRow.spacing = 12
        
        // Shared row
        let dateRow = UIStackView(arrangedSubviews: [dateLabel, UIView()])
        dateRow.axis = .horizontal
        dateRow.alignment = .firstBaseline
        dateRow.spacing = 6
        
        let rightStack = UIStackView(arrangedSubviews: [titleAndChevron, metaRow, dateRow])
        rightStack.axis = .vertical
        rightStack.alignment = .fill
        rightStack.spacing = 8
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rightStack)
        
        rightStack.setContentHuggingPriority(.required, for: .vertical)
        rightStack.setContentCompressionResistancePriority(.required, for: .vertical)
        
        
        thumbView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        thumbView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        
        cardView.addSubview(thumbView)
        
        NSLayoutConstraint.activate([
            
//            scoreValueLabel.centerXAnchor.constraint(equalTo: scoreBubble.centerXAnchor),
//            scoreValueLabel.centerYAnchor.constraint(equalTo: scoreBubble.centerYAnchor),
            
//            scoreBubble.widthAnchor.constraint(equalToConstant: 32),
//            scoreBubble.heightAnchor.constraint(equalTo: scoreBubble.widthAnchor),
            
            sportIconView.heightAnchor.constraint(equalToConstant: 32),
            sportIconView.widthAnchor.constraint(equalToConstant: 32),
            
            scoreIconView.heightAnchor.constraint(equalToConstant: 32),
            scoreIconView.widthAnchor.constraint(equalToConstant: 32),
            
            thumbView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.3),
            thumbView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            thumbView.topAnchor.constraint(equalTo: cardView.topAnchor),
            thumbView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            rightStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            rightStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            rightStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            rightStack.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: 10),
            
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            chevronView.widthAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    // MARK: - API
    struct ViewModel {
        let thumbnail: UIImage?
        let summary: String
        let sportName: String
        let sportIcon: UIImage?   // pass an SF Symbol or your asset
        let score: Int
        let sharedBy: String
    }
    
    private func loadThumbnail(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showPlaceholderImage()
            return
        }
        
        // Show skeleton loading
        showSkeleton()
        
        // Create a session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        let session = URLSession(configuration: config)
        
        // Use session for image loading
        session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showPlaceholderImage()
                    return
                }
                
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
        // Hide skeleton and show placeholder
        hideSkeleton()
        thumbView.image = UIImage(named: "EmptyStateThumbnail")
        thumbView.alpha = 1.0
    }
    
    private func showSkeleton() {
        thumbView.showAnimatedGradientSkeleton()
    }
    
    private func hideSkeleton() {
        thumbView.hideSkeleton()
    }
    
    func configure(with analysis: VideoAnalysisObject) {
        // Set sport
    
        titleLabel.text = analysis.clipSummary
        sportLabel.text = analysis.sport.capitalized
        sportIconView.image = UIImage(systemName: "\(analysis.icon).circle.fill")
        
        // Set AI score
        if let score = analysis.professionalScore {
            let scoreOutOf100 = score * 10
            scoreValueLabel.text = "\(Int(scoreOutOf100))"
            
            if scoreOutOf100 <= 20 {
                scoreIconView.image = UIImage(systemName: SFScoreIcon.zero.rawValue)
                scoreIconView.tintColor = SFScoreIcon.zero.tintColor
            } else if scoreOutOf100 <= 45 {
                scoreIconView.image = UIImage(systemName: SFScoreIcon.thirtyThree.rawValue)
                scoreIconView.tintColor = SFScoreIcon.thirtyThree.tintColor
            } else if scoreOutOf100 <= 55 {
                scoreIconView.image = UIImage(systemName: SFScoreIcon.fifty.rawValue)
                scoreIconView.tintColor = SFScoreIcon.fifty.tintColor
            } else if scoreOutOf100 <= 85 {
                scoreIconView.image = UIImage(systemName: SFScoreIcon.sixtySix.rawValue)
                scoreIconView.tintColor = SFScoreIcon.sixtySix.tintColor
            } else {
                scoreIconView.image = UIImage(systemName: SFScoreIcon.oneHundred.rawValue)
                scoreIconView.tintColor = SFScoreIcon.oneHundred.tintColor
            }
        } else {
            scoreValueLabel.backgroundColor = .clear
            scoreValueLabel.text = ""
            scoreCaptionLabel.text = ""
        }
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        dateLabel.text = analysis.createdAt.longOrdinalString()
        
        // Load thumbnail
        if let video = analysis.video {
            loadThumbnail(from: video.signedThumbnailUrl)
        } else {
            showSkeleton()
        }
    }
}

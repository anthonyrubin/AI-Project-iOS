import UIKit

final class VideoAnalysisCellNew: UITableViewCell {
    
    static let reuseId = "VideoAnalysisCellNew"
    
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
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 4
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = UIColor(white: 0.25, alpha: 1)
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
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let scoreCaptionLabel: UILabel = {
        let l = UILabel()
        l.text = "Score"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private let scoreValueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .label
        return l
    }()
    
    private let dateCaptionLabel: UILabel = {
        let l = UILabel()
        l.text = "Shared by:"
        l.font = .italicSystemFont(ofSize: 15)
        l.textColor = .tertiaryLabel
        return l
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .systemBlue
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
        
        // Top row: thumbnail + (title + chevron)
        let titleAndChevron = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        titleAndChevron.axis = .horizontal
        titleAndChevron.alignment = .top
        titleAndChevron.spacing = 8
        
        let topRow = UIStackView(arrangedSubviews: [thumbView, titleAndChevron])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 12
        topRow.translatesAutoresizingMaskIntoConstraints = false
        
        // Meta row: sport + score
        let sportRow = UIStackView(arrangedSubviews: [sportLabel, sportIconView])
        sportRow.axis = .horizontal
        sportRow.alignment = .center
        sportRow.spacing = 6
        
        let scoreRow = UIStackView(arrangedSubviews: [scoreCaptionLabel, scoreValueLabel])
        scoreRow.axis = .horizontal
        scoreRow.alignment = .center
        scoreRow.spacing = 8
        
        let metaRow = UIStackView(arrangedSubviews: [sportRow, UIView(), scoreRow])
        metaRow.axis = .horizontal
        metaRow.alignment = .center
        metaRow.spacing = 12
        
        // Shared row
        let sharedRow = UIStackView(arrangedSubviews: [dateCaptionLabel, dateLabel])
        sharedRow.axis = .horizontal
        sharedRow.alignment = .firstBaseline
        sharedRow.spacing = 6
        
        // Vertical stack inside the card
        let vStack = UIStackView(arrangedSubviews: [topRow, metaRow, sharedRow])
        vStack.axis = .vertical
        vStack.alignment = .fill
        vStack.spacing = 12
        vStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(vStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            vStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            vStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            vStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            vStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            
            thumbView.widthAnchor.constraint(equalToConstant: 120),
            thumbView.heightAnchor.constraint(equalToConstant: 86), // ~4:3 look
            
            chevronView.widthAnchor.constraint(equalToConstant: 14)
        ])
        
        // Optional soft shadow like your screenshot
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.masksToBounds = false
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
        thumbView.hideSkeleton()
        thumbView.image = UIImage(named: "EmptyStateThumbnail")
        thumbView.alpha = 1.0
    }
    
    func configure(with analysis: VideoAnalysisObject) {
        // Set sport
        
        titleLabel.text = analysis.overallAnalysis
        sportLabel.text = analysis.sport.capitalized
        sportIconView.image = UIImage(systemName: analysis.icon)
        
        // Set AI score
        if let score = analysis.liftScore {
            scoreValueLabel.text = "\(score) / 100"
        } else {
            
        }
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        dateLabel.text = "\(formatter.string(from: analysis.createdAt))"
        
        // Load thumbnail
        if let video = analysis.video {
            loadThumbnail(from: video.signedThumbnailUrl)
        } else {
            showSkeleton()
        }
    }
}

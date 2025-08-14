import UIKit
import SkeletonView

class VideoAnalysisCell: UITableViewCell {
    
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let sportLabel = UILabel()
    private let scoreLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // Thumbnail image view
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = .systemGray5
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        
        // Title label
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Sport label
        sportLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sportLabel.textColor = .systemBlue
        sportLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sportLabel)
        
        // Score label
        scoreLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        scoreLabel.textColor = .systemGreen
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreLabel)
        
        // Date label
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        // Configure SkeletonView for thumbnail
        thumbnailImageView.isSkeletonable = true
        thumbnailImageView.skeletonCornerRadius = 8
        
        // Configure SkeletonView for labels
        titleLabel.isSkeletonable = true
        sportLabel.isSkeletonable = true
        scoreLabel.isSkeletonable = true
        dateLabel.isSkeletonable = true
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Thumbnail
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 96),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Sport
            sportLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            sportLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Score
            scoreLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: sportLabel.bottomAnchor, constant: 4),
            
            // Date
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),
            

        ])
    }
    
    func configure(with analysis: VideoAnalysisObject) {
        // Set text
        titleLabel.text = analysis.clipSummary.isEmpty ? "Video Analysis" : analysis.clipSummary
        sportLabel.text = analysis.sport.isEmpty ? "Unknown Sport" : analysis.sport
        
        if let score = analysis.professionalScore {
            scoreLabel.text = String(format: "Score: %.1f/10", score)
        } else {
            scoreLabel.text = "Score: N/A"
        }
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: analysis.createdAt)
        
        // Load thumbnail
        if let video = analysis.video, !video.thumbnailUrl.isEmpty {
            loadThumbnail(from: video.thumbnailUrl)
        } else {
            showSkeleton()
        }
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
                    self?.thumbnailImageView.image = image
                } else {
                    self?.showPlaceholderImage()
                }
            }
        }.resume()
    }
    
    private func showSkeleton() {
        // Clear any existing content
        thumbnailImageView.image = nil
        
        // Show skeleton loading on the thumbnail specifically
        thumbnailImageView.showAnimatedGradientSkeleton()
    }
    
    private func hideSkeleton() {
        // Hide skeleton loading
        thumbnailImageView.hideSkeleton()
    }
    
    private func showPlaceholderImage() {
        // Hide skeleton and show placeholder
        thumbnailImageView.hideSkeleton()
        thumbnailImageView.image = UIImage(named: "EmptyStateThumbnail")
        thumbnailImageView.alpha = 1.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        thumbnailImageView.hideSkeleton()
    }
}

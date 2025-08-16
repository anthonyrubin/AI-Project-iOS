import UIKit
import SkeletonView

final class DiagonalGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    override func layoutSubviews() {
        super.layoutSubviews()
        let g = layer as! CAGradientLayer
        g.colors = [
            UIColor(red: 33/255, green: 83/255,  blue: 124/255, alpha: 1).cgColor,
            UIColor(red: 74/255, green: 116/255, blue: 151/255, alpha: 1).cgColor
        ]
        g.locations = [0, 1]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
    }
}


class VideoAnalysisCell: UITableViewCell {
    
    // MARK: - UI Components
    private let cardView = DiagonalGradientView()
    private let thumbnailImageView = UIImageView()
    private let topStackView = UIStackView()
    private let sportLabel = UILabel()
    private let scoreLabel = UILabel()
    private let arrowImageView = UIImageView()
    private let dividerLine = UIView()
    private let bottomStackView = UIStackView()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    
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
        backgroundColor = .clear
        
        // Card view - dark blue background
        cardView.backgroundColor = UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0) // Dark blue
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // Thumbnail image view - small square-ish
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = .systemGray5
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(thumbnailImageView)
        
        // Top stack view for sport and score
        topStackView.axis = .vertical
        topStackView.spacing = 8
        topStackView.alignment = .leading
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(topStackView)
        
        // Sport label - white text
        sportLabel.font = .systemFont(ofSize: 16, weight: .medium)
        sportLabel.textColor = .white
        sportLabel.translatesAutoresizingMaskIntoConstraints = false
        topStackView.addArrangedSubview(sportLabel)
        
        // Score label - white text
        scoreLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        scoreLabel.textColor = .white
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        topStackView.addArrangedSubview(scoreLabel)
        
        // Arrow image view - white chevron
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .white
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(arrowImageView)
        
        // Divider line
        dividerLine.backgroundColor = .white
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dividerLine)
        
        // Bottom stack view for date and duration
        bottomStackView.axis = .vertical
        bottomStackView.spacing = 8
        bottomStackView.alignment = .leading
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bottomStackView)
        
        // Date label - white text
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = .white
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.addArrangedSubview(dateLabel)
        
        // Duration label - white text
        durationLabel.font = .systemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = .white
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.addArrangedSubview(durationLabel)
        
        // Configure SkeletonView for thumbnail
        thumbnailImageView.isSkeletonable = true
        thumbnailImageView.skeletonCornerRadius = 12
        
        // Configure SkeletonView for card and labels
        cardView.isSkeletonable = true
        cardView.skeletonCornerRadius = 12
        sportLabel.isSkeletonable = true
        scoreLabel.isSkeletonable = true
        durationLabel.isSkeletonable = true
        dateLabel.isSkeletonable = true
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Card view
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Thumbnail - small square-ish on left
            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Top stack view (sport and score)
            topStackView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            topStackView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            topStackView.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -16),
            
            // Arrow - center right
            arrowImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            arrowImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Divider line
            dividerLine.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            dividerLine.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dividerLine.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 20),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Bottom stack view (date and duration)
            bottomStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bottomStackView.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 20),
            bottomStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            bottomStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with analysis: VideoAnalysisObject) {
        // Set sport
        sportLabel.text = analysis.sport.isEmpty ? "Unknown Sport" : analysis.sport
        
        // Set AI score
        if let score = analysis.professionalScore {
            scoreLabel.text = String(format: "AI Score: %.0f", score * 10) // Convert to 0-100 scale
        } else {
            scoreLabel.text = "AI Score: N/A"
        }
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        dateLabel.text = "Date: \(formatter.string(from: analysis.createdAt))"
        
        // Set duration - only show if available
        if let video = analysis.video, video.hasDuration {
            durationLabel.text = "Duration: \(video.formattedDuration)"
        } else {
            durationLabel.text = ""
        }
        
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
        
        // Show skeleton loading on the card
        cardView.showAnimatedGradientSkeleton()
    }
    
    private func hideSkeleton() {
        // Hide skeleton loading
        cardView.hideSkeleton()
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
        cardView.hideSkeleton()
    }
}


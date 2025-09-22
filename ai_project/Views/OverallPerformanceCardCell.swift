import UIKit

class OverallPerformanceCardCell: UITableViewCell {
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let analysisLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        // Card view
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Analysis label
        analysisLabel.font = .systemFont(ofSize: 16, weight: .regular)
        analysisLabel.textColor = .label
        analysisLabel.numberOfLines = 0
        analysisLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(cardView)
        cardView.addSubview(analysisLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Card view
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Analysis label
            analysisLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            analysisLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            analysisLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            analysisLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with analysis: VideoAnalysisObject) {
        analysisLabel.text = analysis.overallAnalysis
    }
}

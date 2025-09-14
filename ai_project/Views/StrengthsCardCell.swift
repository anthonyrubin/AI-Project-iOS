import UIKit

class StrengthsCardCell: UITableViewCell {
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let strengthsStackView = UIStackView()
    
    // MARK: - Initialization
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
        
        // Title label
        titleLabel.text = "Strengths"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view
        strengthsStackView.axis = .vertical
        strengthsStackView.spacing = 12
        strengthsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(strengthsStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Card view
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Stack view
            strengthsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            strengthsStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            strengthsStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            strengthsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with strengths: [Strength]) {
        // Clear existing views
        strengthsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add strength views
        for strength in strengths {
            let strengthView = createStrengthView(strength: strength)
            strengthsStackView.addArrangedSubview(strengthView)
        }
    }
    
    private func createStrengthView(strength: Strength) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = strength.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let analysisLabel = UILabel()
        analysisLabel.text = strength.analysis
        analysisLabel.font = .systemFont(ofSize: 14, weight: .regular)
        analysisLabel.textColor = .secondaryLabel
        analysisLabel.numberOfLines = 0
        analysisLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(analysisLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            analysisLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            analysisLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            analysisLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            analysisLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
}

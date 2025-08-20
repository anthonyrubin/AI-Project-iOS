import UIKit
import SkeletonView

class EmptyStateAnalysisCell: UITableViewCell {
    
    // MARK: - UI Components
    private let emptyStateImageView = UIImageView()
    private let textView = UILabel()
    private let cardView = UIView()
    
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
        
        cardView.backgroundColor = UIColor.white
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.addSubview(cardView)

        emptyStateImageView.contentMode = .scaleAspectFill
        emptyStateImageView.clipsToBounds = true
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.image = UIImage(named: "EmptyStatePreviewCard")
        emptyStateImageView.contentMode = .scaleAspectFit
        cardView.addSubview(emptyStateImageView)

        textView.font = .systemFont(ofSize: 16, weight: .medium)
        textView.textColor = UIColor.lightGray
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Start your first analysis by tapping Start Session"
        textView.numberOfLines = 2
        textView.textAlignment = .center
        cardView.addSubview(textView)

        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            emptyStateImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            emptyStateImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.9),
            
            textView.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }
}



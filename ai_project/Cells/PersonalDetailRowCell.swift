import UIKit

final class PersonalDetailRowCell: UITableViewCell {
    
    enum Position { case single, first, middle, last }
    
    // Public API
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    func apply(position: Position) {
        // Corner rounding per row position
        switch position {
        case .single:
            container.layer.cornerRadius = 16
            container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                             .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            separator.isHidden = true
        case .first:
            container.layer.cornerRadius = 16
            container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            separator.isHidden = false
        case .middle:
            container.layer.cornerRadius = 0
            separator.isHidden = false
        case .last:
            container.layer.cornerRadius = 16
            container.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            separator.isHidden = true
        }
    }
    
    // MARK: - UI
    private let container = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let pencilIconView = UIImageView()
    private let separator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        container.backgroundColor = .white
        container.layer.cornerCurve = .continuous
        container.layer.masksToBounds = true
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        container.layer.borderWidth = 1 / UIScreen.main.scale
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        // Title label (left side)
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle label (right side)
        subtitleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.textColor = .label
        subtitleLabel.textAlignment = .right
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Pencil icon (far right)
        pencilIconView.image = UIImage(systemName: "pencil")
        pencilIconView.tintColor = .systemGray
        pencilIconView.contentMode = .scaleAspectFit
        pencilIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all elements to container
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(pencilIconView)
        container.addSubview(separator)
        
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container constraints
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Title label (left side)
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // Pencil icon (far right)
            pencilIconView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            pencilIconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            pencilIconView.widthAnchor.constraint(equalToConstant: 16),
            pencilIconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Subtitle label (between title and pencil icon)
            subtitleLabel.trailingAnchor.constraint(equalTo: pencilIconView.leadingAnchor, constant: -8),
            subtitleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            // Container height
            container.heightAnchor.constraint(equalToConstant: 56),
            
            // Separator
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}

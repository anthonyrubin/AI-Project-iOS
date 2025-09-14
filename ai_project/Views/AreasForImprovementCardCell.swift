import UIKit

class AreasForImprovementCardCell: UITableViewCell {
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let areasStackView = UIStackView()
    
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
        titleLabel.text = "Areas for Improvement"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view
        areasStackView.axis = .vertical
        areasStackView.spacing = 16
        areasStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(areasStackView)
        
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
            areasStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            areasStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            areasStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            areasStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with areas: [AreaForImprovement]) {
        // Clear existing views
        areasStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add area views
        for area in areas {
            let areaView = createAreaView(area: area)
            areasStackView.addArrangedSubview(areaView)
        }
    }
    
    private func createAreaView(area: AreaForImprovement) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = area.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let analysisLabel = UILabel()
        analysisLabel.text = area.analysis
        analysisLabel.font = .systemFont(ofSize: 14, weight: .regular)
        analysisLabel.textColor = .secondaryLabel
        analysisLabel.numberOfLines = 0
        analysisLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Expandable sections for tips and drills
        let tipsSection = createExpandableSection(title: "Actionable Tips", items: area.actionable_tips)
        let drillsSection = createExpandableSection(title: "Corrective Drills", items: area.corrective_drills)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(analysisLabel)
        containerView.addSubview(tipsSection)
        containerView.addSubview(drillsSection)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            analysisLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            analysisLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            analysisLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            tipsSection.topAnchor.constraint(equalTo: analysisLabel.bottomAnchor, constant: 8),
            tipsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tipsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            drillsSection.topAnchor.constraint(equalTo: tipsSection.bottomAnchor, constant: 8),
            drillsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            drillsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            drillsSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createExpandableSection(title: String, items: [String]) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let headerButton = UIButton(type: .system)
        headerButton.setTitle("\(title) (\(items.count))", for: .normal)
        headerButton.setTitleColor(.systemBlue, for: .normal)
        headerButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        headerButton.contentHorizontalAlignment = .left
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.isHidden = true // Initially hidden
        
        // Add items to stack view
        for (index, item) in items.enumerated() {
            let itemLabel = UILabel()
            itemLabel.text = "• \(item)"
            itemLabel.font = .systemFont(ofSize: 13, weight: .regular)
            itemLabel.textColor = .secondaryLabel
            itemLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(itemLabel)
        }
        
        // Add tap gesture to toggle visibility
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSection(_:)))
        headerButton.addGestureRecognizer(tapGesture)
        
        containerView.addSubview(headerButton)
        containerView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            headerButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerButton.heightAnchor.constraint(equalToConstant: 30),
            
            contentStackView.topAnchor.constraint(equalTo: headerButton.bottomAnchor, constant: 4),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Store references for toggling
        headerButton.tag = contentStackView.hash
        contentStackView.tag = headerButton.hash
        
        return containerView
    }
    
    @objc private func toggleSection(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton,
              let stackView = viewWithTag(button.tag) as? UIStackView else { return }
        
        let isHidden = stackView.isHidden
        stackView.isHidden = !isHidden
        
        // Update button title to show expand/collapse state
        let currentTitle = button.title(for: .normal) ?? ""
        if isHidden {
            button.setTitle(currentTitle.replacingOccurrences(of: "▼", with: "▲"), for: .normal)
        } else {
            button.setTitle(currentTitle.replacingOccurrences(of: "▲", with: "▼"), for: .normal)
        }
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}

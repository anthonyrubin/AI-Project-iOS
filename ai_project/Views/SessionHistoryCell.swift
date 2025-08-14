import UIKit

class SessionHistoryCell: UITableViewCell {
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let totalRecordingsStackView = UIStackView()
    private let totalRecordingsBadge = UIView()
    private let totalRecordingsLabel = UILabel()
    private let totalRecordingsTextLabel = UILabel()
    
    private let averageScoreStackView = UIStackView()
    private let averageScoreBadge = UIView()
    private let averageScoreLabel = UILabel()
    private let averageScoreTextLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Card view
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // Total recordings section
        totalRecordingsStackView.axis = .horizontal
        totalRecordingsStackView.spacing = 12
        totalRecordingsStackView.alignment = .center
        totalRecordingsStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(totalRecordingsStackView)
        
        // Total recordings badge
        totalRecordingsBadge.backgroundColor = UIColor.systemBlue
        totalRecordingsBadge.layer.cornerRadius = 12
        totalRecordingsBadge.translatesAutoresizingMaskIntoConstraints = false
        totalRecordingsStackView.addArrangedSubview(totalRecordingsBadge)
        
        // Total recordings label
        totalRecordingsLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        totalRecordingsLabel.textColor = .white
        totalRecordingsLabel.textAlignment = .center
        totalRecordingsLabel.translatesAutoresizingMaskIntoConstraints = false
        totalRecordingsBadge.addSubview(totalRecordingsLabel)
        
        // Total recordings text
        totalRecordingsTextLabel.font = .systemFont(ofSize: 16, weight: .medium)
        totalRecordingsTextLabel.textColor = .label
        totalRecordingsTextLabel.text = "Total Recordings (Month to Date)"
        totalRecordingsTextLabel.translatesAutoresizingMaskIntoConstraints = false
        totalRecordingsStackView.addArrangedSubview(totalRecordingsTextLabel)
        
        // Average score section
        averageScoreStackView.axis = .horizontal
        averageScoreStackView.spacing = 12
        averageScoreStackView.alignment = .center
        averageScoreStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(averageScoreStackView)
        
        // Average score badge
        averageScoreBadge.backgroundColor = UIColor.systemGreen
        averageScoreBadge.layer.cornerRadius = 12
        averageScoreBadge.translatesAutoresizingMaskIntoConstraints = false
        averageScoreStackView.addArrangedSubview(averageScoreBadge)
        
        // Average score label
        averageScoreLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        averageScoreLabel.textColor = .white
        averageScoreLabel.textAlignment = .center
        averageScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        averageScoreBadge.addSubview(averageScoreLabel)
        
        // Average score text
        averageScoreTextLabel.font = .systemFont(ofSize: 16, weight: .medium)
        averageScoreTextLabel.textColor = .label
        averageScoreTextLabel.text = "AI Average Score (All Time)"
        averageScoreTextLabel.translatesAutoresizingMaskIntoConstraints = false
        averageScoreStackView.addArrangedSubview(averageScoreTextLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Card view
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Total recordings section
            totalRecordingsStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            totalRecordingsStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            totalRecordingsStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            
            // Total recordings badge
            totalRecordingsBadge.widthAnchor.constraint(equalToConstant: 60),
            totalRecordingsBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Total recordings label
            totalRecordingsLabel.centerXAnchor.constraint(equalTo: totalRecordingsBadge.centerXAnchor),
            totalRecordingsLabel.centerYAnchor.constraint(equalTo: totalRecordingsBadge.centerYAnchor),
            
            // Average score section
            averageScoreStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            averageScoreStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            averageScoreStackView.topAnchor.constraint(equalTo: totalRecordingsStackView.bottomAnchor, constant: 16),
            averageScoreStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            // Average score badge
            averageScoreBadge.widthAnchor.constraint(equalToConstant: 60),
            averageScoreBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Average score label
            averageScoreLabel.centerXAnchor.constraint(equalTo: averageScoreBadge.centerXAnchor),
            averageScoreLabel.centerYAnchor.constraint(equalTo: averageScoreBadge.centerYAnchor)
        ])
    }
    
    func configure(totalMinutes: Int, averageScore: Double) {
        // Format total minutes
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            totalRecordingsLabel.text = "\(hours)h \(minutes)m"
        } else {
            totalRecordingsLabel.text = "\(totalMinutes)m"
        }
        
        // Format average score as percentage
        let percentage = Int(averageScore * 10) // Convert 0-10 scale to 0-100
        averageScoreLabel.text = "\(percentage)%"
    }
}

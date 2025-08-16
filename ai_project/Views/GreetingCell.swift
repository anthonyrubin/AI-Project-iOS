import UIKit

class GreetingCell: UITableViewCell {
    
    private let greetingLabel = UILabel()
    
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
        
        greetingLabel.font = .systemFont(ofSize: 28, weight: .bold)
        greetingLabel.textColor = .label
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(greetingLabel)
        
        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            greetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            greetingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with user: UserObject?) {
        if let firstName = user?.firstName, !firstName.isEmpty {
            greetingLabel.text = "Hello, \(firstName)"
        } else {
            greetingLabel.text = "Hello, User"
        }
    }
}


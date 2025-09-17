import UIKit

final class PersonalDetailRowCell: UITableViewCell {

    enum Position { case single, first, middle, last }

    // MARK: - Public API
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    func apply(position: Position) {
        // Rounded corners only on outer rows; show bottom separator only between rows
        switch position {
        case .single:
            container.layer.cornerRadius = corner
            container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                             .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            separator.isHidden = true

        case .first:
            container.layer.cornerRadius = corner
            container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            separator.isHidden = false

        case .middle:
            container.layer.cornerRadius = 0
            container.layer.maskedCorners = []
            separator.isHidden = false

        case .last:
            container.layer.cornerRadius = corner
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

    // MARK: - Tunables
    private let corner: CGFloat = 16
    private let hairline: CGFloat = 1 / UIScreen.main.scale
    private let minRowHeight: CGFloat = 56

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = .white
        container.layer.cornerCurve = .continuous
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.textColor = .label
        subtitleLabel.textAlignment = .right
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        pencilIconView.image = UIImage(systemName: "pencil")
        pencilIconView.tintColor = .systemGray
        pencilIconView.contentMode = .scaleAspectFit
        pencilIconView.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = UIColor.separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(pencilIconView)
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            // Container inset (matches your screenshot)
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: minRowHeight),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            // Icon
            pencilIconView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            pencilIconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            pencilIconView.widthAnchor.constraint(equalToConstant: 20),
            pencilIconView.heightAnchor.constraint(equalToConstant: 20),

            // Subtitle
            subtitleLabel.trailingAnchor.constraint(equalTo: pencilIconView.leadingAnchor, constant: -8),
            subtitleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

            // Inset bottom separator (only shown on first/middle)
            separator.heightAnchor.constraint(equalToConstant: hairline),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
}


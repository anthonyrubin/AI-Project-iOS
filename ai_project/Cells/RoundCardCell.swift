import UIKit

final class RoundCardCell: UITableViewCell {

    enum Position { case single, first, middle, last }

    // Public API
    func configure(icon: UIImage?, title: String) {
        iconView.image = icon
        titleLabel.text = title
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
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = .white
        container.layer.cornerCurve = .continuous
        container.layer.masksToBounds = true     // keep corners crisp
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        container.layer.borderWidth = 1 / UIScreen.main.scale
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel, chevron])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 14
        h.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)

        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            // “Card” insets from table edges
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Row content
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            // Inner separator (shown for .first/.middle)
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}

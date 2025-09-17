// RoundCardCell (drop-in) — matches the other cell’s height and has ONLY the inset bottom separator.

import UIKit

final class RoundCardCell: UITableViewCell {

    enum Position { case single, first, middle, last }

    // Public API
    func configure(icon: UIImage?, title: String) {
        iconView.image = icon
        titleLabel.text = title
    }

    func apply(position: Position) {
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
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let separator = UIView()

    // MARK: - Tunables
    private let corner: CGFloat = 16
    private let hairline: CGFloat = 1 / UIScreen.main.scale
    private let minRowHeight: CGFloat = 56

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
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 14
        h.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)

        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            // Card inset
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Min height to match other cell
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: minRowHeight),

            // Row content
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            // Inset bottom separator (shown for .first/.middle)
            separator.heightAnchor.constraint(equalToConstant: hairline),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
}


import UIKit

final class StandardTitleCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        // Use layoutMarginsGuide so it breathes nicely
        let g = contentView.layoutMarginsGuide
        contentView.directionalLayoutMargins = .init(top: 0, leading: 20, bottom: 10, trailing: 20)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: g.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = true
    }

    /// Configure once; no constraints here.
    func configure(with title: String, subtitle: String? = nil, fontSize: CGFloat = 28) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: fontSize, weight: .bold)

        if let sub = subtitle, !sub.isEmpty {
            subtitleLabel.text = sub
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.text = nil
            subtitleLabel.isHidden = true
        }
    }
}


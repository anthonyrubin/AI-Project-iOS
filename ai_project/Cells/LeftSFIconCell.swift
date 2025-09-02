
import UIKit

struct LeftSFIconCellData: Hashable {
    let title: String
    let iconName: String

    
    init(title: String, iconName: String) {
        self.title = title
        self.iconName = iconName
    }
}

// MARK: - Cell
final class LeftSFIconCell: UITableViewCell {
    static let reuseID = "LeftSFIconCell"

    private let card = UIView()
    private let iconCircle = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    private let normalBG = UIColor.label.withAlphaComponent(0.05)
    private let selectedBG = UIColor.label
    private let normalTitle = UIColor.label
    private let selectedTitle = UIColor.systemBackground

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // ✅ kill default highlight/selection overlay & make backgrounds clean
        selectionStyle = .none
        selectedBackgroundView = UIView()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false

        card.backgroundColor = normalBG
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        iconCircle.backgroundColor = .systemBackground
        iconCircle.layer.cornerRadius = 18
        iconCircle.layer.cornerCurve = .continuous
        iconCircle.clipsToBounds = true
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconCircle)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label // keep visible in both states
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(iconView)

        titleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        titleLabel.textColor = normalTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            iconCircle.widthAnchor.constraint(equalToConstant: 36),
            iconCircle.heightAnchor.constraint(equalToConstant: 36),
            iconCircle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconCircle.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // ✅ hard reset
        setSelectedAppearance(false, animated: false)
        iconView.tintColor = .label
        iconCircle.backgroundColor = .systemBackground
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        // Disable UIKit’s default selection visuals (we handle it)
        super.setSelected(false, animated: false)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // Optional: a tiny press feedback on the card without changing colors
        let alpha: CGFloat = highlighted ? 0.96 : 1.0
        if animated {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.card.alpha = alpha
            }
        } else {
            card.alpha = alpha
        }
    }

    func configure(_ item: LeftSFIconCellData, selected: Bool) {
        titleLabel.text = item.title
        if let sys = UIImage(systemName: item.iconName)?.withRenderingMode(.alwaysTemplate) {
            iconView.image = sys
        } else {
            iconView.image = UIImage(named: item.iconName)?.withRenderingMode(.alwaysOriginal)
        }
        setSelectedAppearance(selected, animated: false)
    }

    func setSelectedAppearance(_ selected: Bool, animated: Bool) {
        let updates = {
            self.card.backgroundColor = selected ? self.selectedBG : self.normalBG
            self.titleLabel.textColor = selected ? self.selectedTitle : self.normalTitle
            // keep icon visible (or invert both icon & circle together if you prefer)
            self.iconView.tintColor = .label
            self.iconCircle.backgroundColor = .systemBackground
        }
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }
}

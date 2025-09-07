import UIKit

// Optional: keep this here for a self-contained file.
// You can move it to its own file if you prefer.
final class StickyCTAView: UIView {
    let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Join elite athletes worldwide"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(
            "Become a member",
            for: .normal
        )
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .label
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.layer.cornerRadius = 28
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    let finePrint: UILabel = {
        let l = UILabel()
        l.text = "Elite coaching in your pocket for only $19.99 / month"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 24
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 20
        layer.shadowOffset = .init(width: 0, height: -2)

        addSubview(titleLabel)
        addSubview(ctaButton)
        addSubview(finePrint)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            ctaButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            ctaButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 56),

            finePrint.topAnchor.constraint(equalTo: ctaButton.bottomAnchor, constant: 10),
            finePrint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            finePrint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            finePrint.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}



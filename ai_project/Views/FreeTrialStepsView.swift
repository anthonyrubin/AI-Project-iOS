import UIKit

struct FreeTrialStepsData {
    let icon: String
    let title: String?
    let subtitle: String
}

import UIKit

// Uses your existing:
// struct FreeTrialStepsData { let icon: String; let title: String?; let subtitle: String }

final class FreeTrialStepsView: UIView {

    // MARK: Config (tweak as needed)
    var circleDiameter: CGFloat = 40 { didSet { rebuild() } }
    var iconPointSize: CGFloat = 20 { didSet { rebuild() } }
    var rowSpacing: CGFloat = 12 { didSet { vstack.spacing = rowSpacing } }
    var hSpacing: CGFloat = 15 { didSet { rebuild() } }
    var contentInsets: UIEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10) { didSet { updateInsets() } }

    var circleFillColor: UIColor = .secondarySystemBackground { didSet { rebuild() } }
    var circleBorderColor: UIColor? = nil { didSet { rebuild() } } // e.g. .separator
    var circleBorderWidth: CGFloat = 0 { didSet { rebuild() } }
    var iconTint: UIColor = .black { didSet { rebuild() } }

    // MARK: Data
    private var data: [FreeTrialStepsData]
    private let vstack = UIStackView()

    // MARK: Init
    init(steps: [FreeTrialStepsData]) {
        self.data = steps
        super.init(frame: .zero)
        setupBase()
        buildRows()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Public
    func reload(steps: [FreeTrialStepsData]) {
        self.data = steps
        rebuild()
    }

    // MARK: Layout builders
    private func setupBase() {
        translatesAutoresizingMaskIntoConstraints = false

        vstack.axis = .vertical
        vstack.spacing = rowSpacing
        vstack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vstack)

        updateInsets()
    }

    private func updateInsets() {
        // Remove any existing inset constraints and re-pin
        NSLayoutConstraint.deactivate(constraints.filter {
            ($0.firstItem as? UIView) == vstack || ($0.secondItem as? UIView) == vstack
        })
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
            vstack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom)
        ])
    }

    private func rebuild() {
        vstack.arrangedSubviews.forEach { vstack.removeArrangedSubview($0); $0.removeFromSuperview() }
        buildRows()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func buildRows() {
        for step in data {
            vstack.addArrangedSubview(makeRow(for: step))
        }
    }

    private func makeRow(for step: FreeTrialStepsData) -> UIStackView {
        // Circle container
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = circleFillColor
        iconContainer.layer.cornerRadius = circleDiameter / 2
        iconContainer.layer.masksToBounds = true
        if let border = circleBorderColor {
            iconContainer.layer.borderColor = border.cgColor
            iconContainer.layer.borderWidth = circleBorderWidth
        }

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: circleDiameter),
            iconContainer.heightAnchor.constraint(equalToConstant: circleDiameter)
        ])
        iconContainer.setContentHuggingPriority(.required, for: .horizontal)
        iconContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Icon image
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = iconTint
        iconView.image = sizedIcon(named: step.icon, pointSize: iconPointSize)

        iconContainer.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconPointSize),
            iconView.heightAnchor.constraint(equalToConstant: iconPointSize)
        ])

        // Text stack
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        if let t = step.title, !t.isEmpty {
            let title = UILabel()
            title.text = t
            title.font = .systemFont(ofSize: 18, weight: .medium)
            title.numberOfLines = 0
            title.lineBreakMode = .byWordWrapping
            title.setContentCompressionResistancePriority(.required, for: .vertical)
            textStack.addArrangedSubview(title)
        }

        let subtitle = UILabel()
        subtitle.text = step.subtitle
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.setContentCompressionResistancePriority(.required, for: .vertical)
        textStack.addArrangedSubview(subtitle)

        // Row
        let row = UIStackView(arrangedSubviews: [iconContainer, textStack])
        row.axis = .horizontal
        row.alignment = .top              // top-align text with the circle; change to .center if preferred
        row.spacing = hSpacing
        row.translatesAutoresizingMaskIntoConstraints = false

        return row
    }

    // MARK: Helpers
    private func sizedIcon(named name: String, pointSize: CGFloat) -> UIImage? {
        if let sym = UIImage(systemName: name) {
            let cfg = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            return sym.applyingSymbolConfiguration(cfg)?.withRenderingMode(.alwaysTemplate)
        }
        // Fallback to asset by name
        if let img = UIImage(named: name) {
            // Keep template behavior so tintColor applies
            return img.withRenderingMode(.alwaysTemplate)
        }
        return nil
    }
}

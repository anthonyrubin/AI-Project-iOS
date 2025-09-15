import UIKit

final class AreasForImprovementCardCell: UITableViewCell {

    // MARK: - UI
    private let cardView = UIView()
    private let areasStackView = UIStackView()

    // Keep track of expandable sections
    private var expandables: [UIButton: UIStackView] = [:]

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        contentView.addSubview(cardView)

        // Stack of areas
        areasStackView.translatesAutoresizingMaskIntoConstraints = false
        areasStackView.axis = .vertical
        areasStackView.spacing = 16
        cardView.addSubview(areasStackView)

        // Constraints (pin stack INSIDE card)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            areasStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            areasStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            areasStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            areasStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Public
    func configure(with areas: [AreaForImprovement]) {
        // Clear old content & mapping
        expandables.removeAll()
        areasStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Build area blocks
        for area in areas {
            areasStackView.addArrangedSubview(makeAreaBlock(for: area))
        }
    }

    // MARK: - Builders
    private func makeAreaBlock(for area: AreaForImprovement) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = area.title
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = .label
        title.numberOfLines = 0

        let analysis = UILabel()
        analysis.translatesAutoresizingMaskIntoConstraints = false
        analysis.text = area.analysis
        analysis.font = .systemFont(ofSize: 14, weight: .regular)
        analysis.textColor = .secondaryLabel
        analysis.numberOfLines = 0

        let tips = makeExpandableSection(title: "Actionable Tips", items: area.actionable_tips)
        let drills = makeExpandableSection(title: "Corrective Drills", items: area.corrective_drills)

        container.addSubview(title)
        container.addSubview(analysis)
        container.addSubview(tips.container)
        container.addSubview(drills.container)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            analysis.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            analysis.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            analysis.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            tips.container.topAnchor.constraint(equalTo: analysis.bottomAnchor, constant: 8),
            tips.container.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tips.container.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            drills.container.topAnchor.constraint(equalTo: tips.container.bottomAnchor, constant: 8),
            drills.container.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            drills.container.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            drills.container.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Track for toggling
        expandables[tips.button] = tips.content
        expandables[drills.button] = drills.content

        return container
    }

    private func makeExpandableSection(title: String, items: [String]) -> (container: UIView, button: UIButton, content: UIStackView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.setTitle("\(title) (\(items.count))  ▼", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(didTapExpandable(_:)), for: .touchUpInside)

        let content = UIStackView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 4
        content.isHidden = true // collapsed initially

        for item in items {
            let label = UILabel()
            label.text = "• \(item)"
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            content.addArrangedSubview(label)
        }

        container.addSubview(button)
        container.addSubview(content)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.heightAnchor.constraint(equalToConstant: 30),

            content.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 4),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return (container, button, content)
    }

    // MARK: - Actions
    @objc private func didTapExpandable(_ sender: UIButton) {
        guard let content = expandables[sender] else { return }
        let willShow = content.isHidden
        content.isHidden.toggle()

        // Update arrow
        let base = (sender.titleLabel?.text ?? "").replacingOccurrences(of: "▲", with: "").replacingOccurrences(of: "▼", with: "").trimmingCharacters(in: .whitespaces)
        sender.setTitle(willShow ? "\(base)  ▲" : "\(base)  ▼", for: .normal)

        // Ask table to recompute cell height for smooth animation
        if let table = enclosingTableView() {
            UIView.animate(withDuration: 0.25) {
                table.beginUpdates()
                table.endUpdates()
                self.layoutIfNeeded()
            }
        } else {
            // Fallback: just relayout the cell
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    private func enclosingTableView() -> UITableView? {
        var v: UIView? = self
        while let current = v {
            if let tv = current as? UITableView { return tv }
            v = current.superview
        }
        return nil
    }
}

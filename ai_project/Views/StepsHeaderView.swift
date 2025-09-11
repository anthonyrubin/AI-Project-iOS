import UIKit

final class UploadStepHeaderView: UIView {
    private let stack = UIStackView()
    private var badges: [StepBadgeView] = []

    init(total: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        badges = (0..<total).map { StepBadgeView(number: $0 + 1) }
        badges.forEach { stack.addArrangedSubview($0) }
        setActive(index: 0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setActive(index: Int) {
        for (i, b) in badges.enumerated() { b.isActive = (i == index) }
    }
}

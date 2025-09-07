import UIKit

private struct FreeTrialStepsData {
    let icon: String
    let title: String
    let subtitle: String
}

class FreeTrialStepsView: UIView {
    
    private var data: [FreeTrialStepsData]
    
    private var steps: [UIStackView] = []
    
    init(sportIcon: String) {
        
        let firstStep = FreeTrialStepsData(
            icon: sportIcon,
            title: "Today: Get Instant Access",
            subtitle: "Immediately up your game with AI analysis and coaching."
        )
        
        let secondStep = FreeTrialStepsData(
            icon: "bell.circle.fill",
            title: "In 2 days: Trial Reminder Sent",
            subtitle: "We will let you know before your trial ends."
        )
        
        let thirdStep = FreeTrialStepsData(
            icon: "star.circle.fill",
            title: "In 3 days: Subscription Begins",
            subtitle: "Unlock your full potential with a Coach Cam in your pocket."
        )
        
        data = [
            firstStep, secondStep, thirdStep
        ]
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // clean if re-called
        subviews.forEach { $0.removeFromSuperview() }
        steps.removeAll()

        var previousRow: UIStackView?

        for step in data {
            // Icon
            let icon = UIImageView(image: UIImage(systemName: step.icon))
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .systemBlue
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 40),
                icon.heightAnchor.constraint(equalToConstant: 40)
            ])
            icon.tintColor = .black

            // Icon container (gives the row a real left column width)
            let iconContainer = UIView()
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(icon)
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
                icon.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor), // <-- gives container width
                icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
            ])
            iconContainer.setContentHuggingPriority(.required, for: .horizontal)
            iconContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

            // Title + subtitle
            let title = UILabel()
            title.text = step.title
            title.font = .systemFont(ofSize: 18, weight: .medium)
            title.numberOfLines = 0
            title.lineBreakMode = .byWordWrapping
            title.setContentCompressionResistancePriority(.required, for: .vertical)

            let subtitle = UILabel()
            subtitle.text = step.subtitle
            subtitle.font = .systemFont(ofSize: 14, weight: .regular)
            subtitle.textColor = .secondaryLabel
            subtitle.numberOfLines = 0
            subtitle.lineBreakMode = .byWordWrapping
            subtitle.setContentCompressionResistancePriority(.required, for: .vertical)

            let textStack = UIStackView(arrangedSubviews: [title, subtitle])
            textStack.axis = .vertical
            textStack.alignment = .fill
            textStack.spacing = 4
            textStack.translatesAutoresizingMaskIntoConstraints = false
            textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

            // Row
            let row = UIStackView(arrangedSubviews: [iconContainer, textStack])
            row.axis = .horizontal
            row.alignment = .fill            // icon is centered via container constraint
            row.spacing = 15
            row.translatesAutoresizingMaskIntoConstraints = false
            addSubview(row)

            // Vertical chain
            if let prev = previousRow {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 12).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            }

            // Horizontal insets + ensure text has a concrete width so it wraps
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            previousRow = row
            steps.append(row)
        }

        // Bottom inset
        if let last = previousRow {
            last.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        }
    }
}

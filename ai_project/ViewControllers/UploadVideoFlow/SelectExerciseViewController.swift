import UIKit

class SelectExerciseViewController: UIViewController {

    // MARK: - Callbacks expected by the coordinator
    var onContinue: (() -> Void)?
    var onSelectedLift: ((String) -> Void)?

    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "What exercise are you performing?"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let listGrid = ListGridView()
    private let stack = UIStackView()

    private var selectedLiftTitle: String? {
        didSet { refreshContinueState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        layoutUI()
        configureData()
        // Start disabled until a lift is picked
        refreshContinueState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    // MARK: - Continue button (lazy with action)
    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .label
        config.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)

        var attrs = AttributeContainer()
        attrs.font = .systemFont(ofSize: 18, weight: .semibold)
        attrs.foregroundColor = UIColor.systemBackground     // set the color explicitly
        config.attributedTitle = AttributedString("Continue", attributes: attrs)

        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapContinue()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applyTactileTap()
        return button
    }()


    // MARK: - Build / Layout

    private func buildUI() {
        listGrid.translatesAutoresizingMaskIntoConstraints = false
        listGrid.showsSearchBar = true

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(listGrid)

        view.addSubview(stack)
        view.addSubview(continueButton)

        // Selection handler: enable continue + notify coordinator
        listGrid.onSelect = { [weak self] _, item in
            guard let self = self else { return }
            self.selectedLiftTitle = item.title
            self.onSelectedLift?(item.title)      // tell coordinator which lift
        }
    }

    private func layoutUI() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: g.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            continueButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configureData() {
        let catalog: [ListGridItem] = Lift.allCases.map {
            ListGridItem(
                title: $0.rawValue,
                icon: $0.data().icon
            )
        }
        listGrid.items = catalog
    }

    // MARK: - State / Actions

    private func refreshContinueState() {
        let enabled = (selectedLiftTitle != nil)
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }

    @objc private func didTapContinue() {
        onContinue?()
    }
}

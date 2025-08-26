import UIKit

class BaseSignupTableViewController: BaseSignupViewController {
    
    let tableView = UITableView(frame: .zero, style: .plain)
    private lazy var pressHaptics = UIImpactFeedbackGenerator(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pressHaptics.prepare()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure table content isn't hidden behind the fixed button
        let pad = continueButton.bounds.height + 24
        if tableView.contentInset.bottom != pad {
            tableView.contentInset.bottom = pad
            tableView.verticalScrollIndicatorInsets.bottom = pad
        }
    }
    
    func firePressHaptic(_ intensity: CGFloat = 1.0) {
        pressHaptics.impactOccurred(intensity: intensity)
        pressHaptics.prepare()  // prime next one
    }
    
    func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 84

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 0
        tableView.sectionHeaderTopPadding = 0
    }
    
    override func layout() {
        super.layout()
        let g = view.safeAreaLayoutGuide
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12)
        ])
    }
}

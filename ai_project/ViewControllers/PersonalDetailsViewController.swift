import UIKit

final class PersonalDetailsViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // MARK: - Data
    private struct PersonalDetailRow {
        let title: String
        let subtitle: String
    }
    
    private let personalDetailRows: [PersonalDetailRow] = [
        PersonalDetailRow(title: "Experience", subtitle: "test"),
        PersonalDetailRow(title: "Consistency", subtitle: "Test"),
        PersonalDetailRow(title: "Gender", subtitle: "Test"),
        PersonalDetailRow(title: "Height & Weight", subtitle: "Test"),
        PersonalDetailRow(title: "Birthday", subtitle: "Test")
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBackgroundGradient()
    }
    
    // MARK: - Setup
    private func setupCloseButton() {
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navigationItem.rightBarButtonItem = closeButton
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        
        // Register cells
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(PersonalDetailRowCell.self, forCellReuseIdentifier: "PersonalDetailRowCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension PersonalDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Title section + Personal details section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Title row
        case 1:
            return personalDetailRows.count // Personal detail rows
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(with: "Personal Details")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalDetailRowCell", for: indexPath) as! PersonalDetailRowCell
            let row = personalDetailRows[indexPath.row]
            cell.configure(title: row.title, subtitle: row.subtitle)
            return cell
        default:
            fatalError("Unexpected section")
        }
    }
}

// MARK: - UITableViewDelegate
extension PersonalDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let personalDetailCell = cell as? PersonalDetailRowCell else { return }
        
        let rowCount = personalDetailRows.count
        let position: PersonalDetailRowCell.Position
        
        if rowCount == 1 {
            position = .single
        } else if indexPath.row == 0 {
            position = .first
        } else if indexPath.row == rowCount - 1 {
            position = .last
        } else {
            position = .middle
        }
        
        personalDetailCell.apply(position: position)
    }
}

import UIKit

// MARK: - ViewController
final class WorkoutDaysPerWeekViewController: BaseSignupTableViewController {
    
    private let items: [LeftSFIconCellData] = [
        .init(title: "1-2 (Casual)", iconName: "leaf"),
        .init(title: "3-4 (Regular)", iconName: "wind"),
        .init(title: "5+ (Dedicated)", iconName: "bolt")
    ]

    private var selected: LeftSFIconCellData? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.18, animated: false)
        updateContinueState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.cascadeReset()                 // reset state & reload
        tableView.cascadePrepareInitialIfNeeded()// prep icon cells BEFORE screen is shown (no flash)
        // Kick the cascade exactly with the nav transition (instant start)
        tableView.cascadeRunInitialIfNeeded(coordinator: transitionCoordinator)
    }
    
    override func setupTable() {
        super.setupTable()
        tableView.dataSource = self
        tableView.enableCascade(delegate: self)
        tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(LeftSFIconCell.self, forCellReuseIdentifier: LeftSFIconCell.reuseID)
        tableView.allowsMultipleSelection = true
    }

    private func updateContinueState() {
        let enabled = (selected != nil)
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        
        // Save goals to UserDefaults
        UserDefaultsManager.shared.updateGoals(
            workoutDaysPerWeek: selected?.title
        )
        
        let vc = GreatPotentialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data Source & Delegate
extension WorkoutDaysPerWeekViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "How many days per week do you train?",
                subtitle: "This gives our AI model a general idea of your athleticism.",
                fontSize: 35
            )
            return cell
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LeftSFIconCell.reuseID, for: indexPath) as! LeftSFIconCell
        cell.configure(item, selected: selected == item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        firePressHaptic()
        tableView.deselectRow(at: indexPath, animated: false)

        let tapped = items[indexPath.row]

        if selected == tapped {
            // tap again to clear (optional—keeps UX flexible)
            selected = nil
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(false, animated: true)
            }
        } else {
            // turn off previous
            if let prev = selected, let prevRow = items.firstIndex(of: prev) {
                let prevPath = IndexPath(row: prevRow, section: 1)
                if let prevCell = tableView.cellForRow(at: prevPath) as? LeftSFIconCell {
                    prevCell.setSelectedAppearance(false, animated: true)
                } else {
                    tableView.reloadRows(at: [prevPath], with: .none)
                }
            }
            // select new
            selected = items[indexPath.row]
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}


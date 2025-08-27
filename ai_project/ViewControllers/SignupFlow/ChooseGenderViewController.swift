import UIKit

final class ChooseGenderViewController: BaseSignupTableViewController {

    private let items: [LeftSFIconCellData] = [
        .init(title: "Male",                 iconName: "figure.stand"),
        .init(title: "Female",               iconName: "figure.stand.dress"),
        .init(title: "Prefer not to say",    iconName: "questionmark")
    ]

    private var selectedItem: LeftSFIconCellData?   // ← single selection

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.65, animated: false)
        updateContinueState()
    }

    override func setupTable() {
        super.setupTable()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(LeftSFIconCell.self, forCellReuseIdentifier: LeftSFIconCell.reuseID)
        tableView.allowsMultipleSelection = false                     // ← single select
    }

    private func updateContinueState() {
        let enabled = (selectedItem != nil)
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }

    override func didTapContinue() {
        super.didTapContinue()
        let vc = HeightAndWeightViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data Source & Delegate
extension ChooseGenderViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "Choose your gender",
                subtitle: "CoachAI uses this information to improve AI accuracy.",
                fontSize: 35)
            return cell
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LeftSFIconCell.reuseID, for: indexPath) as! LeftSFIconCell
        cell.configure(item, selected: selectedItem == item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        firePressHaptic()
        tableView.deselectRow(at: indexPath, animated: false)

        let tappedItem = items[indexPath.row]

        if selectedItem == tappedItem {
            // tap again to clear
            selectedItem = nil
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(false, animated: true)
            }
        } else {
            // deselect previous if any
            if let prev = selectedItem, let prevRow = items.firstIndex(of: prev) {
                let prevIndexPath = IndexPath(row: prevRow, section: 1)
                if let prevCell = tableView.cellForRow(at: prevIndexPath) as? LeftSFIconCell {
                    prevCell.setSelectedAppearance(false, animated: true)
                } else {
                    tableView.reloadRows(at: [prevIndexPath], with: .none)
                }
            }
            // select new
            selectedItem = tappedItem
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}


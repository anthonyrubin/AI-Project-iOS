import UIKit

// MARK: - ViewController
final class SelectSportViewController: BaseSignupTableViewController {

    private let items: [LeftSFIconCellData] = [
        .init(title: "Golf", iconName: "figure.golf", passdownTitle: "golfer"),
        .init(title: "Tennis", iconName: "figure.tennis", passdownTitle: "tennis player"),
        .init(title: "Pickleball", iconName: "figure.pickleball", passdownTitle: "pickleball player"),
        .init(title: "Basketball", iconName: "figure.basketball", passdownTitle: "basketball player"),
        .init(title: "Baseball", iconName: "figure.baseball", passdownTitle: "baseball player"),
        .init(title: "Soccer", iconName: "figure.indoor.soccer", passdownTitle: "soccer player"),
        .init(title: "Weightlifting", iconName: "figure.strengthtraining.traditional", passdownTitle: "weightlifter"),
        .init(title: "Running", iconName: "figure.run", passdownTitle: "runner"),
        .init(title: "Track & Field", iconName: "figure.track.and.field", passdownTitle: "track athlete"),
        .init(title: "Football (American)", iconName: "figure.american.football", passdownTitle: "football player"),
        .init(title: "Volleyball",  iconName: "figure.volleyball", passdownTitle: "volleyball player"),
        .init(title: "Hockey", iconName: "figure.hockey", passdownTitle: "hockey player"),
        .init(title: "Softball", iconName: "figure.softball", passdownTitle: "softball player"),
        .init(title: "Lacrosse", iconName: "figure.lacrosse", passdownTitle: "lacrosse player"),
        .init(title: "Cricket", iconName: "figure.cricket", passdownTitle: "cricketer"),
        .init(title: "Badminton", iconName: "figure.badminton", passdownTitle: "badminton player"),
        .init(title: "Table Tennis", iconName: "figure.table.tennis", passdownTitle: "table tennis player"),
        .init(title: "Rowing", iconName: "figure.indoor.rowing", passdownTitle: "rower"),
        .init(title: "Striking (Boxing / Kickboxing / TKD)", iconName: "figure.boxing", passdownTitle: "fighter")
    ]

    private var selectedItem: LeftSFIconCellData?   // ← single selection

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.15, animated: false)
        updateContinueState()
    }
    
    override func setupTable() {
        super.setupTable()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(LeftSFIconCell.self, forCellReuseIdentifier: LeftSFIconCell.reuseID)
        tableView.allowsMultipleSelection = false
    }

    private func updateContinueState() {
        let enabled = (selectedItem != nil)
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        
        let vc = GoalsViewController(sportDisplay: selectedItem!.passdownTitle!)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data Source & Delegate
extension SelectSportViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "What sport are you here for?",
                subtitle: "Pick one to start. You can change add more any time.",
                fontSize: 35
            )
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

        let tapped = items[indexPath.row]

        if selectedItem == tapped {
            // tap again to clear (optional—keeps UX flexible)
            selectedItem = nil
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(false, animated: true)
            }
        } else {
            // turn off previous
            if let prev = selectedItem, let prevRow = items.firstIndex(of: prev) {
                let prevPath = IndexPath(row: prevRow, section: 1)
                if let prevCell = tableView.cellForRow(at: prevPath) as? LeftSFIconCell {
                    prevCell.setSelectedAppearance(false, animated: true)
                } else {
                    tableView.reloadRows(at: [prevPath], with: .none)
                }
            }
            // select new
            selectedItem = tapped
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}


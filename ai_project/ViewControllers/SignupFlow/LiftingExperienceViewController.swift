import UIKit

// MARK: - ViewController
final class LiftingExperienceViewController: BaseSignupTableViewController {
    
    var onContinue: (() -> Void)?
    var onSelectedExperience: ((String) -> Void)?

    // SETTINGS MODE: pass this when opening from Settings
    var preSelectedItem: String? = nil
    private var originalItem: LeftSFIconCellData?

    private var items: [LeftSFIconCellData] = [
        LeftSFIconCellData(title: "Beginner (0–6 months)", iconName: "sparkles"),
        LeftSFIconCellData(title: "Intermediate (1-2 years)", iconName: "figure.highintensity.intervaltraining"),
        LeftSFIconCellData(title: "Advanced (3–5 years)", iconName: "figure.strengthtraining.traditional"),
        LeftSFIconCellData(title: "Expert (5+ years)", iconName: "flame"),
    ]

    private var selectedItem: LeftSFIconCellData?   // ← single selection

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.09, animated: false)

        // If provided from Settings, preselect and remember the original
        if let pre = preSelectedItem,
           let match = items.first(where: { $0.title == pre }) {
            originalItem = match
            selectedItem = match
        }

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
        tableView.allowsMultipleSelection = false
    }

    private func updateContinueState() {
        if let originalItem {
            let changed = (selectedItem != nil && selectedItem != originalItem)
            continueButton.isEnabled = changed
            continueButton.alpha = changed ? 1.0 : 0.4
        } else {
            let enabled = (selectedItem != nil)
            continueButton.isEnabled = enabled
            continueButton.alpha = enabled ? 1.0 : 0.4
        }
    }
    
    override func didTapContinue() {
        // Settings flow: only when there was a preselected value and user changed it
        if let originalItem, let selectedItem, selectedItem != originalItem {
            // Stub for settings update action — replace with your save/pop/notify
            print("Settings flow: update lifting experience to \(selectedItem.title)")
            return
        }

        // Default signup behavior (unchanged)
        super.didTapContinue()
        onContinue?()
    }
}

// MARK: - Data Source & Delegate
extension LiftingExperienceViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "How long have you been lifting?",
                subtitle: "We custom tailor our AI feedback to your experience level.",
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
            // tap again to clear
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
            selectedItem = items[indexPath.row]
            onSelectedExperience?(selectedItem!.title)
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}


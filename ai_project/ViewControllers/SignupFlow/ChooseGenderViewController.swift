import UIKit

final class ChooseGenderViewController: BaseSignupTableViewController {
    
    var onContinue: (() -> Void)?
    var onSelectedGender: ((String) -> Void)?
    
    // Used to set the value in GenderViewController from settings
    var preSelectedItem: String? = nil

    private let items: [LeftSFIconCellData] = [
        .init(title: "Male",                 iconName: "figure.stand"),
        .init(title: "Female",               iconName: "figure.stand.dress"),
        .init(title: "Prefer not to say",    iconName: "questionmark")
    ]

    private var selectedItem: LeftSFIconCellData?   // ← single selection

    // Track the preselected/original value to compare changes (only when preSelectedItem != nil)
    private var originalItem: LeftSFIconCellData?

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.36, animated: false)

        // If provided from Settings, preselect and remember the original
        if let pre = preSelectedItem,
           let match = items.first(where: { $0.title == pre }) {
            originalItem = match
            selectedItem = match
            continueButton.setTitle("Save", for: .normal)
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
        tableView.allowsMultipleSelection = false                     // ← single select
    }

    private func updateContinueState() {
        if let originalItem {
            // Settings mode: enable only if the selection changed to a different value
            let changed = (selectedItem != nil && selectedItem != originalItem)
            continueButton.isEnabled = changed
            continueButton.alpha = changed ? 1.0 : 0.4
        } else {
            // Signup flow: original behavior
            let enabled = (selectedItem != nil)
            continueButton.isEnabled = enabled
            continueButton.alpha = enabled ? 1.0 : 0.4
        }
    }

    override func didTapContinue() {
        // If coming from Settings (preSelectedItem provided), take a different action and do NOT call super/onContinue.
        if let originalItem, let selectedItem, selectedItem != originalItem {
            // Stub for settings update action:
            // e.g., save to Realm, pop controller, notify delegate, etc.
            print("Settings flow: update gender to \(selectedItem.title)")
            return
        }

        // Default signup behavior (unchanged)
        super.didTapContinue()
        onContinue?()
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
                subtitle: "Coach Cam uses this information to improve AI accuracy.",
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
            onSelectedGender?(selectedItem!.title)
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}


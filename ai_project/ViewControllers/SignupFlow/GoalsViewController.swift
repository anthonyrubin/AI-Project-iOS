import UIKit

// MARK: - ViewController
final class GoalsViewController: BaseSignupTableViewController {

    private let items: [LeftSFIconCellData] = [
        .init(title: "Win an upcoming event", iconName: "trophy.fill"),
        .init(title: "Improve athleticism", iconName: "bolt.fill"),
        .init(title: "Go professional", iconName: "medal.fill"),
        .init(title: "Steady progress", iconName: "chart.line.uptrend.xyaxis"),
        .init(title: "Injury recovery", iconName: "bandage.fill"),
        .init(title: "Improve form and technique", iconName: "dot.scope")
    ]

    private var selected = Set<LeftSFIconCellData>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.45, animated: false)
        updateContinueState()
    }
    
    override func setupTable() {
        super.setupTable()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(LeftSFIconCell.self, forCellReuseIdentifier: LeftSFIconCell.reuseID)
    }

    private func updateContinueState() {
        let enabled = !selected.isEmpty
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        let vc = GreatPotentialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data Source & Delegate
extension GoalsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(with: "What are your goals?", fontSize: 35)
            return cell
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LeftSFIconCell.reuseID, for: indexPath) as! LeftSFIconCell
        cell.configure(item, selected: selected.contains(item))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        
        firePressHaptic()

        // kill UIKit’s highlight immediately
        tableView.deselectRow(at: indexPath, animated: false)

        let item = items[indexPath.row]
        let nowSelected: Bool
        if selected.contains(item) {
            selected.remove(item)
            nowSelected = false
        } else {
            selected.insert(item)
            nowSelected = true
        }

        if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
            cell.setSelectedAppearance(nowSelected, animated: true)  // ← update directly
        }
        updateContinueState()
    }
}


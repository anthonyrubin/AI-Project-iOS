import UIKit

// MARK: - ViewController
final class GoalsViewController: BaseSignupTableViewController {
    
    var sportDisplay: String
    
    init(sportDisplay: String) {
        self.sportDisplay = sportDisplay
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let items: [LeftSFIconCellData] = [
        .init(title: "Improve consistently", iconName: "chart.line.uptrend.xyaxis"),
        .init(title: "Fix my form / technique", iconName: "wrench.and.screwdriver.fill"),
        .init(title: "Learn a new skill", iconName: "lightbulb.max.fill"),
        .init(title: "Improve accuracy / consistency", iconName: "dot.scope"),
        .init(title: "Increase power / speed", iconName: "bolt.fill"),
        .init(title: "Build endurance / athleticism", iconName: "figure.run"),
        .init(title: "Prepare for an event / tryout", iconName: "calendar"),
        .init(title: "Return from injury safely", iconName: "bandage.fill"),
        .init(title: "Go pro / reach elite level", iconName: "trophy.fill"),
        .init(title: "Have fun / stay active", iconName: "face.smiling.inverse")
    ]

    private var selected = Set<LeftSFIconCellData>() // multi-select, max 3

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
        tableView.allowsMultipleSelection = true
    }

    private func updateContinueState() {
        let enabled = !selected.isEmpty
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        
        // Save goals to UserDefaults
        let selectedGoalTitles = Array(selected).map { $0.title }
        UserDefaultsManager.shared.updateGoals(
            selectedGoals: selectedGoalTitles,
            sportDisplay: sportDisplay
        )
        UserDefaultsManager.shared.updateProgress(progress: 0.55, step: "goals_set")
        
        let vc = GreatPotentialViewController(sportDisplay: sportDisplay)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data Source & Delegate
extension GoalsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "What do you want to improve?",
                subtitle: "Pick up to three.",
                fontSize: 35
            )
            return cell
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LeftSFIconCell.reuseID, for: indexPath) as! LeftSFIconCell
        cell.configure(item, selected: selected.contains(item))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        let item = items[indexPath.row]
        let isAlreadySelected = selected.contains(item)

        // Enforce cap: if trying to add a 4th, reject and give tiny feedback
        if !isAlreadySelected && selected.count >= 3 {
            if let cell = tableView.cellForRow(at: indexPath) {
                shake(cell)
            }
            // Optional: warning haptic
            // let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.warning)
            return
        }

        // Toggle selection
        if isAlreadySelected {
            selected.remove(item)
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(false, animated: true)
            }
        } else {
            selected.insert(item)
            firePressHaptic() // success haptic only when toggle succeeds
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }

    // Simple shake for over-limit taps
    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [0, 8, -8, 6, -6, 0]
        anim.duration = 0.30
        anim.calculationMode = .cubic
        view.layer.add(anim, forKey: "shake")
    }
}


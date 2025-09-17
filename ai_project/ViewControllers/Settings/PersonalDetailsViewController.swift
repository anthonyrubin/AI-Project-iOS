import UIKit

final class PersonalDetailsViewController: UIViewController {

    private let viewModel = PersonalDetailsViewModel(userDataStore: RealmUserDataStore())
    private let tableView = UITableView(frame: .zero, style: .plain)

    private struct PersonalDetailRow { let title: String; let subtitle: String; let action: () -> Void }
    private var personalDetailRows: [PersonalDetailRow] = []

    // ---- Section outline overlay ----
    private let sectionOutlineView = SectionOutlineView()
    private let outlinedSection = 0        // details is now the ONLY section
    private let cardInset: CGFloat = 16
    private let corner: CGFloat = 16

    override func viewDidLoad() {
        title = "Personal Details"
        super.viewDidLoad()
        setData()
        setupCloseButton()
        setupUI()

        // Outline setup
        tableView.addSubview(sectionOutlineView)
        sectionOutlineView.isUserInteractionEnabled = false
        sectionOutlineView.corner = corner
        sectionOutlineView.lineWidth = 1 / UIScreen.main.scale
        sectionOutlineView.strokeColor = .separator
        sectionOutlineView.layer.zPosition = 9_999
        sectionOutlineView.isHidden = true
        
        tableView.reloadData()
        tableView.layoutIfNeeded()
        refreshSectionOutline()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshSectionOutline()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshSectionOutline()
    }

    private func setupCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped)
        )
    }

    @objc private func closeButtonTapped() { dismiss(animated: true) }

    private func setData() {
        personalDetailRows = [
            PersonalDetailRow(title: "Experience",  subtitle: viewModel.getExperience()) { [weak self] in
                let vc = LiftingExperienceViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            PersonalDetailRow(title: "Consistency", subtitle: viewModel.getWorkoutDaysPerWeek()) { [weak self] in
                let vc = WorkoutDaysPerWeekViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            PersonalDetailRow(title: "Gender",      subtitle: viewModel.getGender()) { [weak self] in
                let vc = ChooseGenderViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            PersonalDetailRow(title: "Height",      subtitle: viewModel.getHeight()) { [weak self] in
                let vc = HeightAndWeightViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            PersonalDetailRow(title: "Weight",      subtitle: viewModel.getWeight()) { [weak self] in
                let vc = HeightAndWeightViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            PersonalDetailRow(title: "Birthday",    subtitle: viewModel.getBirthday()) { [weak self] in
                let vc = BirthdayViewController(); vc.hidesProgressBar = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        ]
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)

        // No title cell anymore
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

    // Keep outline in the right place while scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) { refreshSectionOutline() }
    
    private func refreshSectionOutline() {
        guard tableView.numberOfSections > outlinedSection else { sectionOutlineView.isHidden = true; return }
        let rows = tableView.numberOfRows(inSection: outlinedSection)
        guard rows > 0 else { sectionOutlineView.isHidden = true; return }

        tableView.layoutIfNeeded()  // <- safety: table has measured its rows

        let first = tableView.rectForRow(at: IndexPath(row: 0, section: outlinedSection))
        let last  = tableView.rectForRow(at: IndexPath(row: rows - 1, section: outlinedSection))
        var frame = first.union(last)
        frame.origin.x += cardInset
        frame.size.width -= cardInset * 2
        frame = frame.integral

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sectionOutlineView.frame = frame
        sectionOutlineView.isHidden = false
        CATransaction.commit()

        tableView.bringSubviewToFront(sectionOutlineView)
    }
}

// MARK: - DataSource
extension PersonalDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        personalDetailRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalDetailRowCell", for: indexPath) as! PersonalDetailRowCell
        let row = personalDetailRows[indexPath.row]
        cell.configure(title: row.title, subtitle: row.subtitle)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        personalDetailRows[indexPath.row].action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Delegate
extension PersonalDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { .leastNormalMagnitude }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 20 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == outlinedSection, let c = cell as? PersonalDetailRowCell else { return }
        let count = tableView.numberOfRows(inSection: indexPath.section)
        let pos: PersonalDetailRowCell.Position =
            (count == 1) ? .single :
            (indexPath.row == 0) ? .first :
            (indexPath.row == count - 1) ? .last : .middle
        c.apply(position: pos)
        refreshSectionOutline()
    }
}

// ---- SectionOutlineView (same as you have) ----
private final class SectionOutlineView: UIView {
    var corner: CGFloat = 16    { didSet { setNeedsLayout() } }
    var lineWidth: CGFloat = 1  { didSet { shape.lineWidth = lineWidth; setNeedsLayout() } }
    var strokeColor: UIColor = .separator { didSet { shape.strokeColor = strokeColor.cgColor } }

    private var shape: CAShapeLayer { layer as! CAShapeLayer }
    override class var layerClass: AnyClass { CAShapeLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let s = shape
        s.fillColor = UIColor.clear.cgColor
        s.strokeColor = strokeColor.cgColor
        s.lineWidth = lineWidth
        s.lineJoin = .miter
        s.lineCap  = .butt
        s.contentsScale = UIScreen.main.scale
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = lineWidth / 2
        let b = bounds.insetBy(dx: inset, dy: inset)
        let r = max(0, corner - inset)
        let path = UIBezierPath(roundedRect: b, cornerRadius: r)
        shape.strokeColor = strokeColor.resolvedColor(with: traitCollection).cgColor
        shape.path = path.cgPath
    }
}


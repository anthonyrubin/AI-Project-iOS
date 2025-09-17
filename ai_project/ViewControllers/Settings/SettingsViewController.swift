import Foundation
import UIKit
import Combine

final class SettingsViewController: UIViewController {

    private var loadingOverlay = LoadingOverlay()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let viewModel = ProfileViewModel(
        authRepository: AuthRepositoryImpl(
            authAPI: NetworkManager(tokenManager: TokenManager()),
            tokenManager: TokenManager(),
            realmUserDataStore: RealmUserDataStore()
        )
    )

    private struct Section { let header: String?; let rows: [Row] }
    private struct Row { let icon: String; let title: String; let action: () -> Void }

    private var sections: [Section] = []
    private var cancellables = Set<AnyCancellable>()

    // ---- Section chrome (non-title sections only) ----
    private var outlineViews: [Int: SectionOutlineView] = [:]
    private var shadowViews:  [Int: SectionShadowView]  = [:]
    private let cardInset: CGFloat = 16
    private let corner: CGFloat = 16

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupData()
        setupTable()

        // Make sure table has frames before we place chrome
        tableView.reloadData()
        tableView.layoutIfNeeded()

        installChrome()
        refreshSectionChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshSectionChrome()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshSectionChrome()
    }

    private func setupData() {
        sections = [
            Section(header: nil, rows: [
                Row(icon: "person.text.rectangle", title: "Personal details", action: { [weak self] in
                    self?.navigateToPersonalDetails()
                }),
                Row(icon: "translate", title: "Language", action: {
                    let vc = LanguagePickerViewController(selectedCode: "en") { picked in
                        print("Picked:", picked)
                    }
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .crossDissolve   // overlay fade; the sheet itself slides
                    self.present(vc, animated: true)
                }),
                Row(icon: "crown.fill", title: "Membership", action: { [weak self] in
                    self?.navigateToMembership()
                })
            ]),
            Section(header: nil, rows: [
                Row(icon: "text.document", title: "Terms and Conditions", action: { }),
                Row(icon: "shield.pattern.checkered", title: "Privacy Policy", action: { }),
                Row(icon: "book.closed", title: "Attribution & Licenses", action: { [weak self] in
                    let vc = AttributionsViewController()
                    vc.modalPresentationStyle = .pageSheet
                    if let sheet = vc.sheetPresentationController {
                        sheet.detents = [.large()]
                        sheet.prefersGrabberVisible = false
                    }
                    self?.present(vc, animated: true)
                }),
            ]),
            Section(header: nil, rows: [
                Row(icon: "rectangle.portrait.and.arrow.right", title: "Logout", action: { [weak self] in
                    self?.logoutButtonTapped()
                }),
            ])
        ]
    }

    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                isLoading ? self?.loadingOverlay.show(in: self!.navigationController!.view) : self?.loadingOverlay.hide()
            }
            .store(in: &cancellables)
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)

        tableView.register(RoundCardCell.self, forCellReuseIdentifier: "RoundCardCell")
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
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

    // MARK: Chrome (outline + ring shadow)
    private func installChrome() {
        // Non-title sections are 1...(numberOfSections-1)
        for section in 1..<tableView.numberOfSections {
            if shadowViews[section] == nil {
                let s = SectionShadowView()
                s.corner = corner
                s.shadowOpacity = 0.18
                s.shadowRadius  = 8
                s.shadowOffset  = .zero     // outline-style shadow; change to (0,4) if you want drop direction
                s.spread        = 12        // >= radius*2 for clean blur
                s.isHidden = true
                s.layer.zPosition = 9_998
                tableView.addSubview(s)
                shadowViews[section] = s
            }
            if outlineViews[section] == nil {
                let v = SectionOutlineView()
                v.corner = corner
                v.lineWidth = 1 / UIScreen.main.scale
                v.strokeColor = .separator
                v.isHidden = true
                v.layer.zPosition = 9_999
                tableView.addSubview(v)
                outlineViews[section] = v
            }
        }
    }

    private func refreshSectionChrome() {
        tableView.layoutIfNeeded()

        // Hide stale chrome if sections changed
        for (sec, v) in outlineViews where sec >= tableView.numberOfSections { v.isHidden = true }
        for (sec, s) in shadowViews  where sec >= tableView.numberOfSections { s.isHidden = true }

        for section in 1..<tableView.numberOfSections {
            guard let outline = outlineViews[section], let shadow = shadowViews[section] else { continue }
            let count = tableView.numberOfRows(inSection: section)
            guard count > 0 else { outline.isHidden = true; shadow.isHidden = true; continue }

            let first = tableView.rectForRow(at: IndexPath(row: 0, section: section))
            let last  = tableView.rectForRow(at: IndexPath(row: count - 1, section: section))
            var frame = first.union(last)
            frame.origin.x += cardInset
            frame.size.width -= cardInset * 2
            frame = frame.integral

            CATransaction.begin()
            CATransaction.setDisableActions(true)

            // Shadow frame expanded so the halo isn't clipped; outline stays exact
            let spread = shadow.spread
            shadow.frame  = frame.insetBy(dx: -spread, dy: -spread)
            shadow.isHidden = false

            outline.frame = frame
            outline.isHidden = false

            CATransaction.commit()

            tableView.bringSubviewToFront(outline)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) { refreshSectionChrome() }

    // MARK: Actions
    @objc func logoutButtonTapped() {
        Alert(self).danger(
            titleText: "Logout",
            bodyText: "Are you sure you want to logout?",
            buttonText: "Logout",
            canCancel: true,
            completion: { [weak self] in self?.viewModel.logout() }
        )
    }

    private func navigateToMembership() {
        let membershipVC = BecomeAMemberViewController()
        navigationController?.pushViewController(membershipVC, animated: true)
    }

    private func navigateToPersonalDetails() {
        let personalDetailsVC = PersonalDetailsViewController()
        let navController = UINavigationController(rootViewController: personalDetailsVC)
        present(navController, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count + 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : sections[section - 1].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return nil }
        guard let title = sections[section - 1].header else {
            let spacer = UIView(); spacer.backgroundColor = .clear; return spacer
        }
        let c = UIView(); c.backgroundColor = .clear
        let l = UILabel(); l.text = title; l.font = .systemFont(ofSize: 20, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        c.addSubview(l)
        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 20),
            l.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -8)
        ])
        return c
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return .leastNormalMagnitude }
        return sections[section - 1].header == nil ? 8 : 44
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 20
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(with: "Settings")
            return cell
        }
        let row = sections[indexPath.section - 1].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoundCardCell", for: indexPath) as! RoundCardCell
        cell.configure(icon: UIImage(systemName: row.icon), title: row.title)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section != 0, let card = cell as? RoundCardCell else { return }
        let count = tableView.numberOfRows(inSection: indexPath.section)
        let pos: RoundCardCell.Position =
            (count <= 1) ? .single :
            (indexPath.row == 0) ? .first :
            (indexPath.row == count - 1) ? .last : .middle
        card.apply(position: pos)
        refreshSectionChrome()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 { sections[indexPath.section - 1].rows[indexPath.row].action() }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


import Foundation
import UIKit
import Combine


final class ProfileViewController: UIViewController {
    
    private var loadingOverlay = LoadingOverlay()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let viewModel = ProfileViewModel(
        authRepository: AuthRepositoryImpl(
            authAPI: NetworkManager(tokenManager: TokenManager()),
            tokenManager: TokenManager(),
            realmUserDataStore: RealmUserDataStore()
        )
    )

    // Example data
    private struct Section {
        let header: String?
        let rows: [Row]
    }
    private struct Row { let icon: String; let title: String; let action: () -> Void }

    private var sections: [Section] = []
    private var cancellables = Set<AnyCancellable>()


    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupData()
        setupTable()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBackgroundGradient()
    }

    private func setupData() {
        sections = [
            Section(header: nil, rows: [
                Row(icon: "person.text.rectangle", title: "Personal details", action: { print("details") }),
                Row(icon: "translate", title: "Language", action: { }),
                Row(icon: "crown.fill", title: "Membership", action: { [weak self] in
                    self?.navigateToMembership()
                })
            ]),
            Section(header: nil, rows: [
                Row(icon: "text.document", title: "Terms and Conditions", action: { }),
                Row(icon: "shield.pattern.checkered", title: "Privacy Policy", action: { }),
                Row(icon: "book.closed", title: "Attribution & Licenses", action: {
                    let vc = AttributionsViewController()

                    vc.modalPresentationStyle = .pageSheet
                    if let sheet = vc.sheetPresentationController {
                        sheet.detents = [.large()]
                        sheet.prefersGrabberVisible = false
                    }
                    self.present(vc, animated: true)
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
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count + 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : sections[section - 1].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section - 1].header else {
            // spacer above the first card group
            let spacer = UIView()
            spacer.backgroundColor = .clear
            return spacer
        }
        let c = UIView()
        c.backgroundColor = .clear
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 20, weight: .bold)
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
    } // space between cards
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Title cell at the very top (only section 0, row 0)
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(with: "Settings")
            return cell
        }

        // Shift the row index for section 0 because of the extra title row
        let dataRowIndex = indexPath.row - (indexPath.section == 0 ? 1 : 0)
        let row = sections[indexPath.section - 1].rows[dataRowIndex]

        let cell = tableView.dequeueReusableCell(withIdentifier: "RoundCardCell", for: indexPath) as! RoundCardCell
        cell.configure(icon: UIImage(systemName: row.icon), title: row.title)
        return cell
    }

    // Round per position to get a single “card” per section
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let card = cell as? RoundCardCell else { return }

        // Compute “visible” index/count excluding the title row in section 0
        let offset = (indexPath.section == 0 ? 1 : 0)
        let visibleIndex = indexPath.row - offset
        let visibleCount = tableView.numberOfRows(inSection: indexPath.section) - offset

        let pos: RoundCardCell.Position =
            visibleCount <= 1 ? .single :
            visibleIndex == 0 ? .first :
            visibleIndex == visibleCount - 1 ? .last : .middle

        card.apply(position: pos)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sections[indexPath.section - 1].rows[indexPath.row].action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func logoutButtonTapped() {
        Alert(self).danger(
            titleText: "Logout",
            bodyText: "Are you sure you want to logout?",
            buttonText: "Logout",
            canCancel: true,
            completion: {  [weak self] in
                self?.viewModel.logout()
            }
        )
    }
    
    private func navigateToMembership() {
        let membershipVC = BecomeAMemberViewController()
        navigationController?.pushViewController(membershipVC, animated: true)
    }
}

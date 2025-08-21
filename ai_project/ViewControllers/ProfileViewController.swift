import Foundation
import UIKit
import Combine


final class ProfileViewController: UIViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()
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
                Row(icon: "translate", title: "Language", action: { })
            ]),
            Section(header: nil, rows: [
                Row(icon: "text.document", title: "Terms and Conditions", action: { }),
                Row(icon: "shield.pattern.checkered", title: "Privacy Policy", action: { }),
                Row(icon: "person.fill.badge.minus", title: "Privacy Policy", action: { }),
            ]),
            
            Section(header: nil, rows: [
                Row(icon: "rectangle.portrait.and.arrow.right", title: "Logout", action: { [weak self] in
                    self?.logoutButtonTapped()
                }),
            ])
        ]
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
        viewModel.logout()
    }
}


//class ProfileViewController: UIViewController {
//    
//    private lazy var errorModalManager = ErrorModalManager(viewController: self)
//    
//    // MARK: - UI Components
//    let topLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Profile"
//        label.font = .systemFont(ofSize: 28, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    let logoutButton: UIButton = {
//        let b = UIButton(type: .system)
//        var c = UIButton.Configuration.filled()
//        c.title = "Logout"
//        c.baseBackgroundColor = .black
//        c.baseForegroundColor = .white
//        c.cornerStyle = .medium
//        b.configuration = c
//        b.translatesAutoresizingMaskIntoConstraints = false
//        return b
//    }()
//
//    // MARK: - ViewModel
//    private let viewModel = ProfileViewModel(
//        authRepository: AuthRepositoryImpl(
//            authAPI: NetworkManager(
//                tokenManager: TokenManager()
//            ),
//            tokenManager: TokenManager(),
//            realmUserDataStore: RealmUserDataStore()
//        )
//    )
//    private var cancellables = Set<AnyCancellable>()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        hideNavBarHairline()
//        setupUI()
//        setupBindings()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        makeNavBarTransparent(for: self)
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        setBackgroundGradient()
//    }
//
//    func setupUI() {
//        view.addSubview(topLabel)
//        view.addSubview(logoutButton)
//
//        NSLayoutConstraint.activate([
//            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
//            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
//            topLabel.heightAnchor.constraint(equalToConstant: 44),
//
//            logoutButton.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
//            logoutButton.heightAnchor.constraint(equalToConstant: 50),
//            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
//            logoutButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//        ])
//
//        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
//    }
//
//
//    private func setupBindings() {
//        // Bind loading state to button
//        viewModel.$isLoading
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isLoading in
//                self?.logoutButton.isEnabled = !isLoading
//                if isLoading {
//                    self?.logoutButton.configuration?.showsActivityIndicator = true
//                } else {
//                    self?.logoutButton.configuration?.showsActivityIndicator = false
//                }
//            }
//            .store(in: &cancellables)
//        
//        // Bind error messages
//        viewModel.$errorMessage
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] errorMessage in
//                if let errorMessage = errorMessage {
//                    self?.errorModalManager.showError(errorMessage)
//                    self?.viewModel.clearError()
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    @objc func logoutButtonTapped() {
//        viewModel.logout()
//    }
//    
//    deinit {
//        cancellables.removeAll()
//    }
//}

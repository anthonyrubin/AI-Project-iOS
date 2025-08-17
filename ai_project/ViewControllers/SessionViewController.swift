import Foundation
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import RealmSwift
import Combine

// Custom table view that makes section headers scroll with content
class NonStickyTableView: UITableView {
    override var style: UITableView.Style {
        return .plain
    }
}

final class SessionViewController: UIViewController {
    // MARK: - ViewModels
    //private let uploadViewModel = VideoUploadViewModel()
    private let sessionViewModel = SessionViewModel(
        userService: UserService(),
        repository: VideoAnalysisRepository(
            networkManager: NetworkManager(
                tokenManager: TokenManager(),
                userService: UserService()
            )
        ),
        networkManager: NetworkManager(
            tokenManager: TokenManager(),
            userService: UserService()
        )
    )
    
    private lazy var loadingOverlay = LoadingOverlay(viewController: self)
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    // MARK: - UI Components
    private let floatingBar = UIView()
    private let startButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "START SESSION"
        c.image = UIImage(systemName: "video.fill")
        c.imagePadding = 8
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        return UIButton(configuration: c)
    }()

    private let floatingHeight: CGFloat = 92
    private let shadowPad: CGFloat = 24       // room above for the top shadow
    private weak var host: UIView?            // lives in tabBarController.view
    
    // MARK: - UI Components
    private let tableView = NonStickyTableView()
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Section Types
    private enum Section: Int, CaseIterable {
        case greeting = 0
        case sessionHistory = 1
        case lastSession = 2
    }
    
    // MARK: - Row Types
    private enum RowType {
        case greeting
        case sessionHistoryHeader
        case sessionHistoryCell
        case lastSessionHeader
        case lastSessionCell
        case none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customBackgroundColor()
        setupUI()
        setupBindings()
        sessionViewModel.loadUserData()
        sessionViewModel.loadAnalyses()
        setupNotifications()

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startSession), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installFloatingBarIfNeeded()
        sessionViewModel.refreshData()
        
        // Ensure tab bar has correct background
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.barTintColor = .white
    }
    
    private func setupBindings() {
        // Bind session data to table view updates
        sessionViewModel.$userAnalyses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // Bind user data updates
        sessionViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // Bind error messages
        sessionViewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorModalManager.showError(errorMessage)
                    self?.sessionViewModel.clearError()
                }
            }
            .store(in: &cancellables)
        
        sessionViewModel.$uploadedVideo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] video in
                if video != nil {
                    self?.sessionViewModel.resetUploadState()
                }
            }
            .store(in: &cancellables)
        
        sessionViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                print("IS LOADING BE \(isLoading)")
                if isLoading {
                    self?.loadingOverlay.show()
                } else {
                    self?.loadingOverlay.hide()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        setupFloatingBar()
        setupTableView()
        setupConstraints()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove top spacing
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        view.addSubview(tableView)
        
        // Register cell classes
        tableView.register(GreetingCell.self, forCellReuseIdentifier: "GreetingCell")
        tableView.register(SessionHistoryCell.self, forCellReuseIdentifier: "SessionHistoryCell")
        tableView.register(VideoAnalysisCell.self, forCellReuseIdentifier: "VideoAnalysisCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
    }
    
    private func setupFloatingBar() {
        floatingBar.backgroundColor = .white
        floatingBar.layer.cornerRadius = 20
        floatingBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        floatingBar.layer.masksToBounds = false
        floatingBar.layer.shadowColor = UIColor.black.cgColor
        floatingBar.layer.shadowOpacity = 0.5
        floatingBar.layer.shadowRadius = 12
        floatingBar.layer.shadowOffset = .init(width: 0, height: 6)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view - attach directly to top edge for flush greeting cell
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -floatingHeight - shadowPad)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: .videoAnalysisCompleted,
            object: nil
        )
    }
    
    @objc private func refreshData() {
        sessionViewModel.refreshData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
    
    // MARK: - Helper Methods
    private func getRowType(for row: Int) -> RowType {
        var currentRow = 0
        
        // Greeting cell (row 0)
        if row == currentRow {
            return .greeting
        }
        currentRow += 1
        
        // Session History section (if has analyses)
        if sessionViewModel.hasAnalyses() {
            // Session History header
            if row == currentRow {
                return .sessionHistoryHeader
            }
            currentRow += 1
            
            // Session History cell
            if row == currentRow {
                return .sessionHistoryCell
            }
            currentRow += 1
        }
        
        // Last Session section (if has analyses)
        if sessionViewModel.hasAnalyses() {
            // Last Session header
            if row == currentRow {
                return .lastSessionHeader
            }
            currentRow += 1
            
            // Last Session cell
            if row == currentRow {
                return .lastSessionCell
            }
        }
        
        return .none
    }

}

// MARK: - UITableViewDataSource
extension SessionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Single section with all content
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        
        // Greeting cell (always present)
        rowCount += 1
        
        // Session History section header + cell (if has analyses)
        if sessionViewModel.hasAnalyses() {
            rowCount += 2 // Header + cell
        }
        
        // Last Session section header + cell (if has analyses)
        if sessionViewModel.hasAnalyses() {
            rowCount += 2 // Header + cell
        }
        
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        var currentRow = 0
        
        // Greeting cell (row 0)
        if row == currentRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GreetingCell", for: indexPath) as! GreetingCell
            cell.configure(with: sessionViewModel.currentUser)
            return cell
        }
        currentRow += 1
        
        // Session History section (if has analyses)
        if sessionViewModel.hasAnalyses() {
            // Session History header
            if row == currentRow {
                return setHeaderCell(title: "Session History", indexPath: indexPath)
            }
            currentRow += 1
            
            // Session History cell
            if row == currentRow {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SessionHistoryCell", for: indexPath) as! SessionHistoryCell
                cell.configure(totalMinutes: sessionViewModel.totalMinutesAnalyzed, averageScore: sessionViewModel.averageScore)
                return cell
            }
            currentRow += 1
        }
        
        // Last Session section (if has analyses)
        if sessionViewModel.hasAnalyses() {
            // Last Session header
            if row == currentRow {
                return setHeaderCell(title: "Last Session", indexPath: indexPath)
            }
            currentRow += 1
            
            // Last Session cell
            if row == currentRow {
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCell", for: indexPath) as! VideoAnalysisCell
                if let lastAnalysis = sessionViewModel.lastSession {
                    cell.configure(with: lastAnalysis)
                }
                return cell
            }
        }
        
        // Fallback
        return UITableViewCell()
    }
    
    func setHeaderCell(title: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        // Remove any existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SessionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // transparent spacer view
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let rowType = getRowType(for: indexPath.row)
        
        switch rowType {
        case .greeting, .sessionHistoryHeader, .sessionHistoryCell, .lastSessionHeader:
            return // No action for these rows
        case .lastSessionCell:
            if let lastAnalysis = sessionViewModel.lastSession {
                let lessonViewController = LessonViewController(analysis: lastAnalysis)
                navigationController?.pushViewController(lessonViewController, animated: true)
            }
        case .none:
            return
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // refresh path after any layout changes when returning to this tab
        tabBarController?.view.layoutIfNeeded()
        updateShadowPath()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        uninstallFloatingBar() // do not persist over other tabs
    }

    private func installFloatingBarIfNeeded() {
        guard host == nil, let tbc = tabBarController else { return }

        // Host view clips bottom; pinned to tab bar top
        let host = UIView()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.clipsToBounds = true
        tbc.view.addSubview(host)

        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: tbc.view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: tbc.view.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: tbc.tabBar.topAnchor),
            host.heightAnchor.constraint(equalToConstant: floatingHeight + shadowPad)
        ])

        // Bar sits inside host with top padding for the shadow cap
        floatingBar.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(floatingBar)
        NSLayoutConstraint.activate([
            floatingBar.topAnchor.constraint(equalTo: host.topAnchor, constant: shadowPad),
            floatingBar.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            floatingBar.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            floatingBar.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])

        floatingBar.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.topAnchor.constraint(equalTo: floatingBar.topAnchor, constant: 20),
            startButton.leadingAnchor.constraint(equalTo: floatingBar.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: floatingBar.trailingAnchor, constant: -20),
            startButton.bottomAnchor.constraint(equalTo: floatingBar.bottomAnchor, constant: -20)
        ])

        UIView.performWithoutAnimation { tbc.view.layoutIfNeeded() }
        self.host = host
        updateShadowPath() // top-only shadow
    }

    private func uninstallFloatingBar() {
        host?.removeFromSuperview()
        host = nil
    }

    // Draw shadow only on the top cap so nothing overlaps the tab bar
    private func updateShadowPath() {
        guard floatingBar.bounds.width > 0 else { return }
        let r = floatingBar.bounds
        let capHeight: CGFloat = 32
        let cap = CGRect(x: 0, y: 0, width: r.width, height: min(capHeight, r.height))
        let path = UIBezierPath(
            roundedRect: cap,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        floatingBar.layer.shadowPath = path.cgPath
        CATransaction.commit()
    }

    @objc private func startSession() {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .videos
        cfg.selectionLimit = 1
        cfg.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPicker
extension SessionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let item = results.first?.itemProvider else { return }
        let type = UTType.movie.identifier

        guard item.hasItemConformingToTypeIdentifier(type) else { return }

        item.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, err in
            guard let self, let url else { return }
            // Copy to a readable location for later upload/use
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
            do {
                // remove if exists
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: url, to: dest)
                DispatchQueue.main.async {
                    self.handlePickedVideo(at: dest)
                }
            } catch {
                // handle copy error if needed
            }
        }
    }

    private func handlePickedVideo(at url: URL) {
        // Upload video using the view model with loading overlay
        sessionViewModel.uploadVideo(fileURL: url)
    }
}

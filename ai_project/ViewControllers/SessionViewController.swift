import Foundation
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import RealmSwift

final class SessionViewController: UIViewController {
    private let viewModel = VideoUploadViewModel()
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
    private let tableView = UITableView()
    
    // MARK: - Data
    private var userAnalyses: [VideoAnalysisObject] = []
    private var currentUser: UserObject?
    
    // MARK: - Section Types
    private enum Section: Int, CaseIterable {
        case greeting = 0
        case sessionHistory = 1
        case lastSession = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // Light purple-gray background
        hideNavBarHairline()
        
        setupViewModel()
        setupUI()
        loadAnalyses()
        setupNotifications()

        // bar visuals
        floatingBar.backgroundColor = .white
        floatingBar.layer.cornerRadius = 20
        floatingBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        floatingBar.layer.masksToBounds = false
        floatingBar.layer.shadowColor = UIColor.black.cgColor
        floatingBar.layer.shadowOpacity = 0.5
        floatingBar.layer.shadowRadius = 12
        floatingBar.layer.shadowOffset = .init(width: 0, height: 6)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startSession), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installFloatingBarIfNeeded()
        loadUserData()
        loadAnalyses()
        
        // Ensure tab bar has correct background
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.barTintColor = .white
    }
    
    private func setupViewModel() {
        viewModel.onUploadSuccess = { [weak self] videoId in
            print("Video uploaded successfully with ID: \(videoId)")
            // Show success message or navigate to analysis view
        }
        
        viewModel.onUploadFailure = { [weak self] error in
            print("Video upload failed: \(error)")
            // Show error message to user
        }
        
        viewModel.onAnalysisComplete = { [weak self] analysisId in
            print("Video analysis completed with ID: \(analysisId)")
            // Navigate to results view or show success message
        }
        
        viewModel.onAnalysisFailure = { [weak self] error in
            print("Video analysis failed: \(error)")
            // Show error message to user
        }
        
        viewModel.onDataRefreshNeeded = { [weak self] in
            // Notify LessonsViewController to refresh data
            NotificationCenter.default.post(name: .videoAnalysisCompleted, object: nil)
        }
    }
    
    private func setupUI() {
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
        view.addSubview(tableView)
        
        // Register cell classes
        tableView.register(GreetingCell.self, forCellReuseIdentifier: "GreetingCell")
        tableView.register(SessionHistoryCell.self, forCellReuseIdentifier: "SessionHistoryCell")
        tableView.register(VideoAnalysisCell.self, forCellReuseIdentifier: "VideoAnalysisCell")
    }
    

    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -floatingHeight - shadowPad)
        ])
    }
    
    private func loadUserData() {
        // Get current user using UserService
        print("Loading user data")
        currentUser = UserService.shared.getCurrentUser()
        print(currentUser)
    }
    
    private func loadAnalyses() {
        // Load analyses from Realm
        if let realm = try? RealmProvider.make() {
            userAnalyses = Array(realm.objects(VideoAnalysisObject.self).sorted(byKeyPath: "createdAt", ascending: false))
            updateUI()
        }
    }

    private func updateUI() {
        tableView.reloadData()
    }
    
    private func calculateTotalMinutes() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return userAnalyses
            .filter { $0.createdAt >= startOfMonth }
            .compactMap { $0.video?.durationSeconds }
            .reduce(0, +) / 60 // Convert seconds to minutes
    }
    
    private func calculateAverageScore() -> Double {
        guard !userAnalyses.isEmpty else { return 0.0 }
        
        let totalScore = userAnalyses
            .compactMap { $0.professionalScore }
            .reduce(0.0, +)
        
        return totalScore / Double(userAnalyses.count)
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
        loadAnalyses()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - UITableViewDataSource
extension SessionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .greeting:
            return 1
        case .sessionHistory:
            return userAnalyses.isEmpty ? 0 : 1
        case .lastSession:
            return userAnalyses.isEmpty ? 0 : 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .greeting:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GreetingCell", for: indexPath) as! GreetingCell
            cell.configure(with: currentUser)
            return cell
        case .sessionHistory:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SessionHistoryCell", for: indexPath) as! SessionHistoryCell
            let totalMinutes = calculateTotalMinutes()
            let averageScore = calculateAverageScore()
            cell.configure(totalMinutes: totalMinutes, averageScore: averageScore)
            return cell
        case .lastSession:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCell", for: indexPath) as! VideoAnalysisCell
            if let lastAnalysis = userAnalyses.first {
                cell.configure(with: lastAnalysis)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .greeting:
            return nil
        case .sessionHistory:
            return userAnalyses.isEmpty ? nil : "Session History"
        case .lastSession:
            return userAnalyses.isEmpty ? nil : "Last Session"
        }
    }
}

// MARK: - UITableViewDelegate
extension SessionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = Section(rawValue: indexPath.section) else { return 0 }
        
        switch sectionType {
        case .greeting:
            return 80
        case .sessionHistory:
            return 120
        case .lastSession:
            return 160
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .greeting:
            return 0
        case .sessionHistory:
            return userAnalyses.isEmpty ? 0 : 30
        case .lastSession:
            return userAnalyses.isEmpty ? 0 : 30
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .greeting:
            return nil
        case .sessionHistory, .lastSession:
            let headerView = UIView()
            headerView.backgroundColor = .clear
            
            let label = UILabel()
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .label
            label.text = sectionType == .sessionHistory ? "Session History" : "Last Session"
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
            
            return headerView
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .greeting:
            break
        case .sessionHistory:
            break
        case .lastSession:
            if let lastAnalysis = userAnalyses.first {
                let lessonViewController = LessonViewController(analysis: lastAnalysis)
                navigationController?.pushViewController(lessonViewController, animated: true)
            }
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
        viewModel.uploadVideo(fileURL: url, on: self)
    }
}

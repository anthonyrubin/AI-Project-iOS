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
    private let sessionViewModel = SessionViewModel(
        userDataStore: RealmUserDataStore(),
        repository: VideoAnalysisRepository(
            analysisAPI: NetworkManager(tokenManager: TokenManager())
        )
    )
    
    private lazy var loadingOverlay = LoadingOverlay()
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    private weak var videoAnalysisLoadingCell: VideoAnalysisLoadingCell? = nil
    
    private var showLoadingCellPreThumbnail = false
    
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
    private let shadowPad: CGFloat = 24
    private weak var host: UIView?
    
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
        case recentlyAnalyzedHeader
        case recentlyAnalyzedCell
        case none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        makeNavBarTransparent(for: self)
        
        // Ensure tab bar has correct background
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.barTintColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBackgroundGradient()
    }
    
    private func setupBindings() {
        // Bind session data to table view updates
//        sessionViewModel.$userAnalyses
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.tableView.reloadData()
//            }
//            .store(in: &cancellables)
//        
        // Bind user data updates
//        sessionViewModel.$currentUser
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.tableView.reloadData()
//            }
//            .store(in: &cancellables)
        
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
            .sink { [weak self] videoUploaded in
                if videoUploaded == true {
                    // Trigger elegant transition from loading to completed cell
                    self?.handleUploadCompletion()
                }
            }
            .store(in: &cancellables)
        
//        sessionViewModel.$isLoading
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isLoading in
//                print("IS LOADING BE \(isLoading)")
//                if isLoading {
//                    self?.loadingOverlay.show()
//                } else {
//                    self?.loadingOverlay.hide()
//                }
//            }
//            .store(in: &cancellables)
        
        // Bind upload progress
//        sessionViewModel.$uploadProgress
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] progress in
//                self?.updateLoadingCellProgress(progress)
//            }
//            .store(in: &cancellables)
        
        // Bind upload state changes
        sessionViewModel.$isUploadingVideo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isUploading in
                if isUploading == true {
                    self?.tableView.reloadData()
                }
                print("🔄 Upload state changed: \(isUploading)")
                print("🔄 Current upload snapshot: \(self?.sessionViewModel.uploadSnapshot != nil)")
            }
            .store(in: &cancellables)
        
        // Bind upload snapshot changes
//        sessionViewModel.$uploadSnapshot
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] snapshot in
//                print("📸 Snapshot updated: \(snapshot != nil)")
//                self?.tableView.reloadData()
//            }
//            .store(in: &cancellables)
    }
    
    private func handleUploadCompletion() {
        let recentlyAnalyzedIndexPath = getRecentlyAnalyzedIndexPath()

        if let loadingCell = videoAnalysisLoadingCell {
            loadingCell.finishLoading() { [weak self] in
                guard let self = self else { return }
                // TODO: Log here and handle error if self is nil, that would be bad
                UIView.transition(with: self.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                    self.tableView.reloadRows(at: [recentlyAnalyzedIndexPath], with: .none)
                } completion: { _ in
                    self.sessionViewModel.resetUploadState()
                    loadingCell.resetCell()
                }
            }
        } else {
            UIView.transition(with: self.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                self.tableView.reloadRows(at: [recentlyAnalyzedIndexPath], with: .none)
            } completion: { _ in
                self.sessionViewModel.resetUploadState()            }
        }
    }
    
    private func getRecentlyAnalyzedIndexPath() -> IndexPath {
        var row = 0
        
        // Greeting cell
        row += 1
        
        // Session History section (if has analyses)
        if sessionViewModel.hasAnalyses() {
            row += 2 // Header + cell
        }
        
        // Recently Analyzed header
        row += 1
        
        // Recently Analyzed cell
        return IndexPath(row: row, section: 0)
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
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(SessionHistoryCell.self, forCellReuseIdentifier: "SessionHistoryCell")
        tableView.register(VideoAnalysisLoadingCell.self, forCellReuseIdentifier: "VideoAnalysisLoadingCell")
        tableView.register(VideoAnalysisCellNew1.self, forCellReuseIdentifier: "VideoAnalysisCellNew1")
        tableView.register(EmptyStateAnalysisCell.self, forCellReuseIdentifier: "EmptyStateAnalysisCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120  
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
        
        // Last Session section (if has analyses or uploading)
        if sessionViewModel.hasAnalyses() || sessionViewModel.isUploadingVideo {
            // Last Session header
            if row == currentRow {
                return .recentlyAnalyzedHeader
            }
            currentRow += 1
            
            // Last Session cell
            if row == currentRow {
                return .recentlyAnalyzedCell
            }
        }
        
        return .none
    }
    
    private func reloadTablePreDismiss() {
        showLoadingCellPreThumbnail = true
        self.tableView.reloadData()
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
        
        // Last Session section header + cell (if has analyses or uploading)
        if sessionViewModel.hasAnalyses() || sessionViewModel.isUploadingVideo {
            rowCount += 2 // Header + cell
        } else {
            rowCount += 2
        }
        
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        var currentRow = 0
        
        // Greeting cell (row 0)
        if row == currentRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            if let firstName =  sessionViewModel.currentUser?.firstName, !firstName.isEmpty {
                cell.configure(with: "Hello, \(firstName)")
            } else {
                cell.configure(with: "Hello, User")
            }
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
        
        if row == currentRow {
            return setHeaderCell(title: "Recently Analyzed", indexPath: indexPath)
        }
        currentRow += 1
        
        // Last Session section (if has analyses or uploading)
        if sessionViewModel.hasAnalyses() || sessionViewModel.isUploadingVideo {
            // Last Session cell
            if row == currentRow {
                print("🎯 Creating cell for row \(row): isUploading=\(sessionViewModel.isUploadingVideo), hasAnalyses=\(sessionViewModel.hasAnalyses())")
                
                if sessionViewModel.isUploadingVideo || showLoadingCellPreThumbnail {
                    showLoadingCellPreThumbnail = false
                    // Show loading cell with snapshot
                    print("📱 Creating VideoAnalysisLoadingCell")
                    let cell = (tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisLoadingCell", for: indexPath) as! VideoAnalysisLoadingCell)
                    cell.configure(with: sessionViewModel.uploadSnapshot)
                    cell.startLoading()
                    videoAnalysisLoadingCell = cell
                    return videoAnalysisLoadingCell!
                } else if let lastAnalysis = sessionViewModel.lastSession {
                    // Show completed analysis cell
                    print("📱 Creating VideoAnalysisCellNew1")
                    let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCellNew1", for: indexPath) as! VideoAnalysisCellNew1
                    cell.configure(with: lastAnalysis)
                    return cell
                }
            }
        } else {
            // No analyses and not uploading - show empty state
            if row == currentRow {
                print("📱 Creating EmptyStateAnalysisCell")
                return tableView.dequeueReusableCell(withIdentifier: "EmptyStateAnalysisCell", for: indexPath) as! EmptyStateAnalysisCell
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
        case .greeting, .sessionHistoryHeader, .sessionHistoryCell, .recentlyAnalyzedHeader:
            return // No action for these rows
        case .recentlyAnalyzedCell:
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
        reloadTablePreDismiss()
        self.dismiss(animated: true)

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
                DispatchQueue.main.async { [weak self] in
                    self?.handlePickedVideo(at: dest)
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

//var sports = [
//    {
//        "Golf": [
//            "Setup posture (hip hinge, spine angle, knee flex)",
//            "Ball position vs stance",
//            "Shoulder turn at top (°) and hip turn (°)",
//            "X-factor (shoulder–hip separation, °)",
//            "Club path at impact (° in-to-out / out-to-in)",
//            "Face angle vs path (°)",
//            "Attack angle (° up/down)",
//            "Low-point control (in front/behind ball)",
//            "Chip shaft lean at impact (°) and first contact (ball vs turf)",
//            "Putt face angle at impact (°) and stroke path deviation",
//            "Backswing:downswing tempo ratio (~3:1)",
//            "Early extension or lateral sway (pelvis drift)",
//            "Weight shift proxy (lead vs trail hip displacement)",
//            "Clubhead speed proxy (tip velocity)",
//            "Putt tempo and face rotation rate"
//        ],
//        "Baseball (Batting)": [
//            "Stance width (relative to hips)",
//            "Load timing vs pitch release (ms)",
//            "Stride length (% height)",
//            "Hip–shoulder separation at foot strike (°)",
//            "Bat lag angle at lead-arm-parallel (°)",
//            "Bat attack angle (°)",
//            "Swing plane match to pitch plane (° diff)",
//            "Contact point location (in front/behind plate)",
//            "Head movement load→contact (in)",
//            "Time to contact (ms)",
//            "Kinematic sequence order (pelvis→torso→arm→bat)",
//            "Bat speed at contact (tip speed proxy)",
//            "Hand path depth and direction",
//            "Swing decision timing (launch latency, ms)",
//            "(ball) Launch direction/quality at contact"
//        ],
//        "Baseball (Pitching)": [
//            "Stride length (% height)",
//            "Arm slot at release (°)",
//            "Hip–shoulder separation at foot strike (°)",
//            "Trunk tilt at release (°)",
//            "Lead-leg block timing (knee extension velocity timing)",
//            "Release height and forward extension (cm)",
//            "Pelvis rotation timing vs foot strike (ms)",
//            "Tempo: knee-up → foot strike (s)",
//            "Glove-side stability (cm displacement)",
//            "Finish balance (center-of-mass drift, cm)",
//            "Foot-strike alignment vs target line (°)",
//            "Max external rotation timing vs front-foot contact (ms)",
//            "Pronation continuation after release",
//            "Trunk flexion rate into release",
//            "Stride direction error (lateral deviation)"
//        ],
//        "Softball (Fastpitch/Batting)": [
//            "Drive-phase triple extension (hip/knee/ankle angles)",
//            "Arm-circle plane consistency (° variance)",
//            "Stride length (% height) and direction (°)",
//            "Brush interference timing (ms pre-release)",
//            "Release height and forward extension (cm)",
//            "Wrist-snap timing vs hip rotation (ms)",
//            "Posture tilt at release (°)",
//            "Drag-line length (cm)",
//            "Follow-through path and deceleration symmetry",
//            "(batting) Bat attack angle and contact point",
//            "Arm-circle speed and plane-drift consistency",
//            "Resistance/brush timing window tolerance (ms)",
//            "Front-leg block quality (knee extension rate and timing)",
//            "Stride direction error (off power line)",
//            "(ball) Spin axis class if visible"
//        ],
//        "Cricket (Bowling/Batting)": [
//            "Run-up rhythm (last 3 steps cadence, Hz)",
//            "Pre-delivery bound length (cm) and landing alignment (°)",
//            "Front-foot placement vs popping crease (cm)",
//            "Shoulder alignment at release (° to target line)",
//            "Release height and forward extension (cm)",
//            "Wrist position at release (seam axis tilt, °)",
//            "Hip–shoulder separation at front-foot contact (°)",
//            "Follow-through stability (COM drift, cm)",
//            "Batting back-lift angle (°) and downswing plane (°)",
//            "Head over ball at contact and contact point (cm)",
//            "Front-foot contact legality / overstep detection",
//            "Lateral trunk flexion at release (°)",
//            "Seam stability post-release (axis wobble)",
//            "Bat face angle at contact (°)",
//            "Back-lift plane consistency across strokes"
//        ],
//        "Tennis (Serve/Groundstrokes)": [
//            "Toss height (cm) and forward offset (cm)",
//            "Trophy position metrics (shoulder ER, elbow angle)",
//            "Racket drop depth (cm)",
//            "Hip–shoulder separation into uncoil (°)",
//            "Contact point height and forward position (cm)",
//            "Landing inside court (cm) and balance",
//            "Racket lag angle on forehand/backhand (°)",
//            "Low-to-high swing path (°) and finish height",
//            "Split-step timing vs opponent contact (ms)",
//            "Time to recovery (ms)",
//            "Toss variability (x/y drift across reps)",
//            "Over-rotation of shoulders on groundstrokes",
//            "Contact spacing from torso (crowding/reach)",
//            "Racket head speed proxy (drop→contact acceleration)",
//            "Split-step timing accuracy (tolerance-based score)"
//        ],
//        "Pickleball": [
//            "Serve legality (contact below waist, feet behind baseline)",
//            "Serve contact height (cm) and paddle face angle (°)",
//            "Third-shot drop apex height (cm) and landing depth (cm from NVZ)",
//            "Dink contact consistency (cm) and face angle (°)",
//            "Non-volley zone foot faults (detections)",
//            "Transition speed to kitchen line (ms)",
//            "Volley swing length (cm) and contact out-front (cm)",
//            "Ready position paddle height (cm)",
//            "Block reaction time (ms)",
//            "Directional control (target deviation, cm)",
//            "NVZ line management (time within one step of line)",
//            "(ball) Third-shot height window consistency",
//            "Paddle face stability on dinks (variance)",
//            "NVZ volley foot-fault enforcement",
//            "Serve/return to kitchen transition time (ms)"
//        ],
//        "Table Tennis": [
//            "Ready distance from table (cm)",
//            "Stroke length forehand/backhand (cm) and compactness",
//            "Racket angle at contact (°)",
//            "Contact timing vs ball apex (ms)",
//            "Footwork shuffle cadence (Hz) and lateral range (cm)",
//            "Serve toss height (cm) and ≥16 cm legality",
//            "Contact point height above table (cm)",
//            "Recovery time to neutral (ms)",
//            "Elbow/wrist contribution through contact (° change)",
//            "Consistency (consecutive quality contacts)",
//            "Distance-to-table discipline across rallies",
//            "Contact timing tolerance vs apex (tight bands)",
//            "Compactness under pace (no stroke creep)",
//            "Recovery latency scored strictly",
//            "(ball) Serve legality beyond toss (no hiding)"
//        ],
//        "Badminton": [
//            "Split-step timing vs opponent contact (ms)",
//            "Base recovery time to center (ms)",
//            "Overhead contact point height (cm)",
//            "Racket preparation latency (ms)",
//            "Grip-change timing forehand↔backhand (ms)",
//            "Lunge depth (cm) and knee angle (°)",
//            "Non-racket arm balance (°)",
//            "Footwork steps to corner (count) and efficiency",
//            "Smash tip-speed proxy (px/s)",
//            "Drop/clear trajectory quality (apex/landing depth)",
//            "Overhead contact forward offset from body (cm)",
//            "Grip-change timing window accuracy",
//            "Lunge knee-angle minimum with alignment check",
//            "Preparation-latency consistency across exchanges",
//            "Base recovery rule adherence (time window)"
//        ],
//        "Basketball (Shooting)": [
//            "Stance width (cm) and toe alignment (°)",
//            "Dip depth (cm) and timing",
//            "Set-point height (cm)",
//            "Elbow alignment under ball (°)",
//            "Release angle (°) and apex height (cm)",
//            "Wrist snap speed (°/s)",
//            "Lower-to-upper sequencing timing (ms)",
//            "Off-hand influence (ball rotation axis tilt, °)",
//            "Head stillness (cm)",
//            "Catch-to-release time (ms)",
//            "Release speed from set-point (ms)",
//            "Left-right alignment vs rim center (°/cm)",
//            "Jump drift forward/back (cm)",
//            "Set-point consistency across reps",
//            "Elbow-under-ball tolerance window (°)"
//        ],
//        "Soccer (Finishing/Free Kicks)": [
//            "Approach angle (°) and step count",
//            "Plant foot placement (cm to ball and target line)",
//            "Ankle lock at impact (°)",
//            "Hip rotation velocity into strike (°/s)",
//            "Trunk lean at impact (°)",
//            "Contact point on foot (classification)",
//            "Follow-through direction (°) vs target",
//            "(ball) Ball launch angle (°)",
//            "Foot speed at impact (px/s)",
//            "Time from last touch to shot (ms)",
//            "Plant foot rotation (toe line vs target, °)",
//            "Last-step deceleration ratio",
//            "Approach angle consistency across reps",
//            "Shin angle at impact (°)",
//            "(ball) Lateral deviation vs intended target"
//        ],
//        "Volleyball (Serve/Spike)": [
//            "Approach timing profile (ms between steps)",
//            "Penultimate step length ratio",
//            "Toss height and drift (cm)",
//            "Jump height (cm)",
//            "Arm cock angle and external rotation (°)",
//            "Contact point height (cm above net)",
//            "Hit timing vs jump apex (ms)",
//            "Serve contact signature (float vs topspin)",
//            "Landing symmetry (cm drift)",
//            "Block tool/line angle selection (°)",
//            "Approach velocity profile (accelerate then brake)",
//            "Arm-cock timing vs apex (sequencing)",
//            "Contact in front of body (cm)",
//            "Landing asymmetry / valgus risk",
//            "Float vs topspin classification robustness"
//        ],
//        "Lacrosse (Shooting)": [
//            "Hand separation on stick (cm)",
//            "Step length toward target (cm) and direction (°)",
//            "Hip–shoulder separation (°)",
//            "Stick angle at release (°)",
//            "Release height (cm)",
//            "Wrist pronation rate (°/s)",
//            "Follow-through direction (°)",
//            "Cradle-to-release time (ms)",
//            "Head stillness (cm)",
//            "Plant-foot stability (cm sway)",
//            "Lead-foot alignment vs target",
//            "Stick face at release (sail risk)",
//            "Sequence timing pelvis→torso→arm (ms)",
//            "Cradle-to-set latency (decision speed)",
//            "Rear→front weight-transfer completeness"
//        ],
//        "Hockey (Wrist/Slap Shot)": [
//            "Knee flex at load (°)",
//            "Weight transfer rear→front (%)",
//            "Hand separation (cm)",
//            "Puck position at release (cm from lead skate)",
//            "Blade face angle at contact (°)",
//            "Stick flex proxy (shaft bend angle, °)",
//            "Trunk rotation (°) and velocity (°/s)",
//            "Release time from load (ms)",
//            "Follow-through height (cm)",
//            "Balance drift after release (cm)",
//            "Blade contact time window on puck (ms)",
//            "Puck position at load setup (cm)",
//            "Lead-knee angle at release (°)",
//            "Upper–lower separation timing (ms)",
//            "Follow-through line vs target deviation"
//        ],
//        "American Football (QB Throw)": [
//            "Base width (cm) and stagger",
//            "Stride length (cm) and direction (°)",
//            "Hip–shoulder separation at plant (°)",
//            "Arm slot at release (°)",
//            "Max external rotation at late cocking (°)",
//            "Elbow-lead timing (ms)",
//            "Weight-shift timing plant→release (ms)",
//            "Release time from motion start (ms)",
//            "Follow-through path classification",
//            "Head/eye stability (cm)",
//            "Front-foot open angle (°)",
//            "Spiral quality proxy (pronation + path)",
//            "Sequencing timing windows (pelvis→torso→arm)",
//            "Base stability while moving (on-the-run throws)",
//            "Head-level change (vertical bob, cm)"
//        ],
//        "Place Kicking/Punting": [
//            "Approach step cadence and count",
//            "Plant foot placement vs ball (cm)",
//            "Swing plane (°) and arc length (cm)",
//            "Ankle-lock stiffness proxy",
//            "Contact point on ball (classification)",
//            "Trunk lean at impact (°)",
//            "Follow-through height (cm)",
//            "Snap-to-contact time (ms)",
//            "Ball launch angle (°)",
//            "Foot speed at impact (px/s)",
//            "Approach angle and speed profile",
//            "Plant foot rotation and distance tolerances",
//            "Contact height on ball (class)",
//            "Swing plane consistency across reps",
//            "Support-foot pivot behavior"
//        ],
//        "Sprint Mechanics": [
//            "Body angle during acceleration (°)",
//            "Shin angle at contact (°)",
//            "Step length (cm)",
//            "Step frequency (Hz)",
//            "Ground contact time (ms)",
//            "Flight time (ms)",
//            "Vertical oscillation (cm)",
//            "Knee drive height (cm)",
//            "Hip extension at toe-off (°)",
//            "Arm swing amplitude (°) and symmetry",
//            "Front-side vs back-side mechanics ratio",
//            "Braking impulse proxy (contact-time spikes)",
//            "Pelvic tilt control (°)",
//            "Arm–leg contralateral timing (phase)",
//            "Foot strike location vs COM (cm)"
//        ],
//        "Distance Running Gait": [
//            "Cadence (spm)",
//            "Step length (cm) and symmetry",
//            "Ground contact time (ms) and asymmetry (%)",
//            "Vertical oscillation (cm)",
//            "Foot strike location vs COM (cm)",
//            "Overstride angle (°)",
//            "Hip drop (Trendelenburg, °)",
//            "Trunk lean (°)",
//            "Pronation/supination excursion proxy (°)",
//            "Arm swing symmetry (° and tempo)",
//            "Tibial angle at initial contact (°)",
//            "Foot inclination at contact (°)",
//            "Hip-drop magnitude thresholding",
//            "Cadence vs speed zone adherence",
//            "Overstride angle strict bounds"
//        ],
//        "Olympic Lifts (Snatch/Clean & Jerk)": [
//            "Start back angle (°)",
//            "Bar path deviation from vertical (cm)",
//            "First-to-second pull timing (ms)",
//            "Peak bar speed (px/s) and timing",
//            "Triple extension completeness (angles)",
//            "Bar height at turnover (cm)",
//            "Elbow turnover speed (°/s)",
//            "Catch depth (cm) and torso angle (°)",
//            "Foot placement change (cm) and symmetry",
//            "Bar crash speed at rack (px/s)",
//            "Double-knee-bend timing window",
//            "Bar–body distance (horizontal drift, cm)",
//            "Turnover loop width (snatch loop, cm)",
//            "Pull-under speed (turnover time)",
//            "Footwork displacement and symmetry"
//        ],
//        "Powerlifts (Squat/Bench/Deadlift)": [
//            "Squat depth (hip crease vs knee, cm)",
//            "Squat bar-over-midfoot deviation (cm)",
//            "Squat knee valgus at ascent (°)",
//            "Squat trunk-angle drift (°)",
//            "Squat stance width and toe angle (normalized)",
//            "Squat descent tempo and bottom control (ms)",
//            "Bench touchpoint location (cm)",
//            "Bench bar-path J-curve deviation (cm)",
//            "Bench elbow flare angle and timing (°)",
//            "Bench leg-drive timing and stability",
//            "Bench bar-velocity profile / sticking point",
//            "Deadlift bar-break time (ms)",
//            "Deadlift hip-rise vs bar (early-hips ratio)",
//            "Deadlift slack-pull quality (pre-tension)",
//            "Deadlift bar–shin distance drift (cm)"
//        ],
//        "Rowing (Erg Technique)": [
//            "Catch angle (°) and shins vertical check",
//            "Drive:recovery ratio",
//            "Stroke rate (spm)",
//            "Handle path straightness (cm lateral drift)",
//            "Layback angle at finish (°)",
//            "Seat–heels timing (early knee-break flags)",
//            "Catch timing vs flywheel (ms)",
//            "Knee angle at catch (°)",
//            "Over-compression detection",
//            "Split consistency per stroke (variance)",
//            "Drive order (legs→body→arms; reverse on recovery)",
//            "Handle speed profile (peak mid-drive)",
//            "Slide control quality (no rushing the slide)",
//            "Catch posture lumbar-flexion proxy",
//            "Ratio target scoring (1:2–1:3)"
//        ],
//        "Striking (Boxing/Kickboxing/TKD)": [
//            "Stance width and guard height (cm)",
//            "Jab extension and retraction time (ms)",
//            "Hip rotation on cross (°) and timing (ms)",
//            "Hook elbow angle (°) and shoulder rotation (°)",
//            "Return-to-guard latency after strike (ms)",
//            "Head-movement timing after strike (ms)",
//            "Roundhouse support-foot pivot (°)",
//            "Kick chamber height (cm) and knee path",
//            "Combination tempo (inter-strike interval, ms)",
//            "Distance management (entry/exit efficiency)",
//            "Chin position and post-strike guard-drop time",
//            "Weight-shift timing on cross/hook",
//            "Exit on angles time after combo (ms)",
//            "Support-foot pivot tolerance on kicks (°)",
//            "Defensive head-movement timing vs opponent window"
//        ]
//    }
//]

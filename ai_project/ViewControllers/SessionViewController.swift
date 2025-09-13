import UIKit
import Combine
import PhotosUI

class NonStickyTableView: UITableView {
    override var style: UITableView.Style { .plain }
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
    
    // MARK: - Upload State Management
    var uploadStateManager: UploadStateManager?

    private weak var videoAnalysisLoadingCell: VideoAnalysisLoadingCell? = nil
    private var showLoadingCellPreThumbnail = false

    // MARK: - UI
    private let tableView = NonStickyTableView()

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Section/Row enums (unchanged)
    private enum Section: Int, CaseIterable { case greeting = 0, sessionHistory = 1, lastSession = 2 }
    private enum RowType { case greeting, sessionHistoryHeader, sessionHistoryCell, recentlyAnalyzedHeader, recentlyAnalyzedCell, none }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        sessionViewModel.loadUserData()
        sessionViewModel.loadAnalyses()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBackgroundGradient()
    }

    private func setupBindings() {
        sessionViewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let self, let errorMessage else { return }
                self.errorModalManager.showError(errorMessage)
                self.sessionViewModel.clearError()
            }
            .store(in: &cancellables)

        // Observe upload state from UploadStateManager
        uploadStateManager?.$isUploading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isUploading in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        uploadStateManager?.$uploadCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completed in
                if completed {
                    self?.handleUploadCompletion()
                }
            }
            .store(in: &cancellables)
        
        uploadStateManager?.$uploadError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorModalManager.showError(error)
                    self?.uploadStateManager?.clearError()
                }
            }
            .store(in: &cancellables)
    }

    private func handleUploadCompletion() {
        let recentlyAnalyzedIndexPath = getRecentlyAnalyzedIndexPath()

        if let loadingCell = videoAnalysisLoadingCell {
            loadingCell.finishLoading() { [weak self] in
                guard let self else { return }
                UIView.transition(with: self.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                    self.tableView.reloadRows(at: [recentlyAnalyzedIndexPath], with: .none)
                } completion: { _ in
                    loadingCell.resetCell()
                }
            }
        } else {
            UIView.transition(with: self.tableView, duration: 0.5, options: .transitionCrossDissolve) {
                self.tableView.reloadRows(at: [recentlyAnalyzedIndexPath], with: .none)
            } completion: { _ in
                // Upload completed
            }
        }
    }

    private func getRecentlyAnalyzedIndexPath() -> IndexPath {
        var row = 0
        row += 1 // greeting
        if sessionViewModel.hasAnalyses() { row += 2 } // history header + cell
        row += 1 // recently analyzed header
        return IndexPath(row: row, section: 0)
    }

    // MARK: - UI setup (no floating bar anymore)
    private func setupUI() {
        view.backgroundColor = .systemBackground
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
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = .zero

        view.addSubview(tableView)

        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(SessionHistoryCell.self, forCellReuseIdentifier: "SessionHistoryCell")
        tableView.register(VideoAnalysisLoadingCell.self, forCellReuseIdentifier: "VideoAnalysisLoadingCell")
        tableView.register(VideoAnalysisCellNew1.self, forCellReuseIdentifier: "VideoAnalysisCellNew1")
        tableView.register(EmptyStateAnalysisCell.self, forCellReuseIdentifier: "EmptyStateAnalysisCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // no extra space for a floating bar
        ])
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .videoAnalysisCompleted, object: nil)
    }

    @objc private func refreshData() { sessionViewModel.refreshData() }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }

    private func getRowType(for row: Int) -> RowType {
        var currentRow = 0
        if row == currentRow { return .greeting }
        currentRow += 1

        if sessionViewModel.hasAnalyses() {
            if row == currentRow { return .sessionHistoryHeader }
            currentRow += 1
            if row == currentRow { return .sessionHistoryCell }
            currentRow += 1
        }

        if row == currentRow { return .recentlyAnalyzedHeader }
        currentRow += 1

        if sessionViewModel.hasAnalyses() || (uploadStateManager?.isUploading ?? false) {
            if row == currentRow { return .recentlyAnalyzedCell }
        } else if row == currentRow {
            return .recentlyAnalyzedCell // empty state cell below
        }
        return .none
    }

    private func reloadTablePreDismiss() {
        showLoadingCellPreThumbnail = true
        tableView.reloadData()
    }

    // Keep startSession() for now (unused) so your future + action can call it.
//    @objc private func startSession() {
//        var cfg = PHPickerConfiguration(photoLibrary: .shared())
//        cfg.filter = .videos
//        cfg.selectionLimit = 1
//        cfg.preferredAssetRepresentationMode = .current
//        let picker = PHPickerViewController(configuration: cfg)
//        picker.delegate = self
//        present(picker, animated: true)
//    }
}

// MARK: - UITableViewDataSource
extension SessionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        rowCount += 1 // greeting
        if sessionViewModel.hasAnalyses() { rowCount += 2 }
        // recently analyzed header + cell always allocated
        rowCount += 2
        return rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        var currentRow = 0

        if row == currentRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            if let firstName = sessionViewModel.currentUser?.firstName, !firstName.isEmpty {
                cell.configure(with: "Hello, \(firstName)")
            } else {
                cell.configure(with: "Hello, User")
            }
            return cell
        }
        currentRow += 1

        if sessionViewModel.hasAnalyses() {
            if row == currentRow { return setHeaderCell(title: "Session History", indexPath: indexPath) }
            currentRow += 1

            if row == currentRow {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SessionHistoryCell", for: indexPath) as! SessionHistoryCell
                cell.configure(totalMinutes: sessionViewModel.totalMinutesAnalyzed, averageScore: sessionViewModel.averageScore)
                return cell
            }
            currentRow += 1
        }

        if row == currentRow { return setHeaderCell(title: "Recently Analyzed", indexPath: indexPath) }
        currentRow += 1

        if row == currentRow {
            if (uploadStateManager?.isUploading ?? false) || showLoadingCellPreThumbnail {
                showLoadingCellPreThumbnail = false
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisLoadingCell", for: indexPath) as! VideoAnalysisLoadingCell
                cell.configure(with: uploadStateManager?.uploadSnapshot)
                cell.startLoading()
                videoAnalysisLoadingCell = cell
                return cell
            } else if let lastAnalysis = sessionViewModel.lastSession {
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCellNew1", for: indexPath) as! VideoAnalysisCellNew1
                cell.configure(with: lastAnalysis)
                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "EmptyStateAnalysisCell", for: indexPath) as! EmptyStateAnalysisCell
            }
        }

        return UITableViewCell()
    }

    func setHeaderCell(title: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
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
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowType = getRowType(for: indexPath.row)
        switch rowType {
        case .recentlyAnalyzedCell:
            if let last = sessionViewModel.lastSession {
                let lesson = LessonViewController(analysis: last)
                lesson.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(lesson, animated: true)
            }
        default: break
        }
    }
}

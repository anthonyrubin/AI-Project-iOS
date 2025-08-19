import Foundation
import UIKit
import Combine

class LessonsViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    // MARK: - Title Cell Components
    private let titleLabel = UILabel()
    private let inboxButton = UIButton(type: .system)
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    
    // MARK: - ViewModel
    private let viewModel = LessonsViewModel(
        repository: VideoAnalysisRepository(
            networkManager: NetworkManager(
                tokenManager: TokenManager()
            )
        ),
        networkManager: NetworkManager(
            tokenManager: TokenManager()
        )
    )

    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customBackgroundColor()
        viewModel.refreshAnalyses()
        setupUI()
        setupTableView()
        setupBindings()
        viewModel.loadAnalyses()
        setupNotifications()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupBindings() {
        // Bind analyses to table view updates
        viewModel.$analyses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // Bind loading state to refresh control
        viewModel.$isRefreshing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshing in
                if !isRefreshing {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)
        

        
        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorModalManager.showError(errorMessage)
                    self?.viewModel.clearError()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoAnalysisCell.self, forCellReuseIdentifier: "VideoAnalysisCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TitleInboxCell")
        tableView.separatorStyle = .none // Remove separator lines for card design
        tableView.backgroundColor = .systemGroupedBackground // Better background for cards
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func refreshData() {
        viewModel.refreshAnalyses()
    }
    
    @objc private func inboxButtonTapped() {
        let inboxViewController = InboxViewController()
        navigationController?.pushViewController(inboxViewController, animated: true)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVideoAnalysisCompleted),
            name: .videoAnalysisCompleted,
            object: nil
        )
    }
    
    @objc private func handleVideoAnalysisCompleted() {
        // Refresh data when new analysis is completed
        viewModel.refreshAnalyses()
    }
    

    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

// MARK: - UITableViewDataSource
extension LessonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Add 1 for the title cell, plus the number of analysis cells
        return 1 + viewModel.getAnalysesCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // Title cell (first row)
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleInboxCell", for: indexPath)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            
            // Remove any existing subviews
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Configure title label (matching GreetingCell style exactly)
            titleLabel.text = "History"
            titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
            titleLabel.textColor = .label
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(titleLabel)
            
            // Configure inbox button
            inboxButton.setImage(UIImage(systemName: "tray"), for: .normal)
            inboxButton.tintColor = .label
            inboxButton.translatesAutoresizingMaskIntoConstraints = false
            inboxButton.addTarget(self, action: #selector(inboxButtonTapped), for: .touchUpInside)
            cell.contentView.addSubview(inboxButton)
            
            // Setup constraints (matching GreetingCell exactly)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -20),
                titleLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                
                inboxButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -20),
                inboxButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                inboxButton.widthAnchor.constraint(equalToConstant: 44),
                inboxButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            return cell
        } else {
            // Analysis cells (offset by 1 for title cell)
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCell", for: indexPath) as! VideoAnalysisCell
            
            if let analysis = viewModel.getAnalysis(at: indexPath.row - 1) {
                cell.configure(with: analysis)
            }
            
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension LessonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Only handle selection for analysis cells (not title cell)
        if indexPath.row > 0 {
            if let analysis = viewModel.getAnalysis(at: indexPath.row - 1) {
                let lessonViewController = LessonViewController(analysis: analysis)
                navigationController?.pushViewController(lessonViewController, animated: true)
            }
        }
    }
}

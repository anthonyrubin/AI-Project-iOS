import Foundation
import UIKit
import Combine

class LessonsViewController: UIViewController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    
    // MARK: - ViewModel
    private let viewModel = LessonsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavBarHairline()
        setupUI()
        setupTableView()
        setupBindings()
        viewModel.loadAnalyses()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        viewModel.refreshAnalyses()
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
                    ErrorModalManager.shared.showError(errorMessage, from: self!)
                    self?.viewModel.clearError()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoAnalysisCell.self, forCellReuseIdentifier: "VideoAnalysisCell")
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
        return viewModel.getAnalysesCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCell", for: indexPath) as! VideoAnalysisCell
        
        if let analysis = viewModel.getAnalysis(at: indexPath.row) {
            cell.configure(with: analysis)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LessonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160 // Increased height to accommodate better spacing
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let analysis = viewModel.getAnalysis(at: indexPath.row) {
            let lessonViewController = LessonViewController(analysis: analysis)
            navigationController?.pushViewController(lessonViewController, animated: true)
        }
    }
}

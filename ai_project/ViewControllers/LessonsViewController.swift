import Foundation
import UIKit
import RealmSwift

class LessonsViewController: UIViewController {
    
    private let tableView = UITableView()
    private let repository = VideoAnalysisRepository.shared
    private var analyses: Results<VideoAnalysisObject>?
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavBarHairline()
        setupUI()
        setupTableView()
        loadData()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        refreshData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
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
    
    private func loadData() {
        do {
            analyses = repository.getAllAnalyses()
            
            print("Analysis be")
            print(analyses)
            
            // Observe changes
            notificationToken = analyses?.observe { [weak self] changes in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        } catch {
            print("❌ Error loading data: \(error)")
            // Show error modal
            ErrorModalManager.shared.showError(error, from: self)
        }
    }
    
    @objc private func refreshData() {
        repository.fetchAndStoreNewAnalyses { [weak self] result in
            DispatchQueue.main.async {
                self?.tableView.refreshControl?.endRefreshing()
                
                switch result {
                case .success(let newAnalyses):
                    print("Fetched \(newAnalyses.count) new analyses")
                case .failure(let error):
                    print("Error fetching analyses: \(error)")
                    // Show error modal
                    ErrorModalManager.shared.showError(error, from: self!)
                }
            }
        }
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
        refreshData()
    }
    
    // This method is no longer needed since we use ErrorModalManager
    // private func showErrorAlert(message: String) {
    //     let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    //     alert.addAction(UIAlertAction(title: "OK", style: .default))
    //     present(alert, animated: true)
    // }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource
extension LessonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        do {
            return analyses?.count ?? 0
        } catch {
            print("❌ Error getting analysis count: \(error)")
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoAnalysisCell", for: indexPath) as! VideoAnalysisCell
        
        do {
            if let analysis = analyses?[indexPath.row] {
                cell.configure(with: analysis)
            }
        } catch {
            print("❌ Error configuring cell at index \(indexPath.row): \(error)")
            // Configure with placeholder data or show error state
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
        
        if let analysis = analyses?[indexPath.row] {
            let lessonViewController = LessonViewController(analysis: analysis)
            navigationController?.pushViewController(lessonViewController, animated: true)
        }
    }
}

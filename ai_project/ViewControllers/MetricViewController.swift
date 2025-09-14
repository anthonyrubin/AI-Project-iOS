import UIKit

class MetricViewController: UIViewController {
    
    // MARK: - Properties
    private let metricName: String
    private let metricBreakdown: MetricBreakdown
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let scoreRingView: ScoreRingView
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let analysisLabel = UILabel()
    private let analysisTextView = UITextView()
    private let improvementLabel = UILabel()
    private let improvementTextView = UITextView()
    
    // MARK: - Initialization
    init(metricName: String, metricBreakdown: MetricBreakdown) {
        self.metricName = metricName
        self.metricBreakdown = metricBreakdown
        self.scoreRingView = ScoreRingView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = metricBreakdown.human_readable_name
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup labels
        setupLabels()
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(scoreRingView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(analysisLabel)
        contentView.addSubview(analysisTextView)
        contentView.addSubview(improvementLabel)
        contentView.addSubview(improvementTextView)
    }
    
    private func setupLabels() {
        // Title label
        titleLabel.text = metricBreakdown.human_readable_name
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description label
        descriptionLabel.text = metricBreakdown.description
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Analysis label
        analysisLabel.text = "Analysis"
        analysisLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        analysisLabel.textColor = .label
        analysisLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Improvement label
        improvementLabel.text = "How to Improve"
        improvementLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        improvementLabel.textColor = .label
        improvementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Analysis text view
        analysisTextView.text = metricBreakdown.analysis_text
        analysisTextView.font = .systemFont(ofSize: 16, weight: .regular)
        analysisTextView.textColor = .label
        analysisTextView.backgroundColor = .clear
        analysisTextView.isEditable = false
        analysisTextView.isScrollEnabled = false
        analysisTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Improvement text view
        improvementTextView.text = metricBreakdown.how_to_improve
        improvementTextView.font = .systemFont(ofSize: 16, weight: .regular)
        improvementTextView.textColor = .label
        improvementTextView.backgroundColor = .clear
        improvementTextView.isEditable = false
        improvementTextView.isScrollEnabled = false
        improvementTextView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Score ring view
            scoreRingView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            scoreRingView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: scoreRingView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Analysis label
            analysisLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            analysisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            analysisLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Analysis text view
            analysisTextView.topAnchor.constraint(equalTo: analysisLabel.bottomAnchor, constant: 8),
            analysisTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            analysisTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Improvement label
            improvementLabel.topAnchor.constraint(equalTo: analysisTextView.bottomAnchor, constant: 24),
            improvementLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            improvementLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Improvement text view
            improvementTextView.topAnchor.constraint(equalTo: improvementLabel.bottomAnchor, constant: 8),
            improvementTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            improvementTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            improvementTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
}

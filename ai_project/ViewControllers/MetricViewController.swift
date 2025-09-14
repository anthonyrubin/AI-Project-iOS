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
    private let improvementLabel = UILabel()
    
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
        populateContent()
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
        contentView.addSubview(improvementLabel)
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
            
            // Improvement label
            improvementLabel.topAnchor.constraint(equalTo: analysisLabel.bottomAnchor, constant: 16),
            improvementLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            improvementLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            improvementLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func populateContent() {
        // Create analysis text view
        let analysisTextView = createTextView(text: metricBreakdown.analysis_text)
        contentView.addSubview(analysisTextView)
        
        // Create improvement text view
        let improvementTextView = createTextView(text: metricBreakdown.how_to_improve)
        contentView.addSubview(improvementTextView)
        
        // Update constraints
        NSLayoutConstraint.activate([
            analysisTextView.topAnchor.constraint(equalTo: analysisLabel.bottomAnchor, constant: 8),
            analysisTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            analysisTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            improvementTextView.topAnchor.constraint(equalTo: improvementLabel.bottomAnchor, constant: 8),
            improvementTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            improvementTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            improvementTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createTextView(text: String) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate height based on content
        let size = textView.sizeThatFits(CGSize(width: view.frame.width - 40, height: CGFloat.greatestFiniteMagnitude))
        textView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        
        return textView
    }
}

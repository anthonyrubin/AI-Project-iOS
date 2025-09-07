import UIKit

final class LoadingOverlay: UIView {

    // MARK: - UI

    private let containerView = UIView()
    private let activityIndicatorSubContainer = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        isUserInteractionEnabled = true // block touches
        
        activityIndicatorSubContainer.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorSubContainer.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        containerView.addSubview(activityIndicatorSubContainer)
        activityIndicatorSubContainer.addSubview(activityIndicator)
        
        activityIndicatorSubContainer.layer.cornerRadius = 12

        // Container
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Spinner
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicatorSubContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicatorSubContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorSubContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorSubContainer.centerYAnchor),
            activityIndicatorSubContainer.widthAnchor.constraint(equalToConstant: 100),
            activityIndicatorSubContainer.heightAnchor.constraint(equalToConstant: 100),
        ])
    }

    // MARK: - Public API

    func show(in hostView: UIView) {
        activityIndicator.startAnimating()

        translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(self)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            topAnchor.constraint(equalTo: hostView.topAnchor),
            bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.activityIndicator.stopAnimating()
            self.removeFromSuperview()
        }
    }
}

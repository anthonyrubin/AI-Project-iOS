import UIKit

class BaseSignupViewController: UIViewController {
    
    // MARK: - Public API
    var progress: Float = 0 { didSet { updateProgress(animated: false) } }
    var hidesProgressBar: Bool = false { didSet { progressView?.isHidden = hidesProgressBar } }
    
    let continueButton = UIButton(type: .system)
    private var hasSecondaryButton = false
    
    var killDefaultLayout = false
    
    let secondaryButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .clear
        b.contentHorizontalAlignment = .center

        let baseFont = UIFont.systemFont(ofSize: 14, weight: .regular)

        b.titleLabel?.font = baseFont
        b.applyTactileTap()
        return b
    }()
    
    // MARK: - Private (nav-bar mounted progress)
    private static let progressTag = 426_888
    private weak var progressView: UIProgressView?
    private weak var backButton: UIButton?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNav()
        attachProgressInTitleView()   // now mounts on the nav bar
        setupContinueButton()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachProgressInTitleView()                 // ensure it's on this nav bar
        progressView?.isHidden = hidesProgressBar
        progressView?.setProgress(progress, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If we're navigating to a non-signup VC, hide the bar so it doesn't "stick"
        if let toVC = transitionCoordinator?.viewController(forKey: .to) {
            if !(toVC is BaseSignupViewController) {
                progressView?.isHidden = true
            }
        } else {
            // No coordinator (e.g. dismiss) → hide by default
            progressView?.isHidden = true
        }
    }
    
    // MARK: - Progress
    func setProgress(_ value: Float, animated: Bool) {
        let clamped = max(0, min(1, value))
        progress = clamped
        attachProgressInTitleView()
        progressView?.setProgress(clamped, animated: animated)
    }
    
    private func updateProgress(animated: Bool) {
        progressView?.setProgress(progress, animated: animated)
    }
    
    /// Mounts the progress bar ON the UINavigationBar (keeps old name for call sites).
    private func attachProgressInTitleView() {
        guard let navBar = navigationController?.navigationBar else { return }
        
        // Reuse if present
        if let existing = navBar.viewWithTag(Self.progressTag) as? UIProgressView {
            progressView = existing
            return
        }
        
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.tag = Self.progressTag
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = .quaternaryLabel
        pv.progressTintColor = .label
        pv.layer.cornerRadius = 2
        pv.clipsToBounds = true
        
        navBar.addSubview(pv)
        
        // Fixed fraction width to avoid collapsing; perfectly centered vertically in the nav bar.
        let widthMultiplier: CGFloat = 0.66
        var cs: [NSLayoutConstraint] = [
            pv.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),                 // vertical center
            pv.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),                 // horizontal center
            pv.widthAnchor.constraint(equalTo: navBar.widthAnchor, multiplier: widthMultiplier),
            pv.heightAnchor.constraint(equalToConstant: 3),
            pv.leadingAnchor.constraint(greaterThanOrEqualTo: navBar.layoutMarginsGuide.leadingAnchor),
            pv.trailingAnchor.constraint(lessThanOrEqualTo: navBar.layoutMarginsGuide.trailingAnchor)
        ]
        
        // Leave space for the circular back button if present
        if let backBtn = backButton, backBtn.superview != nil {
            cs.append(pv.leadingAnchor.constraint(greaterThanOrEqualTo: backBtn.trailingAnchor, constant: 12))
        } else {
            // Fallback clearance for default back chevron
            cs.append(pv.leadingAnchor.constraint(greaterThanOrEqualTo: navBar.layoutMarginsGuide.leadingAnchor, constant: 56))
        }
        
        NSLayoutConstraint.activate(cs)
        progressView = pv
    }
    
    // MARK: - Nav helpers
    @objc func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupNav() {
        // Circular back
        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = .label
        backBtn.backgroundColor = UIColor.systemGray5
        backBtn.layer.cornerRadius = 16
        backBtn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            backBtn.heightAnchor.constraint(equalToConstant: 32)
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        backButton = backBtn
        
        // Keep call to preserve your flow (now mounts to nav bar)
        attachProgressInTitleView()

        title = nil
    }

    func setupSecondaryButton(text: String, selector: Selector) {
        secondaryButton.setTitle(text, for: .normal)
        secondaryButton.setTitleColor(.black, for: .normal) // or default .system tint if you prefer
        secondaryButton.contentHorizontalAlignment = .center
        secondaryButton.backgroundColor = .clear
        secondaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        secondaryButton.addTarget(self, action: selector, for: .touchUpInside)
        secondaryButton.applyTactileTap()
        
        hasSecondaryButton = true
    }
    
    // MARK: - Continue button
    func setupContinueButton() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .label
        continueButton.tintColor = .systemBackground
        continueButton.layer.cornerRadius = 28
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        continueButton.applyTactileTap()
    }
    
    func layout() {
        if !killDefaultLayout {
            view.addSubview(secondaryButton)
            view.addSubview(continueButton)
            let g = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                continueButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
                continueButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
                continueButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),
                continueButton.heightAnchor.constraint(equalToConstant: 56)
            ])
            
            if hasSecondaryButton {
                NSLayoutConstraint.activate([
                    secondaryButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
                    secondaryButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
                    secondaryButton.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
                ])
            }
        }
    }
    
    @objc func didTapContinue() {
        // override in subclasses
    }
}

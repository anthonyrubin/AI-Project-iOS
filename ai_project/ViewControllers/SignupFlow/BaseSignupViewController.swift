import UIKit

class BaseSignupViewController: UIViewController {
    
    // MARK: - Public API
    var hidesProgressBar: Bool = false { didSet { progressView?.isHidden = hidesProgressBar } }
    
    let continueButton = UIButton(type: .system)
    private var hasSecondaryButton = false
    
    var killDefaultLayout = false
    var hideBackButton = false
    
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
    private var progress = Float(0)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNav(hideBackButton: hideBackButton)
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
        attachProgressInTitleView()
        progress = value
        progressView?.setProgress(progress, animated: animated)
    }
    
    
    // Tweak these once to match your UI.
    private enum SignupNavFixed {
        static let backLeading: CGFloat   = 16   // space from left edge to start of back button
        static let backWidth: CGFloat     = 32   // your circular back = 32x32
        static let gapAfterBack: CGFloat  = 12   // gap from back to bar

        static let pillTrailing: CGFloat  = 15   // you said trailing == 15
        static let pillWidth: CGFloat     = 64   // <-- SET THIS to your pill's width (flag+EN)
        static let gapBeforePill: CGFloat = 12   // gap from bar to pill

        static let barHeight: CGFloat     = 3
        static let minWidth: CGFloat      = 140  // never look like a toothpick
    }

    private func attachProgressInTitleView() {
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.layoutIfNeeded()

        // remove old one (cheap way to re-apply constraints cleanly)
        if let old = navBar.viewWithTag(Self.progressTag) as? UIProgressView { old.removeFromSuperview() }

        let pv: UIProgressView = {
            let v = UIProgressView(progressViewStyle: .bar)
            v.tag = Self.progressTag
            v.trackTintColor = .quaternaryLabel
            v.progressTintColor = .label
            v.layer.cornerRadius = 2
            v.clipsToBounds = true
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        // Hard-coded edges (points from left/right of nav bar)
        let leftEdge  = SignupNavFixed.backLeading + SignupNavFixed.backWidth + SignupNavFixed.gapAfterBack
        let rightEdge = SignupNavFixed.pillTrailing + SignupNavFixed.pillWidth + SignupNavFixed.gapBeforePill

        // If the math makes the region too small, relax the right side so we keep >= minWidth.
        let available = navBar.bounds.width - (leftEdge + rightEdge)
        let needExtra = max(0, SignupNavFixed.minWidth - available)
        let relaxedRightEdge = max(0, rightEdge - needExtra) // pull away from the right side if cramped

        UIView.performWithoutAnimation {
            navBar.addSubview(pv)
            pv.setProgress(progress, animated: false)

            // Pin exactly between the fixed edges
            let lead = pv.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: leftEdge)
            let trail = pv.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -relaxedRightEdge)
            // Keep a minimum width safety (just in case of rotations, etc.)
            let minW = pv.widthAnchor.constraint(greaterThanOrEqualToConstant: SignupNavFixed.minWidth)
            minW.priority = .required

            NSLayoutConstraint.activate([
                pv.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
                pv.heightAnchor.constraint(equalToConstant: SignupNavFixed.barHeight),
                lead, trail, minW
            ])

            navBar.layoutIfNeeded()
        }

        progressView = pv
    }

    
    // MARK: - Nav helpers
    @objc func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupNav(hideBackButton: Bool) {
        // Circular back
        if !hideBackButton {
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
        } else {
            navigationItem.setLeftBarButton(nil, animated: false)
            navigationItem.hidesBackButton = hideBackButton
            navigationItem.leftItemsSupplementBackButton = false
        }
        
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

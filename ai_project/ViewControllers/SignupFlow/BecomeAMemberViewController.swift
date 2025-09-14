import UIKit
import StoreKit
import Combine


final class BecomeAMemberViewController: BaseSignupViewController {

    // MARK: - Dependencies
    private let viewModel = BecomeAMemberViewModel(
        repository: VideoAnalysisRepository(
            analysisAPI: NetworkManager(tokenManager: TokenManager())
        ),
        membershipAPI: NetworkManager(tokenManager: TokenManager())
    )

    // MARK: - Header / summary
    private let laurel5StarsView = Laurel5StarsView()
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    private lazy var loadingOverlay = LoadingOverlay()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Subscribe to unlock your full potential"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Get instant AI analysis and feedback, track your progress over time, and more."
        l.font = .systemFont(ofSize: 18)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let summarySectionTitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.text = "AI Analysis Summary"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let summaryView: UIView = {
        let v = UIView()
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 12
        v.layer.borderColor = UIColor.systemGray.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreRingView = ScoreRingView()

    private let summaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    let restoreButton = UIButton(type: .system)

    // MARK: - Scroll container
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Events card + overlay
    private let eventsView = UIView()
    private let eventsStack = UIStackView()
    private let overlay = EventsPaywallOverlay()

    // Constraints we mutate
    private var overlayTopConstraint: NSLayoutConstraint!
    private var eventsHeightConstraint: NSLayoutConstraint!

    // MARK: - Sticky CTA + spacer
    private let stickyCard = StickyCTAView()
    private let bottomSpacer = UIView()
    private var spacerHeight: NSLayoutConstraint!
    private let spacerExtra: CGFloat = 12

    // MARK: - Pixel-based cutoff (in points)
    /// Amount of content (in points) to leave visible at the top of the card.
    /// The overlay starts exactly after this many points.
    var freeRevealHeight: CGFloat = 100 {
        didSet {
            freeRevealHeight = max(0, freeRevealHeight)
            if isViewLoaded { repositionOverlay() }
        }
    }

    // MARK: - Membership Properties
    
    private let storeKitManager = StoreKitManager.shared
    private lazy var membershipManager: MembershipManager = {
        let networkManager = NetworkManager(tokenManager: TokenManager())
        return MembershipManager(networkManager: networkManager)
    }()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        setupMembershipBindings()
        hideBackButton = true
        hidesProgressBar = true
        buildUI()
        super.viewDidLoad()

        buildEventsRows()
        repositionOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var aiScore = 0
        
        if let _aiScore = viewModel.getLastUpload()?.liftScore {
            aiScore = Int(_aiScore)
        }
        scoreRingView.animate(to: aiScore, duration: 0.6)
        updateCardInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardInsets()
        repositionOverlay() // handle rotations / width changes
    }

    // MARK: - Build UI

    private func buildUI() {
        view.backgroundColor = .systemBackground

        summaryLabel.text = viewModel.getLastUpload()?.overallAnalysis
        summaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // Scroll + content
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Header/summary
        [titleLabel, subtitleLabel, laurel5StarsView, summarySectionTitle, summaryView, eventsView, bottomSpacer]
            .forEach { contentView.addSubview($0) }
        laurel5StarsView.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false

        summaryView.addSubview(summaryStack)
        summaryStack.addArrangedSubview(scoreRingView)
        summaryStack.addArrangedSubview(summaryLabel)
        scoreRingView.translatesAutoresizingMaskIntoConstraints = false

        // Events card
        eventsView.layer.borderWidth = 1
        eventsView.layer.cornerRadius = 12
        eventsView.layer.borderColor = UIColor.systemGray.cgColor
        eventsView.backgroundColor = .systemBackground
        eventsView.clipsToBounds = true
        eventsView.translatesAutoresizingMaskIntoConstraints = false

        // Events stack (your rows)
        eventsStack.axis = .vertical
        eventsStack.alignment = .fill
        eventsStack.spacing = 16
        eventsStack.translatesAutoresizingMaskIntoConstraints = false
        eventsView.addSubview(eventsStack)

        // Overlay
        overlay.translatesAutoresizingMaskIntoConstraints = false
        eventsView.addSubview(overlay)
        eventsView.bringSubviewToFront(overlay)
        
        view.addSubview(stickyCard)

        restoreButton.setTitle("Restore Purchases", for: .normal)
        stickyCard.ctaButton.setTitle("Continue", for: .normal)
        restoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        restoreButton.setTitleColor(.systemBlue, for: .normal)
        restoreButton.backgroundColor = .clear
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.addTarget(self, action: #selector(restorePurchasesTapped), for: .touchUpInside)
        
        view.addSubview(restoreButton)

        // Control indicator insets manually
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false

        stickyCard.ctaButton.addTarget(self, action: #selector(didTapMembershipButton), for: .touchUpInside)
    }

    override func layout() {
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        spacerHeight = bottomSpacer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Scroll frame (full screen)
            frame.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            frame.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frame.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frame.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Scroll content
            contentView.topAnchor.constraint(equalTo: content.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frame.widthAnchor),

            // Header
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            laurel5StarsView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            laurel5StarsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            laurel5StarsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            summarySectionTitle.topAnchor.constraint(equalTo: laurel5StarsView.bottomAnchor, constant: 60),
            summarySectionTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summarySectionTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Summary card
            summaryView.topAnchor.constraint(equalTo: summarySectionTitle.bottomAnchor, constant: 15),
            summaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            summaryStack.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 10),
            summaryStack.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 10),
            summaryStack.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -10),
            summaryStack.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -10),

            scoreRingView.widthAnchor.constraint(equalToConstant: 70),
            scoreRingView.heightAnchor.constraint(equalToConstant: 70),

            // Events card
            eventsView.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 20),
            eventsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Rows inside card
            eventsStack.topAnchor.constraint(equalTo: eventsView.topAnchor, constant: 16),
            eventsStack.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor, constant: 16),
            eventsStack.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor, constant: -16),

            // Overlay pinned sides + bottom (we only move TOP)
            overlay.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: eventsView.bottomAnchor),

            // Bottom spacer so content doesn’t hide behind sticky card
            bottomSpacer.topAnchor.constraint(equalTo: eventsView.bottomAnchor, constant: 20),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            spacerHeight,
            
            stickyCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restoreButton.bottomAnchor.constraint(equalTo: stickyCard.topAnchor, constant: -16)
        ])

        // Mutable constraints we update at runtime
        eventsHeightConstraint = eventsView.heightAnchor.constraint(equalToConstant: 260)
        eventsHeightConstraint.priority = .required
        eventsHeightConstraint.isActive = true

        overlayTopConstraint = overlay.topAnchor.constraint(equalTo: eventsView.topAnchor)
        overlayTopConstraint.isActive = true
    }

    // MARK: - Build event rows (your data)
    private func buildEventsRows() {
//        eventsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        for e in viewModel.getEvents() {
//            let row = EventElement()
//            row.configure(with: e)
//            eventsStack.addArrangedSubview(row)
//        }
//        if let last = eventsStack.arrangedSubviews.last {
//            // Helps the stack’s intrinsic height match the last row.
//            last.bottomAnchor.constraint(equalTo: eventsStack.bottomAnchor).isActive = true
//        }
    }

    // MARK: - Overlay placement (pixel cutoff)

    /// Places the overlay at `freeRevealHeight` points from the top of the card and
    /// resizes the card so the overlay (scrim + lock/message) fully fits below that cutoff.
    private func repositionOverlay() {
        eventsView.layoutIfNeeded()

        let width = eventsView.bounds.width
        guard width > 0 else { return } // need width to measure label wrapping

        overlay.isHidden = false // always show the paywall area

        let cutoffY = freeRevealHeight
        let overlayH = overlay.requiredOverlayHeight(for: width)

        overlayTopConstraint.constant = cutoffY
        eventsHeightConstraint.constant = cutoffY + overlayH

        eventsView.bringSubviewToFront(overlay)
        overlay.setNeedsLayout()
    }

    // MARK: - Sticky CTA spacing & indicator

    /// Makes space for the sticky card at the bottom of the scroll content,
    /// and makes the scroll indicator stop exactly at the sticky card’s top.
    private func updateCardInsets() {
        let cardHeight = stickyCard.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

        // Content spacer (so last content isn’t under the card)
        spacerHeight.constant = cardHeight + spacerExtra

        // Scrollbar track ends at the card’s top
        scrollView.verticalScrollIndicatorInsets.bottom = cardHeight
    }

    // MARK: - CTA action
    @objc private func didTapMembershipButton() {
        initiateMembershipPurchase()
    }
    
    // MARK: - Membership Methods
    
    private func setupMembershipBindings() {
        // Bind membership status changes
        membershipManager.$isMember
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMember in
                // Update UI for is member state if need be
            }
            .store(in: &cancellables)
        
        // Bind loading state
        membershipManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                
                if isLoading {
                    self?.loadingOverlay.show(in: self!.navigationController!.view)
                } else {
                    self?.loadingOverlay.hide()
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        membershipManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorModalManager.showError(errorMessage)
                }
            }
            .store(in: &cancellables)
    }

    private func initiateMembershipPurchase() {
        guard let product = StoreKitManager.shared.monthlyMembershipProduct else {
            self.errorModalManager.showError("Product not available")
            return
        }

        // Your stored user UUID that your backend minted at signup/login.
        // Make sure this actually exists; if not, create on server and refetch profile first.
        let appAccountToken = RealmUserDataStore().load()?.appAccountToken  // UUID?

        Task { @MainActor in
            do {
                guard let outcome = try await StoreKitManager.shared.purchase(product, appAccountToken: appAccountToken) else {
                    return // user cancelled or pending
                }

                guard let jws = outcome.jws else {
                    self.errorModalManager.showError("Missing signed transaction payload (JWS)")
                    return
                }

                // Only send what the server actually needs.
                let payload = AttachPayload(
                    productId: product.id,
                    jws: jws,
                    appAccountToken: appAccountToken?.uuidString
                )

                viewModel.attachSubscription(payload) { [weak self] success in
                    DispatchQueue.main.async {
                        if success {
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            NotificationCenter.default.post(name: .authDidSucceed, object: nil)
                        } else {
                            // TODO: What to do here? If user can't pay, they will be bricked
                            self?.errorModalManager.showError("Failed to activate membership")
                        }
                    }
                }
            } catch {
                self.errorModalManager.showError(error.localizedDescription)
            }
        }
    }

    
    @objc private func restorePurchasesTapped() {
        membershipManager.restorePurchase { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    // TODO: Change error modal manager to be modalManager, and show
                    // non error modals
                    self?.errorModalManager.showError("Purchase restored successfully!")
                } else {
                    self?.errorModalManager.showError("No active purchases found")
                }
            }
        }
    }
}


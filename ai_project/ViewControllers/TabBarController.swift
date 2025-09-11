import UIKit

final class TallTabBar: UITabBar {
    var extraHeight: CGFloat = 8

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        s.height += extraHeight
        return s
    }

    // If you were nudging subviews before, keep it; otherwise remove.
    // Leaving it out to avoid odd spacing with titles.
    // override func layoutSubviews() { ... }
}

final class TabBarController: UITabBarController {

    private var coordinator: UploadVideoCoordinator? = nil
    // Change once, affects all icons (points, not pixels)
    private let iconPointSize: CGFloat = 30
    private let tapHapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light

    private let tallBar = TallTabBar()

    private let plusButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .black
        b.tintColor = .white
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.layer.cornerRadius = 30
        b.layer.masksToBounds = true
        b.accessibilityLabel = "Add"
        b.applyTactileTap()
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use taller tab bar
        tallBar.extraHeight = 8
        setValue(tallBar, forKey: "tabBar")
        tabBar.delegate = self

        configureTabBarAppearance()
        buildTabs()
        setupPlusButton()
    }
    
    // Fires for every tab selection (including reselect)
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        UIImpactFeedbackGenerator(style: tapHapticStyle).impactOccurred()
    }

    // MARK: - Tabs

    private func buildTabs() {
        let lessons = nav(LessonsViewController(), title: "Home",     baseName: "HomeTabIcon")
        let session = nav(SessionViewController(), title: "Progress", baseName: "ProgressTabIcon")
        let profile = nav(ProfileViewController(), title: "Settings", baseName: "SettingsTabIcon")

        // Placeholder tab to shift real tabs left (disabled & invisible)
        let spacer = UIViewController()
        spacer.tabBarItem = UITabBarItem(title: nil, image: UIImage(), selectedImage: UIImage())
        spacer.tabBarItem.isEnabled = false
        spacer.tabBarItem.isAccessibilityElement = false

        viewControllers = [lessons, session, profile, spacer]
        selectedIndex = 1
    }

    // Wrap in a nav and assign a correctly-sized item (same image for both states)
    private func nav(_ root: UIViewController, title: String, baseName: String) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        let img = tabIcon(baseName, pointSize: iconPointSize)
        // Same sized template image for selected & unselected
        n.tabBarItem = UITabBarItem(title: title, image: img, selectedImage: img)
        return n
    }

    /// Resizes your PNG asset to the requested point size and returns a template image.
    private func tabIcon(_ name: String, pointSize: CGFloat) -> UIImage {
        guard let src = UIImage(named: name) else { return UIImage() }
        let templated = src.withRenderingMode(.alwaysTemplate)
        let size = CGSize(width: pointSize, height: pointSize)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { _ in templated.draw(in: CGRect(origin: .zero, size: size)) }
    }

    // MARK: - Appearance

    private func configureTabBarAppearance() {
        // Legacy props (harmless)
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false

        // Modern appearance
        let ap = UITabBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = .systemBackground
        ap.shadowColor = .clear

        // Colors for icons/titles
        ap.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        ap.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        ap.stackedLayoutAppearance.selected.iconColor = .black
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]

        tabBar.standardAppearance = ap
        tabBar.scrollEdgeAppearance = ap

        tabBar.tintColor = .black               // selected icon/title tint
        tabBar.unselectedItemTintColor = .secondaryLabel
    }

    // MARK: - Plus button

    private func setupPlusButton() {
        view.addSubview(plusButton)
        NSLayoutConstraint.activate([
            plusButton.widthAnchor.constraint(equalToConstant: 60),
            plusButton.heightAnchor.constraint(equalToConstant: 60),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            // Keep your original visual: center on the bar's top edge
            plusButton.centerYAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
        tabBar.bringSubviewToFront(plusButton)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
    }

    @objc private func plusTapped() { presentPlusFlow() }

    func presentPlusFlow() {
        
        coordinator = UploadVideoCoordinator(startingAt: self)
        coordinator?.start()
    }
}







final class OneFullRep: UIView {

    // MARK: UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "One full rep"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scannerContainer = UIView()
    private let stepsView: FreeTrialStepsView

    // You already have this view; keep its contentMode/aspect-fit behavior internally
    private let scannerView: LoadingScannerView

    // MARK: Aspect constraints we’ll rebuild when needed
    private var arEqual: NSLayoutConstraint?
    private var arMax: NSLayoutConstraint?

    // Pass the images in so we can read the aspect
    init() {
        let base = UIImage(named: "weightlifting_preview")!
        let overlay = UIImage(named: "weightlifting_overlay")!
        self.scannerView = LoadingScannerView(base: base, overlay: overlay)
        self.scannerView.contentCornerRadius = 14
        self.stepsView   = FreeTrialStepsView(steps: [
            .init(icon: "1.circle", title: nil,
                  subtitle: "Film a single rep from start to finish"),
            .init(icon: "hand.raised", title: nil,
                  subtitle: "Make a full stop at lockout and descent")
        ])
        super.init(frame: .zero)
        setup()

        // Build aspect constraints from the **image’s** ratio (H/W)
        let aspect = base.size.height / base.size.width
        setScannerAspect(aspect)
        scannerView.startScan(duration: 6)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        scannerContainer.translatesAutoresizingMaskIntoConstraints = false
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        stepsView.translatesAutoresizingMaskIntoConstraints = false

        // Layout: scanner (flex) → title → steps (required)
        let stack = UIStackView(arrangedSubviews: [scannerContainer, titleLabel, stepsView])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // Scanner fills its container
        scannerContainer.addSubview(scannerView)
        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: scannerContainer.topAnchor),
            scannerView.leadingAnchor.constraint(equalTo: scannerContainer.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: scannerContainer.trailingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: scannerContainer.bottomAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Priorities so title/steps never clip; scanner shrinks first
        [titleLabel, stepsView].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        scannerContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        scannerContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        // (Optional) minimum scanner height so it never fully disappears
        let minH = scannerContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        minH.priority = .defaultHigh
        minH.isActive = true
    }

    /// Rebuild aspect constraints using the given H/W ratio.
    func setScannerAspect(_ aspect: CGFloat) {
        arEqual?.isActive = false
        arMax?.isActive   = false

        // Prefer exact aspect when there is room…
        arEqual = scannerContainer.heightAnchor.constraint(
            equalTo: scannerContainer.widthAnchor,
            multiplier: aspect
        )
        arEqual?.priority = .defaultHigh   // 750
        arEqual?.isActive = true

        // …but never exceed it if vertical space is tight
        arMax = scannerContainer.heightAnchor.constraint(
            lessThanOrEqualTo: scannerContainer.widthAnchor,
            multiplier: aspect
        )
        arMax?.priority = .required        // 1000
        arMax?.isActive = true

        setNeedsLayout()
        layoutIfNeeded()
    }
}



//Step 1 (Angle, deadlift)
//
//Title: Use a side view
//
//Body bullets:
//
//Side view at hip height, 2–3 m away.
//
//Keep bar and mid-foot visible.
//
//Good lighting; avoid backlight.
//
//Step 2 (Framing)
//
//Title: Keep your whole body in frame
//
//Bullets:
//
//Head to feet visible. Don’t crop plates.
//
//Camera roughly at hip height.
//
//Stable phone or tripod.
//
//Step 3 (One rep)
//
//Title: Record one full rep
//
//Bullets (DL):
//
//Dead-stop preferred. Let plates settle.
//
//Stand tall at lockout.
//
//Max 20s clip; ≤120 fps.
//
//














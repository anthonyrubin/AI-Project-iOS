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
        // Build your step views (swap with real ones)
        let v1 = LoadingScannerView(
            base: UIImage(named: "weightlifting_preview")!,
            overlay: UIImage(named: "weightlifting_overlay")!
        )
        let v2 = LoadingScannerView(
            base: UIImage(named: "weightlifting_preview")!,
            overlay: UIImage(named: "weightlifting_overlay")!
        )
        let v3 = LoadingScannerView(
            base: UIImage(named: "weightlifting_preview")!,
            overlay: UIImage(named: "weightlifting_overlay")!
        )

        let vc = UploadInstructionsViewController(steps: [v1, v2, v3])
        vc.onFinish = { [weak self] in
            // do upload
            // self?.startUpload()
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }
        selectedViewController?.present(vc, animated: true)
    }
}

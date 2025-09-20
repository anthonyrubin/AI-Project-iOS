import UIKit

import UIKit

final class TallTabBar: UITabBar {
    var extraHeight: CGFloat = 8
    
    // Hold a weak reference to the button to avoid retain cycles.
    weak var plusButton: UIButton?

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        s.height += extraHeight
        return s
    }
    
    // Override hitTest to forward taps on the plus button.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If the button exists and the tap is inside its bounds,
        // return the button to handle the tap.
        if let button = plusButton, !button.isHidden {
            // Convert the point from the tab bar's coordinate system
            // to the button's coordinate system.
            let buttonPoint = button.convert(point, from: self)
            if button.bounds.contains(buttonPoint) {
                return button
            }
        }
        
        // Otherwise, let the default behavior continue.
        // This ensures the other tab items are still tappable.
        return super.hitTest(point, with: event)
    }
}

final class TabBarController: UITabBarController, UITabBarControllerDelegate {

    private var coordinator: UploadVideoCoordinator? = nil
    // Change once, affects all icons (points, not pixels)
    private let iconPointSize: CGFloat = 30
    private let tapHapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light

    private let tallBar = TallTabBar()
    
    // MARK: - Upload State Management
    private let uploadStateManager = UploadStateManager()
    
    // MARK: - Plus Button State
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
        // --- RESTORED your original view controllers ---
        let sessionVC = SessionViewController()
        sessionVC.uploadStateManager = uploadStateManager
        let session = nav(sessionVC, title: "Home", baseName: "HomeTabIcon")
        let lessons = nav(LessonsViewController(), title: "History",     baseName: "ProgressTabIcon")
        let profile = nav(SettingsViewController(), title: "Settings", baseName: "SettingsTabIcon")

        // Placeholder tab to shift real tabs left (disabled & invisible)
        let spacer = UIViewController()
        spacer.tabBarItem = UITabBarItem(title: nil, image: UIImage(), selectedImage: UIImage())
        spacer.tabBarItem.isEnabled = false
        spacer.tabBarItem.isAccessibilityElement = false

        viewControllers = [session, lessons, profile, spacer]
        selectedIndex = 0
    }

    // Wrap in a nav and assign a correctly-sized item (same image for both states)
    private func nav(_ root: UIViewController, title: String, baseName: String) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        // --- RESTORED your call to your custom tabIcon function ---
        let img = tabIcon(baseName, pointSize: iconPointSize)
        n.tabBarItem = UITabBarItem(title: title, image: img, selectedImage: img)
        return n
    }

    /// --- RESTORED your original helper function for rendering icons ---
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
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false

        let ap = UITabBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = .systemBackground
        ap.shadowColor = .clear

        ap.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        ap.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        ap.stackedLayoutAppearance.selected.iconColor = .black
        ap.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]

        tabBar.standardAppearance = ap
        tabBar.scrollEdgeAppearance = ap

        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .secondaryLabel
    }

    // MARK: - Plus button (No changes here, the fix is the same)

    private func setupPlusButton() {
        tabBar.addSubview(plusButton)
        
        if let tallBar = self.tabBar as? TallTabBar {
            tallBar.plusButton = plusButton
        }
        
        NSLayoutConstraint.activate([
            plusButton.widthAnchor.constraint(equalToConstant: 60),
            plusButton.heightAnchor.constraint(equalToConstant: 60),
            plusButton.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: -32),
            plusButton.centerYAnchor.constraint(equalTo: tabBar.topAnchor, constant: 12)
        ])
        
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
    }

    @objc private func plusTapped() { presentPlusFlow() }

    func presentPlusFlow() {
        coordinator = UploadVideoCoordinator(startingAt: self, uploadStateManager: uploadStateManager)
        coordinator?.start()
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














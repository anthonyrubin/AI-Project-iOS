import UIKit
import Foundation
import ObjectiveC

extension UIViewController {
    func hideNavBarHairline() {
        guard let nav = navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear

        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
    }
    
    func whiteBackgroundColor() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        view.backgroundColor = .white

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }
    
    func customBackgroundColor() {
        let customColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = customColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.shadowColor = .clear
        
        view.backgroundColor = customColor

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }
    
    func setBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        // Option 1: two-stop, cool white bottom
        // g.colors = [
        //     UIColor(red: 0.85, green: 0.86, blue: 1.00, alpha: 1).cgColor, // #D9DBFF
        //     UIColor(red: 0.965, green: 0.973, blue: 1.0, alpha: 1).cgColor  // ~#F6F8FF
        // ]
        // g.locations = [0.0, 1.0]

        // Option 2: three-stop to avoid muddy mid
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.86, blue: 1.00, alpha: 1).cgColor,   // top #D9DBFF
            UIColor(red: 0.92, green: 0.92, blue: 1.00, alpha: 1).cgColor,   // mid  #EAEAFF
            UIColor(red: 0.973, green: 0.976, blue: 1.00, alpha: 1).cgColor  // bot  #F8F9FF
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0] as [NSNumber]

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        view.layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.frame = view.bounds
    }
    
    
    func makeNavBarTransparent(for vc: UIViewController) {
        guard let nav = vc.navigationController?.navigationBar else { return }

        let clear = UINavigationBarAppearance()
        clear.configureWithTransparentBackground()
        clear.shadowColor = .clear

        nav.standardAppearance = clear
        nav.compactAppearance = clear
        nav.scrollEdgeAppearance = clear
        nav.isTranslucent = true

        vc.edgesForExtendedLayout = [.top]
        vc.extendedLayoutIncludesOpaqueBars = true
    }
}

extension Notification.Name {
    static let videoAnalysisCompleted = Notification.Name("videoAnalysisCompleted")
    static let authDidSucceed = Notification.Name("authDidSucceed")
    static let didLogout = Notification.Name("didLogout")
    static let seekToTimestamp = Notification.Name("seekToTimestamp")
}

extension String {
    func hasAnyWhitespace() -> Bool {
        self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
}


extension Date {
    /// e.g. "August 8th, 2025"
    func longOrdinalString(locale: Locale = .current) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: self)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return "" }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        let month = monthFormatter.monthSymbols[m - 1]   // "January"..."December"

        let ordinal = NumberFormatter.ordinalString(d, locale: locale)
        return "\(month) \(ordinal), \(y)"
    }
}

private extension NumberFormatter {
    static func ordinalString(_ value: Int, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .ordinal
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

final class FadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration: TimeInterval
    init(duration: TimeInterval = 0.25) { self.duration = duration }

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        guard let toVC = ctx.viewController(forKey: .to) else { return }

        let toView = toVC.view!
        toView.alpha = 0
        container.addSubview(toView)

        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
        }, completion: { finished in
            ctx.completeTransition(!ctx.transitionWasCancelled)
        })
    }
}



final class FadeNavDelegate: NSObject, UINavigationControllerDelegate {
    let animator = FadeAnimator()
    var duration: TimeInterval {
        get { animator.duration }
        set { animator.duration = newValue }
    }

    // Content fade
    func navigationController(_ nav: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator
    }

    // Nav bar fade
    func navigationController(_ nav: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        guard animated else { return }
        let t = CATransition()
        t.type = .fade
        t.duration = animator.duration
        t.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        nav.navigationBar.layer.add(t, forKey: "fadeBar")
    }
}


extension UIViewController {
    func pushWithFade(_ vc: UIViewController, duration: TimeInterval = 0.25) {
        guard let nav = navigationController else { return }
        let tempDelegate = FadeNavDelegate()
        tempDelegate.animator.duration = duration
        nav.delegate = tempDelegate
        nav.pushViewController(vc, animated: true)

        // Clear delegate after transition completes so it doesn't stick
        nav.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
            nav.delegate = nil
        }
    }

    func popWithFade(duration: TimeInterval = 0.25) {
        guard let nav = navigationController else { return }
        let tempDelegate = FadeNavDelegate()
        tempDelegate.animator.duration = duration
        nav.delegate = tempDelegate
        nav.popViewController(animated: true)
        nav.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
            nav.delegate = nil
        }
    }
}

extension UIView {
    /**
     Calculates the coordinate at the *bottom* most point of the view relative to its superview
     - returns: `frame.origin.y + frame.height` */
    func bottom() -> CGFloat {
        return frame.origin.y + frame.height
    }
    
    /**
     Calculates the coordinate at the *right* most point of the view relative to its superview
     - returns: `frame.origin.y + frame.height` */
    func right() -> CGFloat {
        return frame.origin.x + frame.width
    }
}

public extension UIColor {
    
    /// Get color from a hex code, e.g. 0xffffff
    convenience init(netHex: UInt32, alpha: CGFloat = 1.0) {
        
        let rbgContstant: CGFloat = 255
        let red = CGFloat((netHex & 0xFF0000) >> 16) / rbgContstant
        let green = CGFloat((netHex & 0xFF00) >> 8) / rbgContstant
        let blue = CGFloat(netHex & 0xFF) / rbgContstant

        self.init(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
}




// MARK: - Models & Positions

public enum BarPosition { case left, right }

public struct OverflowMenuItem {
    public let title: String
    public let systemImage: String?   // SF Symbol name (optional)
    public let isDestructive: Bool
    public let isDisabled: Bool
    public let handler: (() -> Void)?

    public init(title: String,
                systemImage: String? = nil,
                isDestructive: Bool = false,
                isDisabled: Bool = false,
                handler: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.handler = handler
    }
}

// MARK: - Assoc keys

private enum _Assoc {
    static var closeActionKey: UInt8 = 0
    static var floatingCloseButtonKey: UInt8 = 0
    static var overflowButtonKey: UInt8 = 0
    static var overflowItemsKey: UInt8 = 0
}

// MARK: - Extension

public extension UIViewController {

    // ===== Close (X) button in the nav bar =====

    /// Adds a circular X to the nav bar. Default action: dismiss presented nav stack if root, else pop, else dismiss.
    func setupCloseButton(position: BarPosition = .left, action: (() -> Void)? = nil) {
        let item = makeCloseBarItem()
        // store optional custom action
        objc_setAssociatedObject(self, &_Assoc.closeActionKey, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        switch position {
        case .left:
            navigationItem.leftBarButtonItem = item
        case .right:
            // If you ever want X on the right (rare), supported:
            navigationItem.rightBarButtonItems = insertBarItem(item, into: navigationItem.rightBarButtonItems)
        }
    }

    /// For hidden nav bars: adds the same circular X pinned to the safe area.
    @discardableResult
    func addFloatingCloseButton(topInset: CGFloat = 8, leadingInset: CGFloat = 8, action: (() -> Void)? = nil) -> UIButton {
        // remove existing if any
        if let existing = objc_getAssociatedObject(self, &_Assoc.floatingCloseButtonKey) as? UIButton {
            existing.removeFromSuperview()
        }

        let button = makeCircularCloseButton()
        objc_setAssociatedObject(self, &_Assoc.closeActionKey, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, &_Assoc.floatingCloseButtonKey, button, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: leadingInset),
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        button.addTarget(self, action: #selector(_closeTapped), for: .touchUpInside)
        return button
    }

    /// Makes a bar item wrapping the circular X button.
    func makeCloseBarItem() -> UIBarButtonItem {
        let b = makeCircularCloseButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 32),
            b.heightAnchor.constraint(equalToConstant: 32)
        ])
        b.addTarget(self, action: #selector(_closeTapped), for: .touchUpInside)
        return UIBarButtonItem(customView: b)
    }
    
    func makeBackBarItem() -> UIBarButtonItem {
        let b = makeCircularBackButton()
        return UIBarButtonItem(customView: b)
    }

    // ===== Three-dot overflow menu in the nav bar =====

    /// Adds/updates a circular three-dot menu in the nav bar (right by default).
    @discardableResult
    func setupOverflowMenu(items: [OverflowMenuItem], position: BarPosition = .right) -> UIButton {
        let button: UIButton
        if let existing = objc_getAssociatedObject(self, &_Assoc.overflowButtonKey) as? UIButton {
            button = existing
        } else {
            button = makeCircularOverflowButton()
            objc_setAssociatedObject(self, &_Assoc.overflowButtonKey, button, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        objc_setAssociatedObject(self, &_Assoc.overflowItemsKey, items, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        rebuildMenu(on: button, with: items)

        let barItem = UIBarButtonItem(customView: button)
        switch position {
        case .right:
            navigationItem.rightBarButtonItems = insertBarItem(barItem, into: navigationItem.rightBarButtonItems)
        case .left:
            navigationItem.leftBarButtonItems = insertBarItem(barItem, into: navigationItem.leftBarButtonItems)
        }
        return button
    }

    /// Replace the current overflow menu items (keeps same button and placement).
    func updateOverflowMenu(items: [OverflowMenuItem]) {
        guard let button = objc_getAssociatedObject(self, &_Assoc.overflowButtonKey) as? UIButton else { return }
        objc_setAssociatedObject(self, &_Assoc.overflowItemsKey, items, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        rebuildMenu(on: button, with: items)
    }

    // ===== Internal actions =====

    @objc private func _closeTapped() {
        if let custom = objc_getAssociatedObject(self, &_Assoc.closeActionKey) as? (() -> Void) {
            custom()
            return
        }
        if let nav = navigationController, nav.presentingViewController != nil, nav.viewControllers.first === self {
            nav.dismiss(animated: true) // presented nav; dismiss whole stack
            return
        }
        if let nav = navigationController {
            nav.popViewController(animated: true) // pushed
            return
        }
        dismiss(animated: true) // fallback
    }
    
    @objc private func _backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // ===== UI builders =====

    private func makeCircularCloseButton() -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = .secondarySystemBackground
        b.tintColor = .secondaryLabel
        b.layer.cornerRadius = 16
        b.layer.masksToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let img = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(cfg)
        b.setImage(img, for: .normal)
        return b
    }
    
    private func makeCircularBackButton() -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .label
        b.backgroundColor = UIColor.systemGray5
        b.layer.cornerRadius = 16
        b.addTarget(self, action: #selector(_backTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 32),
            b.heightAnchor.constraint(equalToConstant: 32)
        ])
        return b
    }

    private func makeCircularOverflowButton() -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = .secondarySystemBackground
        b.tintColor = .secondaryLabel
        b.layer.cornerRadius = 16
        b.layer.masksToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        // Horizontal ellipsis (three dots)
        let img = UIImage(systemName: "ellipsis")?.applyingSymbolConfiguration(cfg)
        b.setImage(img, for: .normal)
        return b
    }

    private func rebuildMenu(on button: UIButton, with items: [OverflowMenuItem]) {
        // iOS 16+: build a UIMenu with UIActions
        let actions: [UIAction] = items.map { item in
            var attrs: UIMenuElement.Attributes = []
            if item.isDestructive { attrs.insert(.destructive) }
            if item.isDisabled { attrs.insert(.disabled) }
            let image = item.systemImage.flatMap { UIImage(systemName: $0) }
            return UIAction(title: item.title,
                            image: image,
                            identifier: nil,
                            discoverabilityTitle: nil,
                            attributes: attrs,
                            state: .off) { _ in
                item.handler?()
            }
        }
        button.menu = UIMenu(title: "", children: actions)
        button.showsMenuAsPrimaryAction = true
    }

    // Insert/replace our customView button in an existing bar button array.
    private func insertBarItem(_ item: UIBarButtonItem, into array: [UIBarButtonItem]?) -> [UIBarButtonItem] {
        var arr = array ?? []
        // Replace if the same customView already exists; else append.
        if let idx = arr.firstIndex(where: { $0.customView === item.customView }) {
            arr[idx] = item
        } else {
            arr.append(item)
        }
        return arr
    }
}

private enum _LangNavAssoc {
    static var buttonKey: UInt8 = 0
    static var codeKey:   UInt8 = 1
    static var onPickedKey: UInt8 = 2
}

public extension UINavigationController {

    /// Install a single pill that persists across pushes in the signup flow.
    /// Call this ONCE (e.g., when you create/present the flow).
    func installLanguagePillForSignupFlow(code: String,
                                          trailingInset: CGFloat = 15,
                                          onPicked: ((String) -> Void)? = nil) {
        let upper = code.uppercased()
        let pill: UIButton

        if let existing = objc_getAssociatedObject(self, &_LangNavAssoc.buttonKey) as? UIButton {
            pill = existing
        } else {
            pill = UIButton(type: .system)
            pill.translatesAutoresizingMaskIntoConstraints = false
            pill.heightAnchor.constraint(equalToConstant: 28).isActive = true
            pill.widthAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            pill.layer.cornerRadius = 14
            pill.layer.masksToBounds = true
            pill.setContentHuggingPriority(.required, for: .horizontal)
            pill.setContentCompressionResistancePriority(.required, for: .horizontal)
            pill.addTarget(self, action: #selector(_langNav_pillTapped), for: .touchUpInside)

            navigationBar.addSubview(pill)
            NSLayoutConstraint.activate([
                pill.trailingAnchor.constraint(equalTo: navigationBar.layoutMarginsGuide.trailingAnchor,
                                               constant: -trailingInset),
                pill.centerYAnchor.constraint(equalTo: navigationBar.layoutMarginsGuide.centerYAnchor)
            ])

            objc_setAssociatedObject(self, &_LangNavAssoc.buttonKey, pill, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        objc_setAssociatedObject(self, &_LangNavAssoc.codeKey, upper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &_LangNavAssoc.onPickedKey, onPicked, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        _langNav_applyTitle(pill, code: upper)
    }

    /// Update the persistent pill’s code+flag.
    func updateSignupFlowLanguagePill(code: String) {
        guard let pill = objc_getAssociatedObject(self, &_LangNavAssoc.buttonKey) as? UIButton else { return }
        let upper = code.uppercased()
        objc_setAssociatedObject(self, &_LangNavAssoc.codeKey, upper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        _langNav_applyTitle(pill, code: upper)
    }

    /// Access the pill if you need its view (for constraints/lookups).
    var signupFlowLanguagePillButton: UIButton? {
        objc_getAssociatedObject(self, &_LangNavAssoc.buttonKey) as? UIButton
    }

    @objc private func _langNav_pillTapped() {
        let upper = (objc_getAssociatedObject(self, &_LangNavAssoc.codeKey) as? String) ?? "EN"
        let selectedLower = upper.lowercased()

        // Present your existing picker from the top VC.
        let picker = LanguagePickerViewController(selectedCode: selectedLower) { [weak self] picked in
            guard let self = self else { return }
            let newCode = picked.code.uppercased()
            self.updateSignupFlowLanguagePill(code: newCode)
            if let cb = objc_getAssociatedObject(self, &_LangNavAssoc.onPickedKey) as? ((String)->Void) {
                cb(newCode)
            }
        }
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        (topViewController ?? self).present(picker, animated: true)
    }

    private func _langNav_applyTitle(_ button: UIButton, code: String) {
        let flag: String
        switch code {
        case "EN": flag = "🇺🇸"; case "ZH": flag = "🇨🇳"; case "HI": flag = "🇮🇳"
        case "ES": flag = "🇪🇸"; case "FR": flag = "🇫🇷"; case "DE": flag = "🇩🇪"
        case "RU": flag = "🇷🇺"; case "PT": flag = "🇵🇹"; case "IT": flag = "🇮🇹"
        case "RO": flag = "🇷🇴"; case "AZ": flag = "🇦🇿"; case "NL": flag = "🇳🇱"
        default:   flag = "🏳️"
        }

        var cfg = UIButton.Configuration.plain()
        cfg.contentInsets = .init(top: 4, leading: 10, bottom: 4, trailing: 10)
        cfg.attributedTitle = AttributedString(
            "\(flag) \(code)",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
        )
        cfg.background.backgroundColor = .secondarySystemBackground
        cfg.background.cornerRadius = 14
        button.configuration = cfg
    }
}


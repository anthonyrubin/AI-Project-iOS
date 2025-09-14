import UIKit
import Foundation
import ObjectiveC

public enum CloseButtonPosition { case left, right }

private final class _ClosureBox {
    let handler: (() -> Void)?
    init(_ handler: (() -> Void)?) { self.handler = handler }
}

private struct _AssocKeys {
    static var closeAction = "vc_close_action_key"
    static var floatingButton = "vc_close_floating_button_key"
}

public extension UIViewController {

    /// Adds a circular "X" button to the nav bar.
    /// - Parameters:
    ///   - position: .left (default) or .right
    ///   - action: optional custom action; if nil, uses smart dismiss/pop.
    func setupCloseButton(position: CloseButtonPosition = .left,
                          action: (() -> Void)? = nil) {
        let item = makeCloseBarItem()
        let box = _ClosureBox(action)
        objc_setAssociatedObject(self, &_AssocKeys.closeAction, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        switch position {
        case .left:  navigationItem.leftBarButtonItem  = item
        case .right: navigationItem.rightBarButtonItem = item
        }
    }

    /// For screens with hidden nav bars, adds the same circular "X" as a floating button pinned to the safe area.
    /// Returns the button so you can further customize if needed.
    @discardableResult
    func addFloatingCloseButton(topInset: CGFloat = 8,
                                leadingInset: CGFloat = 8,
                                action: (() -> Void)? = nil) -> UIButton {
        // Remove existing (if any)
        if let existing = objc_getAssociatedObject(self, &_AssocKeys.floatingButton) as? UIButton {
            existing.removeFromSuperview()
        }

        let button = makeCloseButton()
        button.addTarget(self, action: #selector(_closeTapped), for: .touchUpInside)

        let box = _ClosureBox(action)
        objc_setAssociatedObject(self, &_AssocKeys.closeAction, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &_AssocKeys.floatingButton, button, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: leadingInset),
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])

        return button
    }

    /// Creates the UIBarButtonItem wrapping the circular "X" button.
    func makeCloseBarItem() -> UIBarButtonItem {
        let button = makeCloseButton()
        button.addTarget(self, action: #selector(_closeTapped), for: .touchUpInside)

        // Size constraints so the bar button sizes correctly
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])

        return UIBarButtonItem(customView: button)
    }

    // MARK: - Internal helpers

    @objc private func _closeTapped() {
        // Use custom override if provided
        if let box = objc_getAssociatedObject(self, &_AssocKeys.closeAction) as? _ClosureBox,
           let handler = box.handler {
            handler()
            return
        }
        // Default: dismiss presented nav stack if we’re its root
        if let nav = navigationController, nav.presentingViewController != nil, nav.viewControllers.first === self {
            nav.dismiss(animated: true)
            return
        }
        // If we’re in a nav stack, pop
        if let nav = navigationController {
            nav.popViewController(animated: true)
            return
        }
        // Fallback
        dismiss(animated: true)
    }

    private func makeCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.tintColor = .secondaryLabel
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let image = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(symbolConfig)
        button.setImage(image, for: .normal)

        // If you have a haptic/tactile extension, call it here.
        button.applyTactileTap()

        return button
    }
}


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

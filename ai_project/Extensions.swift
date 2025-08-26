import UIKit
import Foundation

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
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.86, blue: 1.00, alpha: 1).cgColor, // top tint
            UIColor.white.cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.locations = [0.0, 0.55, 1.0] as [NSNumber]   // fade by ~55% of height
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)

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

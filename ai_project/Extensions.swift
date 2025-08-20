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

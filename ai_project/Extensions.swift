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
}

extension Notification.Name {
    static let videoAnalysisCompleted = Notification.Name("videoAnalysisCompleted")
    static let authDidSucceed = Notification.Name("authDidSucceed")
    static let didLogout = Notification.Name("didLogout")
}

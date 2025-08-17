import UIKit
import Alamofire

class ErrorModalManager {
    
    weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: self.getErrorMessage(for: error),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Present from the topmost view controller
            if let topViewController = self.getTopViewController() {
                topViewController.present(alert, animated: true)
            } else {
                self.viewController?.present(alert, animated: true)
            }
        }
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Present from the topmost view controller
            if let topViewController = self.getTopViewController() {
                topViewController.present(alert, animated: true)
            } else {
                self.viewController?.present(alert, animated: true)
            }
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.localizedDescription
        }
        
        // Handle specific error types
        if let afError = error as? AFError {
            switch afError {
            case .responseValidationFailed(let reason):
                switch reason {
                case .unacceptableStatusCode(let code):
                    return "Server error (HTTP \(code)). Please try again."
                default:
                    return "Network validation failed. Please check your connection."
                }
            case .responseSerializationFailed:
                return "Failed to process server response. Please try again."
            default:
                return "Network error occurred. Please try again."
            }
        }
        
        // Default error message
        return error.localizedDescription.isEmpty ? "An unexpected error occurred. Please try again." : error.localizedDescription
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        if let navigationController = topViewController as? UINavigationController {
            topViewController = navigationController.visibleViewController
        }
        
        if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController
        }
        
        return topViewController
    }
}

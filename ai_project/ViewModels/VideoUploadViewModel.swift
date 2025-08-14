import Foundation
import UIKit

class VideoUploadViewModel {
    
    var onUploadSuccess: ((_ videoId: String, _ analysisId: String) -> Void)?
    var onUploadFailure: ((Error) -> Void)?
    var onDataRefreshNeeded: (() -> Void)?
    
    private var loadingOverlay: LoadingOverlay?
    
    func uploadVideo(fileURL: URL, on viewController: UIViewController) {
        // Show loading overlay
        loadingOverlay = LoadingOverlay()
        loadingOverlay?.show(on: viewController, message: "Analyzing")
        
        NetworkManager.shared.uploadVideo(fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingOverlay?.hide()
                
                switch result {
                case .success(let response):
                    self?.onUploadSuccess?(response.videoId, response.analysisId)
                    // Trigger data refresh in LessonsViewController
                    self?.onDataRefreshNeeded?()
                case .failure(let error):
                    ErrorModalManager.shared.showError(error, from: viewController)
                    self?.onUploadFailure?(error)
                }
            }
        }
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

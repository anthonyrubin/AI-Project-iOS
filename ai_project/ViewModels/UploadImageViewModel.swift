import UIKit

class UploadImageViewModel {

    var onUploadSuccess: (() -> Void)?
    var onUploadFailure: ((Error) -> Void)?

    func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        NetworkManager.shared.uploadImage(data: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.onUploadSuccess?()
                case .failure(let error):
                    self.onUploadFailure?(error)
                }
            }
        }
    }
}

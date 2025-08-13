import Foundation

class VerifyAccountViewModel {
    var onSuccess: (() -> Void)?
    var onFailure: ((String) -> Void)?

    func verifyAccount(email: String, code: String) {
        NetworkManager.shared.verifyAccount(
            email: email,
            code: code
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.onSuccess?()
                case .failure(let error):
                    self?.onFailure?(error.localizedDescription)
                }
            }
        }
    }
}

import Foundation

class LoginViewModel {
    var onLoginSuccess: ((LoginOrCheckpointResponse) -> Void)?
    var onLoginFailure: ((String) -> Void)?

    func login(username: String, password: String) {
        NetworkManager.shared.loginOrCheckpoint(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.onLoginSuccess?(user)
                case .failure(let error):
                    self?.onLoginFailure?(error.localizedDescription)
                }
            }
        }
    }
}

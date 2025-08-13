import Foundation

class CreateAccountViewModel {
    var onCreateAccountSuccess: (() -> Void)?
    var onCreateAccountFailure: ((String) -> Void)?

    func CreateAccount(username: String, email: String, password1: String, password2: String) {
        NetworkManager.shared.createAccount(
            username: username,
            email: email,
            password1: password1,
            password2: password2
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.onCreateAccountSuccess?()
                case .failure(let error):
                    self?.onCreateAccountFailure?(error.localizedDescription)
                }
            }
        }
    }
}

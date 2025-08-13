import Foundation

class SetNameViewModel {
    var onSuccess: (() -> Void)?
    var onFailure: ((String) -> Void)?

    func setName(firstName: String, lastName: String) {
        NetworkManager.shared.setName(
            firstName: firstName,
            lastName: lastName
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // TODO: Do something with the response or get rid of this somehow
                    self?.onSuccess?()
                case .failure(let error):
                    self?.onFailure?(error.localizedDescription)
                }
            }
        }
    }
}

import Foundation

class SetBirthdayViewModel {
    var onSuccess: (() -> Void)?
    var onFailure: ((String) -> Void)?

    func setBirthday(birthday: Date) {
        NetworkManager.shared.setBirthday(
            birthday: birthday
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

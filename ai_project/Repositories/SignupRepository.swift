import Foundation

protocol SignupRepository {
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )
}

class SignupRepositoryImpl: SignupRepository {

    private var signupAPI: SignupAPI
    private var userDataStore: UserDataStore
    
    init (signupAPI: SignupAPI, userDataStore: UserDataStore) {
        self.signupAPI = signupAPI
        self.userDataStore = userDataStore
    }
    
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {

        signupAPI.createAccount(
            username: username,
            email: email,
            password1: password1,
            password2: password2,
            completion: { result in                     // no decoding
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        )
    }
}

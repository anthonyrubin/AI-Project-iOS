import Foundation

protocol SignupRepository {
    func createAccount(
        username: String,
        email: String,
        password1: String,
        password2: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )
    
    func setName(
        firstName: String,
        lastName: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )

    func setBirthday(birthday: Date, completion: @escaping (Result<Void, NetworkError>) -> Void)
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
    
    func setName(
        firstName: String,
        lastName: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void) {
        
            signupAPI.setName(
                firstName: firstName,
                lastName: lastName,
                completion: { [weak self] result in
                    
                    switch result {
                    case .success:
                        completion(.success(()))
                        if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                            do {
                                try self?.userDataStore.setName(userId: currentUserId, first: firstName, last: lastName)
                            } catch {
                                // TODO: Log here, caching should not fail, but this should fail silently if it does
                            }
                        } else {
                            // TODO: Log here, we should always have a useID at this point
                        }
                        
                    case .failure(let err):
                        completion(.failure(err))
                    }
            }
        )
    }
    
    func setBirthday(
        birthday: Date,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        signupAPI.setBirthday(
            birthday: birthday,
            completion: { [weak self] result in
                switch result {
                case .success:
                    completion(.success(()))
                    if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                        do {
                            try self?.userDataStore.setBirthday(userId: currentUserId, date: birthday)
                        } catch {
                            // TODO: Log here, caching should not fail, but this should fail silently if it does
                        }
                    } else {
                        // TODO: Log here, we should always have a useID at this point
                    }
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        )
    }
}

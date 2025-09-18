import Foundation

protocol SettingsRepository {
    func setBirthday(birthday: Date, completion: @escaping (Result<Void, NetworkError>) -> Void)
    func setExperience(experience: String, completion: @escaping (Result<Void, NetworkError>) -> Void)
    func setWorkoutDaysPerWeek(workoutDaysPerWeek: String, completion: @escaping (Result<Void, NetworkError>) -> Void)
    func setGender(gender: String, completion: @escaping (Result<Void, NetworkError>) -> Void)
    func setBodyMetrics(gender: String, completion: @escaping (Result<Void, NetworkError>) -> Void)
}

class SettingsRepositoryImpl: SettingsRepository {
    
    private var settingsAPI: SettingsAPI
    private var userDataStore: UserDataStore
    
    init (settingsAPI: SettingsAPI, userDataStore: UserDataStore) {
        self.settingsAPI = settingsAPI
        self.userDataStore = userDataStore
    }
    
    func setBirthday(
        birthday: Date,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        settingsAPI.setBirthday(
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
    
    func setExperience(experience: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        settingsAPI.setExperience(
            experience: experience,
            completion: { [weak self] result in
                switch result {
                case .success:
                    if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                        do {
                            try self?.userDataStore.setExperience(userId: currentUserId, experience: experience)
                            completion(.success(()))
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
    
    func setWorkoutDaysPerWeek(workoutDaysPerWeek: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        settingsAPI.setWorkoutDaysPerWeek(
            workoutDaysPerWeek: workoutDaysPerWeek,
            completion: { [weak self] result in
                switch result {
                case .success:
                    if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                        do {
                            try self?.userDataStore.setWorkoutDaysPerWeek(
                                userId: currentUserId,
                                workoutDaysPerWeek: workoutDaysPerWeek)
                            completion(.success(()))
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
    
    func setGender(gender: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        settingsAPI.setGender(
            gender: gender,
            completion: { [weak self] result in
                switch result {
                case .success:
                    if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                        do {
                            try self?.userDataStore.setGender(
                                userId: currentUserId,
                                gender: gender)
                            completion(.success(()))
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
    
    func setBodyMetrics(
        height: Double,
        weight: Double,
        isMetric: Bool,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        settingsAPI.setBodyMetrics(
            height: height,
            weight: weight,
            isMetric: isMetric,
            completion: { [weak self] result in
                switch result {
                case .success:
                    if let currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? Int {
                        do {
                            try self?.userDataStore.setBodyMetrics(
                                userId: currentUserId,
                                height: height,
                                weight: weight,
                                isMetric: isMetric
                            )
                            completion(.success(()))
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

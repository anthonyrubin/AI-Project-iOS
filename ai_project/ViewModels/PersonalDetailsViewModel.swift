import Foundation

struct PersonalDetailsData {
    let birthday: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    let isMetric: Bool?
    let workoutDaysPerWeek: String?
    let experience: String?
}

class PersonalDetailsViewModel {

    private let userDataStore: RealmUserDataStore
    var personalDetailsData: PersonalDetailsData? = nil
    
    init(userDataStore: RealmUserDataStore) {
        self.userDataStore = userDataStore
        self.personalDetailsData = loadUserData()
    }
    
    func refresh() {
        personalDetailsData = loadUserData() 
    }
    
    func loadUserData() -> PersonalDetailsData {
        let user = userDataStore.load()
        
        return PersonalDetailsData(
            birthday: user?.birthday,
            gender: user?.gender,
            height: user?.height,
            weight: user?.weight,
            isMetric: user?.isMetric,
            workoutDaysPerWeek: user?.workoutDaysPerWeek,
            experience: user?.experience
        )
    }
    
    func getBirthday() -> String {
        guard let personalDetailsData = personalDetailsData,
              let birthday = personalDetailsData.birthday else { return "Not set" }
        
        return formatDateMMDDYYYY(birthday)
    }
    
    func getGender() -> String {
        guard let personalDetailsData = personalDetailsData,
              let gender = personalDetailsData.gender else { return "Not set" }
        
        return gender
    }
    
    func getWorkoutDaysPerWeek() -> String {
        guard let personalDetailsData = personalDetailsData,
              let workoutDaysPerWeek = personalDetailsData.workoutDaysPerWeek else { return "Not set" }
        
        return workoutDaysPerWeek
    }
    
    func getExperience() -> String {
        guard let personalDetailsData = personalDetailsData,
              let experience = personalDetailsData.experience else { return "Not set" }
        
        return experience
    }
    
    // Function 1: Convert height from UserDTO to display string
    func getFormattedHeight() -> String {
        
        guard let personalDetailsData = personalDetailsData,
              let height = personalDetailsData.height,
              let isMetric = personalDetailsData.isMetric else { return "Not set" }
        
        if isMetric {
            // Display in cm
            return "\(Int(height)) cm"
        } else {
            // Convert cm to feet and inches
            let totalInches = height / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet) ft \(inches) in"
        }
    }

    // Function 2: Convert weight from UserDTO to display string
    func getFormattedWeight() -> String {
        
        guard let personalDetailsData = personalDetailsData,
              let weight = personalDetailsData.weight,
              let isMetric = personalDetailsData.isMetric else { return "Not set" }

        if isMetric {
            // Display in kg
            return "\(Int(weight)) kg"
        } else {
            // Convert kg to lbs
            let pounds = weight * 2.20462
            return "\(Int(pounds)) lbs"
        }
    }
    
    func getRawHeight() -> Double {
        guard let personalDetailsData = personalDetailsData,
              let height = personalDetailsData.height,
              let isMetric = personalDetailsData.isMetric else { return 177 }
        return height
    }
    
    func getRawWeight() -> Double {
        guard let personalDetailsData = personalDetailsData,
              let weight = personalDetailsData.weight else { return 79 }
        return weight
    }
    
    func getIsMetric() -> Bool {
        guard let personalDetailsData = personalDetailsData,
              let isMetric = personalDetailsData.isMetric else { return false }
        return isMetric
    }
}

import UIKit
import Foundation

struct SignupFlowData {
    var experience: String?
    var workoutDaysPerWeek: String?
    var gender: String?
    var heightCm: Double?
    var weightKg: Double?
    var isMetric: Bool?
    var birthdate: Date?
}

final class SignupCoordinator: NSObject {
    
    private(set) var nav: UINavigationController!
    private weak var presentingVC: UIViewController?
    private var signupFlowData = SignupFlowData()
    
    init(startingAt presentingVC: UIViewController, nav: UINavigationController) {
        self.presentingVC = presentingVC
        self.nav = nav
        super.init()

        nav.navigationBar.tintColor = .secondaryLabel
    }
    
    func start(completion: (() -> Void)? = nil) {
        let vc = LiftingExperienceViewController()
        // wire step callbacks the coordinator expects
        vc.onSelectedExperience = {
            [weak self] experience in self?.signupFlowData.experience = experience
            // TODO: We don't need to even store in userDefaults in coordinator is handling it
            UserDefaultsManager.shared.updateGoals(experience: experience)
        }
        // let VC advance the flow via its bottom Continue
        vc.onContinue = { [weak self] in self?.nextTapped() }
        presentingVC?.pushWithFade(vc) {
            completion?()
        }
    }
    
    @objc private func nextTapped() {
        guard let top = nav.topViewController else { return }
        
        if let _ = top as? LiftingExperienceViewController {
            let vc = WorkoutDaysPerWeekViewController()
            vc.onContinue = { [weak self] in self?.nextTapped() }
            vc.onSelectedWorkoutDaysPerWeek = {
                [weak self] workoutDaysPerWeek in self?.signupFlowData.workoutDaysPerWeek = workoutDaysPerWeek
                UserDefaultsManager.shared.updateGoals(workoutDaysPerWeek: workoutDaysPerWeek)
            }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? WorkoutDaysPerWeekViewController {
            let vc = GreatPotentialViewController()
            vc.onContinue = { [weak self] in self?.nextTapped() }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? GreatPotentialViewController {
            let vc = ChooseGenderViewController()
            vc.onContinue = { [weak self] in self?.nextTapped() }
            vc.onSelectedGender = {
                [weak self] gender in self?.signupFlowData.gender = gender
                UserDefaultsManager.shared.updateBasicInfo(gender: gender)
            }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? ChooseGenderViewController {
            let vc = HeightAndWeightViewController()
            vc.onContinue = {
                [weak self] heightCm, weightKg, isMetric in
                UserDefaultsManager.shared.updatePhysicalInfo(
                    height: heightCm,
                    weight: weightKg,
                    isMetric: isMetric
                )
                self?.signupFlowData.heightCm = heightCm
                self?.signupFlowData.weightKg = weightKg
                self?.signupFlowData.isMetric = isMetric
                self?.nextTapped()
            }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? HeightAndWeightViewController {
            let vc = BirthdayViewController()
            vc.onContinue = { [weak self] birthdate in
                UserDefaultsManager.shared.updateBasicInfo(birthday: birthdate)
                self?.signupFlowData.birthdate = birthdate
                self?.nextTapped()
            }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? BirthdayViewController {
            let vc = ThanksForTrustingUsViewController()
            vc.onContinue = { [weak self] in self?.nextTapped() }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? ThanksForTrustingUsViewController {
            let vc = AllowNotificationsViewController()
            vc.onContinue =  { [weak self] in self?.nextTapped() }
            nav?.pushViewController(vc, animated: true)
        } else if let _ = top as? AllowNotificationsViewController {
            let vc = StartAnalysisViewController()
            //TODO: Continue implementing sign up flow coordinator
            nav?.pushViewController(vc, animated: true)
        }
    }
}

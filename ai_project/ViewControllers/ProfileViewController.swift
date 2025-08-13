import Foundation
import UIKit

class ProfileViewController: UIViewController {
    let topLabel: UILabel = {
        let label = UILabel()
        label.text = "Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let logoutButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = "Logout"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false                        // start disabled
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        setupUI()
        
//        viewModel.onFailure = ({ [weak self] response in
//            print("Set Name Failure")
//            self?.setLoading(false)
//        })
//        
//        viewModel.onSuccess = ({ [weak self] in
//            print("Set Name Success")
//            self?.setLoading(false)
//            let vc = SetBirthdayViewController()
//            self?.navigationController?.pushViewController(vc, animated: true)
//            print("Pushed view controller")
//        })
//
//        updateNextEnabled()
    }

//    private let viewModel = SetNameViewModel()
    private var isLoading = false

    func setupUI() {
        view.addSubview(topLabel)
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topLabel.heightAnchor.constraint(equalToConstant: 44),

            logoutButton.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 30),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            logoutButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])

        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    }


    @objc func logoutButtonTapped() {
        performLogout()
    }
    
    func performLogout() {
        NetworkManager.shared.logout {
            // wipe local state
            TokenManager.shared.clearTokens()
            // TODO: Come back to this and clear UserDefaults on logout
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")

            // optional: clear Realm cache if you want a clean slate
            // TODO: Come back to this and clear realm on logout
            if let realm = try? RealmProvider.make() {
                try? realm.write { realm.deleteAll() }
            }

            // tell SceneDelegate to mount login
            NotificationCenter.default.post(name: .didLogout, object: nil)
        }
    }

    // loading also locks the button
//    func setLoading(_ loading: Bool) {
//        isLoading = loading
//        var c = nextButton.configuration ?? .filled()
//        c.showsActivityIndicator = loading
//        c.title = loading ? nil : "Next"
//        nextButton.configuration = c
//        updateNextEnabled()
//    }
}

import UIKit

final class GreatPotentialViewController: BaseSignupViewController {

    init(sportDisplay: String) {
        titleLabel.text = "CoachAI makes you a better \(sportDisplay)."
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.27, animated: false)
    }
    
    override func layout() {
        view.addSubview(titleLabel)
        super.layout()
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        let vc = ChooseGenderViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}


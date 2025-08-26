import UIKit

final class GreatPotentialViewController: BaseSignupViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "You have great potential to crush your goals"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.55, animated: false)
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


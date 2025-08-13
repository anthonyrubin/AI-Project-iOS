import Foundation
import UIKit

class LessonsViewController: UIViewController {
    private let label = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavBarHairline()
        view.backgroundColor = .systemBackground
        label.text = "Lessons"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

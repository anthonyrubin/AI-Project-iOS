import UIKit

final class SetBirthdayViewController: UIViewController {
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "What's Your Birthday?"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.maximumDate = Date()              // no future dates
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    private let nextButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Next"
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    let viewModel = SetBirthdayViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(datePicker)
        view.addSubview(nextButton)
        
        viewModel.onFailure = ({ [weak self] response in
            print("Set Birthday Failure")
            self?.setLoading(false)
        })
        
        viewModel.onSuccess = ({ [weak self] in
            print("Set Birthday Success")
            self?.setLoading(false)
//            let vc = SetBirthdayViewController()
//            self?.navigationController?.pushViewController(vc, animated: true)
            print("Pushed view controller")
        })

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nextButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 30),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }

    @objc private func nextButtonTapped() {
        setLoading(true)
        viewModel.setBirthday(birthday: datePicker.date)
    }

    private func setLoading(_ loading: Bool) {
        var c = nextButton.configuration ?? .filled()
        c.showsActivityIndicator = loading
        c.title = loading ? nil : "Save"
        nextButton.configuration = c
        nextButton.isEnabled = !loading
        datePicker.isEnabled = !loading
    }
}

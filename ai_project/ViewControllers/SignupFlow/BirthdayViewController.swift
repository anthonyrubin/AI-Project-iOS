import UIKit

final class BirthdayViewController: BaseSignupViewController {
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    // MARK: - State
    private(set) var birthdate: Date = {
        // default to 18 years ago so the wheel lands somewhere sensible
        let cal = Calendar.current
        return cal.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }()

    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "When were you born?"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Coach Cam sets age-based targets and comparisons."
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateContainer = UIView()
    private let datePicker = UIDatePicker()

    // install constraints once
    private var didInstallConstraints = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        buildUI()                 // add subviews BEFORE calling super (base calls layout())
        super.viewDidLoad()

        setProgress(0.55, animated: false)

        wire()
        updateFromState()
    }

    // MARK: - Build
    private func buildUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        dateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateContainer)

        // Date picker (wheels)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.maximumDate = Date()                           // no future birthdays
        datePicker.minimumDate = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))

        dateContainer.addSubview(datePicker)
    }

    override func layout() {
        super.layout()
        guard !didInstallConstraints else { return }
        didInstallConstraints = true

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Title / subtitle
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Card
            dateContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            dateContainer.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 24),
            dateContainer.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -24),

            // Date picker inside card
            datePicker.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 12),
            datePicker.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor, constant: 12),
            datePicker.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor, constant: -12),
            datePicker.bottomAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: -12),
            datePicker.heightAnchor.constraint(equalToConstant: 216) // typical wheel height
        ])
    }

    private func wire() {
        datePicker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)
    }

    private func updateFromState() {
        datePicker.date = birthdate
        // If you want to gate continue by age (e.g., >= 13), add logic here.
        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }

    @objc private func didChangeDate() {
        birthdate = datePicker.date
    }
    
    private func isAtLeast(_ years: Int, from date: Date) -> Bool {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0 >= years
    }

    // MARK: - Continue
    override func didTapContinue() {
        
        if !isAtLeast(13, from: birthdate) {
            errorModalManager.showError("You must be at least 13 years old")
            return
        }
        
        UserDefaultsManager.shared.updateBasicInfo(birthday: birthdate)
        
        super.didTapContinue()
        
        let vc = ThanksForTrustingUsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

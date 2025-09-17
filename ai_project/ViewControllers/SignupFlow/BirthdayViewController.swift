import UIKit

final class BirthdayViewController: BaseSignupViewController {
    
    var onContinue: ((_ birthday: Date) -> Void)?
    
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    // SETTINGS MODE: incoming preselected date as "MM/DD/YYYY"
    var preSelectedItem: String? = nil
    private var originalDate: Date?   // parsed from preSelectedItem for comparison

    // MARK: - State
    private(set) var birthdate: Date = {
        // default to 18 years ago at LOCAL NOON so the wheel lands somewhere sensible
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let base = cal.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: base) ?? base
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

        // Apply preselected value if provided (settings mode)
        if let pre = preSelectedItem,
           let parsed = Self.parseDate(from: pre) {
            originalDate = parsed
            birthdate = parsed
            datePicker.date = parsed
            continueButton.setTitle("Save", for: .normal)
        }

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
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.timeZone = .current                 // iOS 16+: force local timezone
        datePicker.maximumDate = Date()                // no future birthdays
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
        updateContinueState()
    }

    // Enable Continue only when needed (settings mode),
    // otherwise preserve original signup behavior.
    private func updateContinueState() {
        if let originalDate {
            // settings mode: enable only if changed
            let changed = !Calendar.current.isDate(birthdate, inSameDayAs: originalDate)
            continueButton.isEnabled = changed
            continueButton.alpha = changed ? 1.0 : 0.4
        } else {
            // signup flow: original behavior (button enabled)
            continueButton.isEnabled = true
            continueButton.alpha = 1.0
        }
    }

    @objc private func didChangeDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        // Normalize to local noon to avoid off-by-one due to DST/UTC
        birthdate = cal.date(bySettingHour: 12, minute: 0, second: 0, of: datePicker.date) ?? datePicker.date
        updateContinueState()
    }
    
    private func isAtLeast(_ years: Int, from date: Date) -> Bool {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0 >= years
    }

    // MARK: - Continue
    override func didTapContinue() {
        // Settings flow branch: only when preselected existed and user changed it
        if let originalDate,
           !Calendar.current.isDate(birthdate, inSameDayAs: originalDate) {
            // Stub for settings update action — replace with Realm save / delegate / pop
            let out = Self.formatDate(birthdate)
            print("Settings flow: update birthday to \(out)")
            return
        }

        // Default signup behavior (unchanged)
        if !isAtLeast(13, from: birthdate) {
            errorModalManager.showError("You must be at least 13 years old")
            return
        }
        
        super.didTapContinue()
        onContinue?(birthdate)
    }

    // MARK: - Helpers
    private static func parseDate(from string: String) -> Date? {
        // Expecting "MM/DD/YYYY" — construct a local date at NOON to avoid timezone drift
        let parts = string.split(separator: "/")
        guard parts.count == 3,
              let m = Int(parts[0]),
              let d = Int(parts[1]),
              let y = Int(parts[2]) else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        var comps = DateComponents()
        comps.calendar = cal
        comps.timeZone = .current
        comps.year = y
        comps.month = m
        comps.day = d
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)
    }

    private static func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "MM/dd/yyyy"
        return df.string(from: date)
    }
}


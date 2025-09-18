import UIKit
import Combine

struct PreSelectedHeightAndWeightData {
    let heightCm: Double
    let weightKg: Double
    let isMetric: Bool
}

final class HeightAndWeightViewController: BaseSignupViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var viewModel = HeightAndWeightViewModel(
        settingsRepository: SettingsRepositoryImpl(
            settingsAPI: NetworkManager(tokenManager: TokenManager()),
            userDataStore: RealmUserDataStore()
        )
    )
    private var cancellables = Set<AnyCancellable>()
    private var loader = LoadingOverlay()
    private lazy var alert = Alert(self)

    var onContinue: ((_ height: Double, _ weight: Double, _ isMetric: Bool) -> Void)?

    // MARK: - Source of truth (store in metric for precision)
    private var height: Measurement<UnitLength> = .init(value: 178, unit: .centimeters) // ~5'10"
    private var weight: Measurement<UnitMass>   = .init(value: 79,  unit: .kilograms)   // ~175 lb
    private var isMetric = false {
        didSet {
            updateUnitUI(fromToggle: true)
            updateContinueState() // NEW: reflect unit changes in the settings-mode gating
        }
    } // off = Imperial

    // MARK: - Ranges
    private let feetRange = Array(3...7)               // 3–7 ft
    private let inchesRange = Array(0...11)            // 0–11 in
    private let poundsRange = Array(70...350)          // 70–350 lb
    private let centimetersRange = Array(100...230)    // 100–230 cm
    private let kilogramsRange = Array(30...180)     // 30–180 kg

    // MARK: - UI
    private let metricContainer = UIView()
    private let unitRow = UIStackView()
    private let imperialLabel = UILabel()
    private let unitSwitch = UISwitch()
    private let metricLabel = UILabel()

    private let heightLabel = UILabel()
    private let weightLabel = UILabel()

    private let heightPicker = UIPickerView()
    private let weightPicker = UIPickerView()

    private let cols = UIStackView()
    private let leftCol = UIStackView()
    private let rightCol = UIStackView()
    
    // SETTINGS MODE: inject this when opening from Settings
    var preSelectedData: PreSelectedHeightAndWeightData? = nil

    // Track original values for change detection (settings mode only)
    private var originalHeightCm: Double?
    private var originalWeightKg: Double?
    private var originalIsMetric: Bool?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Height & weight"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Coach Cam uses this to give precise AI analysis and scoring.\n\nWe will never share this."
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Picker font (edit here)
    private let pickerFont = UIFont.systemFont(ofSize: 22, weight: .semibold)

    // install constraints once
    private var didInstallConstraints = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        setupViewModelBindings()
        buildUI()
        super.viewDidLoad()

        setProgress(0.45, animated: false)

        // Apply preselected values if provided (settings mode)
        if let data = preSelectedData {
            // Store originals for comparison
            originalHeightCm = data.heightCm
            originalWeightKg = data.weightKg
            originalIsMetric = data.isMetric

            // Set current state from provided cm/kg + unit
            height = .init(value: data.heightCm, unit: .centimeters)
            weight = .init(value: data.weightKg, unit: .kilograms)
            isMetric = data.isMetric
            unitSwitch.isOn = data.isMetric
            continueButton.setTitle("Save", for: .normal)
        } else {
            // Signup flow defaults (existing behavior)
            unitSwitch.isOn = false
        }

        wire()
        updateUnitUI(fromToggle: false) // reflects initial values in wheels
        updateContinueState()           // NEW: gate Continue in settings mode
    }
    
    private func setupViewModelBindings() {
        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loader.show(in: self!.view)
                } else {
                    self?.loader.hide()
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.alert.danger(
                        titleText: "Uh-oh",
                        bodyText: errorMessage,
                        buttonText: "Okay"
                    )
                    self?.viewModel.clearError()
                }
            }
            .store(in: &cancellables)
        
        // Bind name set success
        viewModel.$isHeightAndWeightSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHeightAndWeightSet in
                if isHeightAndWeightSet {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Build UI
    private func buildUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        metricContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metricContainer)

        unitRow.axis = .horizontal
        unitRow.alignment = .center
        unitRow.spacing = 12
        unitRow.translatesAutoresizingMaskIntoConstraints = false
        metricContainer.addSubview(unitRow)

        imperialLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        imperialLabel.text = "Imperial"

        metricLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        metricLabel.text = "Metric"

        unitSwitch.onTintColor = .label
        unitSwitch.isOn = false // Off = Imperial (matches your mock)

        unitRow.addArrangedSubview(imperialLabel)
        unitRow.addArrangedSubview(unitSwitch)
        unitRow.addArrangedSubview(metricLabel)
        unitRow.setCustomSpacing(20, after: unitSwitch)

        cols.axis = .horizontal
        cols.alignment = .top
        cols.distribution = .fillEqually
        cols.spacing = 24
        cols.translatesAutoresizingMaskIntoConstraints = false
        metricContainer.addSubview(cols)

        // Left (Height)
        leftCol.axis = .vertical
        leftCol.spacing = 8
        heightLabel.text = "Height"
        heightLabel.textAlignment = .center
        heightLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        heightPicker.dataSource = self
        heightPicker.delegate = self
        heightPicker.translatesAutoresizingMaskIntoConstraints = false

        leftCol.addArrangedSubview(heightLabel)
        leftCol.addArrangedSubview(heightPicker)

        // Right (Weight)
        rightCol.axis = .vertical
        rightCol.spacing = 8
        weightLabel.text = "Weight"
        weightLabel.textAlignment = .center
        weightLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        weightPicker.dataSource = self
        weightPicker.delegate = self
        weightPicker.translatesAutoresizingMaskIntoConstraints = false

        rightCol.addArrangedSubview(weightLabel)
        rightCol.addArrangedSubview(weightPicker)

        cols.addArrangedSubview(leftCol)
        cols.addArrangedSubview(rightCol)
    }

    override func layout() {
        super.layout()
        guard !didInstallConstraints else { return }
        didInstallConstraints = true

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Card
            metricContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            metricContainer.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 24),
            metricContainer.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -24),

            // Inside card
            unitRow.topAnchor.constraint(equalTo: metricContainer.topAnchor, constant: 20),
            unitRow.centerXAnchor.constraint(equalTo: metricContainer.centerXAnchor),

            cols.topAnchor.constraint(equalTo: unitRow.bottomAnchor, constant: 24),
            cols.leadingAnchor.constraint(equalTo: metricContainer.leadingAnchor, constant: 20),
            cols.trailingAnchor.constraint(equalTo: metricContainer.trailingAnchor, constant: -20),
            cols.bottomAnchor.constraint(equalTo: metricContainer.bottomAnchor, constant: -20),

            heightPicker.heightAnchor.constraint(equalToConstant: 210),
            weightPicker.heightAnchor.constraint(equalToConstant: 210)
        ])
    }

    private func wire() {
        unitSwitch.addTarget(self, action: #selector(toggleUnits(_:)), for: .valueChanged)
    }

    // MARK: - Units / Conversion
    @objc private func toggleUnits(_ sw: UISwitch) { isMetric = sw.isOn }

    private func updateUnitUI(fromToggle: Bool) {
        imperialLabel.textColor = isMetric ? .secondaryLabel : .label
        metricLabel.textColor   = isMetric ? .label : .secondaryLabel

        heightPicker.reloadAllComponents()
        weightPicker.reloadAllComponents()

        if isMetric {
            // Height -> cm
            let cm = Int(round(height.converted(to: .centimeters).value))
            let cmIdx = index(of: cm, in: centimetersRange) ??
                        clamp(cm, within: centimetersRange) - (centimetersRange.first ?? 0)
            heightPicker.selectRow(max(0, cmIdx), inComponent: 0, animated: fromToggle)

            // Weight -> kg
            let kg = Int(round(weight.converted(to: .kilograms).value))
            let kgIdx = index(of: kg, in: kilogramsRange) ??
                        clamp(kg, within: kilogramsRange) - (kilogramsRange.first ?? 0)
            weightPicker.selectRow(max(0, kgIdx), inComponent: 0, animated: fromToggle)
        } else {
            // Height -> ft + in
            let totalInches = height.converted(to: .inches).value
            var ft = Int(floor(totalInches / 12.0))
            var inch = Int(round(totalInches - Double(ft * 12)))
            if inch == 12 { ft += 1; inch = 0 }

            let ftIdx = index(of: ft, in: feetRange) ??
                        clamp(ft, within: feetRange) - (feetRange.first ?? 0)
            let inIdx = index(of: inch, in: inchesRange) ??
                        clamp(inch, within: inchesRange) - (inchesRange.first ?? 0)

            heightPicker.selectRow(max(0, ftIdx), inComponent: 0, animated: fromToggle)
            heightPicker.selectRow(max(0, inIdx), inComponent: 1, animated: fromToggle)

            // Weight -> lb
            let lb = Int(round(weight.converted(to: .pounds).value))
            let lbIdx = index(of: lb, in: poundsRange) ??
                        clamp(lb, within: poundsRange) - (poundsRange.first ?? 0)
            weightPicker.selectRow(max(0, lbIdx), inComponent: 0, animated: fromToggle)
        }
    }

    private func clamp(_ v: Int, within arr: [Int]) -> Int {
        guard let lo = arr.first, let hi = arr.last else { return v }
        return min(max(v, lo), hi)
    }
    private func index(of value: Int, in arr: [Int]) -> Int? {
        guard let lo = arr.first else { return nil }
        let idx = value - lo
        return (0..<arr.count).contains(idx) ? idx : nil
    }

    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView === heightPicker { return isMetric ? 1 : 2 }
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === heightPicker {
            return isMetric ? centimetersRange.count : (component == 0 ? feetRange.count : inchesRange.count)
        } else {
            return isMetric ? kilogramsRange.count : poundsRange.count
        }
    }

    // MARK: - UIPickerViewDelegate (custom font)
    private func textFor(_ pickerView: UIPickerView, row: Int, component: Int) -> String {
        if pickerView === heightPicker {
            if isMetric { return "\(centimetersRange[row]) cm" }
            return component == 0 ? "\(feetRange[row]) ft" : "\(inchesRange[row]) in"
        }
        return isMetric ? "\(kilogramsRange[row]) kg" : "\(poundsRange[row]) lb"
    }

    func pickerView(_ pickerView: UIPickerView,
                    viewForRow row: Int,
                    forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? {
            let l = UILabel()
            l.textAlignment = .center
            l.textColor = .label
            l.adjustsFontForContentSizeCategory = true
            return l
        }()
        // If you want Dynamic Type scaling:
        // label.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: pickerFont)
        label.font = pickerFont
        label.text = textFor(pickerView, row: row, component: component)
        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        max(44, pickerFont.lineHeight + 14)
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if pickerView === heightPicker && !isMetric { return pickerView.bounds.width * 0.45 }
        return pickerView.bounds.width * 0.9
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === heightPicker {
            if isMetric {
                let cm = centimetersRange[row]
                height = .init(value: Double(cm), unit: .centimeters)
            } else {
                let ft = feetRange[safe: pickerView.selectedRow(inComponent: 0)] ?? feetRange.first!
                let inch = inchesRange[safe: pickerView.selectedRow(inComponent: 1)] ?? inchesRange.first!
                let inches = Double(ft * 12 + inch)
                height = .init(value: inches, unit: .inches).converted(to: .centimeters)
            }
        } else {
            if isMetric {
                weight = .init(value: Double(kilogramsRange[row]), unit: .kilograms)
            } else {
                let lb = poundsRange[row]
                weight = .init(value: Double(lb), unit: .pounds).converted(to: .kilograms)
            }
        }
        updateContinueState() // NEW: react to wheel changes
    }

    // MARK: - Continue gating (settings mode)
    // MARK: - Continue gating (settings mode)
    private func updateContinueState() {
        guard let oHcm = originalHeightCm,
              let oWkg = originalWeightKg,
              let oMetric = originalIsMetric else {
            // Signup flow: original behavior (button enabled)
            continueButton.isEnabled = true
            continueButton.alpha = 1.0
            return
        }

        let curMetric = isMetric

        var changed = (curMetric != oMetric) // flipping the unit is a change

        if curMetric {
            // Compare in metric (cm / kg), rounded to picker granularity (ints)
            let curHcm = Int(round(height.converted(to: .centimeters).value))
            let curWkg = Int(round(weight.converted(to: .kilograms).value))
            let origHcm = Int(round(oHcm))
            let origWkg = Int(round(oWkg))
            if curHcm != origHcm || curWkg != origWkg { changed = true }
        } else {
            // Compare in imperial (total inches / pounds), rounded to picker granularity (ints)
            let curInches = Int(round(height.converted(to: .inches).value))
            let curLbs    = Int(round(weight.converted(to: .pounds).value))

            let origInches = Int(
                round(Measurement(value: oHcm, unit: UnitLength.centimeters).converted(to: .inches).value)
            )
            let origLbs = Int(
                round(Measurement(value: oWkg, unit: UnitMass.kilograms).converted(to: .pounds).value)
            )

            if curInches != origInches || curLbs != origLbs { changed = true }
        }

        continueButton.isEnabled = changed
        continueButton.alpha = changed ? 1.0 : 0.4
    }


    // MARK: - Continue
    override func didTapContinue() {
        // Settings flow branch: only when we had preselected values and user changed something
        if originalHeightCm != nil, originalWeightKg != nil, originalIsMetric != nil {
            // If button is enabled we already detected a change; run settings stub and exit
            if continueButton.isEnabled {
                let heightCm = height.converted(to: .centimeters).value
                let weightKg = weight.converted(to: .kilograms).value
                print("Settings flow: update height=\(Int(round(heightCm)))cm, weight=\(Int(round(weightKg)))kg, isMetric=\(isMetric)")
                
                viewModel.setBodyMetrics(height: heightCm, weight: weightKg, isMetric: isMetric)
                
                return
            } else {
                return // no change
            }
        }

        // Default signup behavior (unchanged)
        super.didTapContinue()
        let heightCm = height.converted(to: .centimeters).value
        let weightKg = weight.converted(to: .kilograms).value
        onContinue?(heightCm, weightKg, isMetric)
    }
}

// Safe index helper
private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}


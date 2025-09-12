import UIKit
import AVFoundation
import Combine

import UIKit
import Combine

final class StartAnalysisQuestionsViewController: BaseSignupViewController,
    UITextViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIScrollViewDelegate,
    UIGestureRecognizerDelegate
{
    // MARK: – Inputs
    private let thumbnail: UIImage?
    private let videoURL: URL?

    // MARK: – UI (scrollable stack)
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "A few quick questions"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Thumbnail card
    private let thumbCard = UIView()
    private let thumbImage = UIImageView()

    private let liftGroup = UIStackView()
    private let liftField = UIView()
    private let liftCaption = UILabel()
    private let liftValue = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let liftTable = UITableView(frame: .zero, style: .plain)
    private var liftTableHeight: NSLayoutConstraint!

    // Dropdown state
    private var dropdownOpen = false
    private let cornerRadius: CGFloat = 12

    // Lift
    private var lifts: [String] = []
    private var selectedLift: String = "" {
        didSet {
            liftValue.text = selectedLift
            updateContinueButtonState()
        }
    }

    // Prompt
    private let promptLabel: UILabel = {
        let l = UILabel()
        l.text = "Is there anything you’d like CoachCam to focus on in this video?"
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Details card
    private let detailsCard = UIView()
    private let detailsHeader = UIStackView()
    private let detailsTitle = UILabel()
    private let countLabel = UILabel()

    private let detailsText = UITextView()
    private let placeholder = UILabel()
    private let maxChars = 500

    private let isSignup: Bool

    private var cancellables = Set<AnyCancellable>()
    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    private let viewModel = StartAnalysisQuestionsViewModel(
        repository: VideoAnalysisRepository(
            analysisAPI: NetworkManager(tokenManager: TokenManager())
        )
    )

    // MARK: - Upload State Management
    var uploadStateManager: UploadStateManager?

    // MARK: – Keyboard dismissal
    private lazy var tapToDismiss: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardTap))
        g.cancelsTouchesInView = false // let buttons/table selections go through
        g.delegate = self
        return g
    }()

    @objc private func dismissKeyboardTap() {
        view.endEditing(true)
    }

    // MARK: – Init
    init(thumbnail: UIImage?, videoURL: URL? = nil, prefill: String? = nil, showProgress: Bool = true, isSignup: Bool = true, selectedLift: String?) {

        for _lift in Lift.allCases {
            lifts.append(_lift.rawValue.capitalized)
        }

        self.thumbnail = thumbnail
        self.videoURL = videoURL
        self.isSignup = isSignup

        if let _selectedLift = selectedLift {
            self.selectedLift = _selectedLift
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: – Lifecycle
    override func viewDidLoad() {
        buildUI()
        killDefaultLayout = true
        super.viewDidLoad()

        // Keyboard dismissal behaviors
        scroll.keyboardDismissMode = .interactive  // slide down on drag
        scroll.delegate = self                      // also end editing on drag start
        view.addGestureRecognizer(tapToDismiss)     // tap outside to dismiss

        setProgress(0.91, animated: false)
        updateContinueButtonState()
        setupBindings()
    }

    private func setupBindings() {
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let self, let errorMessage else { return }
                self.errorModalManager.showError(errorMessage)
                self.viewModel.clearError()
            }
            .store(in: &cancellables)

//        viewModel.$isUploadingVideo
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.navigationController?.dismiss(animated: true)
//            }
//            .store(in: &cancellables)
    }

    // MARK: – Build
    private func buildUI() {
        // Scroll + content stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        // Title
        content.addArrangedSubview(titleLabel)

        // Thumbnail card
        thumbCard.backgroundColor = .secondarySystemBackground
        thumbCard.layer.cornerRadius = cornerRadius
        thumbCard.layer.cornerCurve = .continuous
        thumbCard.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(thumbCard)

        thumbImage.image = thumbnail
        thumbImage.contentMode = .scaleAspectFit
        thumbImage.clipsToBounds = true
        thumbImage.layer.cornerRadius = cornerRadius
        thumbImage.layer.cornerCurve = .continuous
        thumbImage.translatesAutoresizingMaskIntoConstraints = false
        thumbCard.addSubview(thumbImage)

        // Lift group (field + table)
        liftGroup.axis = .vertical
        liftGroup.alignment = .fill
        liftGroup.spacing = 0
        liftGroup.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(liftGroup)

        // Field content
        liftField.backgroundColor = .secondarySystemBackground
        liftField.layer.cornerRadius = cornerRadius
        liftField.layer.cornerCurve = .continuous
        liftField.translatesAutoresizingMaskIntoConstraints = false

        liftCaption.text = "Lift"
        liftCaption.font = .systemFont(ofSize: 16, weight: .semibold)
        liftCaption.textColor = .secondaryLabel
        liftCaption.translatesAutoresizingMaskIntoConstraints = false

        liftValue.text = selectedLift
        liftValue.font = .systemFont(ofSize: 22, weight: .semibold)
        liftValue.translatesAutoresizingMaskIntoConstraints = false

        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit

        liftField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleDropdown)))
        liftField.addSubview(liftCaption)
        liftField.addSubview(liftValue)
        liftField.addSubview(chevron)

        // Dropdown table
        liftTable.isHidden = true
        liftTable.alpha = 0
        liftTable.layer.masksToBounds = true
        liftTable.layer.cornerRadius = cornerRadius
        liftTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        liftTable.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        liftTable.rowHeight = 52
        liftTable.dataSource = self
        liftTable.delegate = self
        liftTable.translatesAutoresizingMaskIntoConstraints = false

        // Assemble group
        liftGroup.addArrangedSubview(liftField)
        liftGroup.addArrangedSubview(liftTable)

        // Spacing before prompt
        content.setCustomSpacing(24, after: liftGroup)

        // Prompt
        content.addArrangedSubview(promptLabel)
        content.setCustomSpacing(10, after: promptLabel)

        // Details card
        detailsCard.backgroundColor = .secondarySystemBackground
        detailsCard.layer.cornerRadius = cornerRadius
        detailsCard.layer.cornerCurve = .continuous
        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(detailsCard)

        detailsHeader.axis = .horizontal
        detailsHeader.alignment = .center
        detailsHeader.spacing = 8
        detailsHeader.translatesAutoresizingMaskIntoConstraints = false

        detailsTitle.text = "Extra details"
        detailsTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        detailsTitle.textColor = .secondaryLabel

        countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.textColor = .secondaryLabel
        countLabel.text = "0/\(maxChars)"

        detailsHeader.addArrangedSubview(detailsTitle)
        detailsHeader.addArrangedSubview(UIView()) // spacer
        detailsHeader.addArrangedSubview(countLabel)
        detailsCard.addSubview(detailsHeader)

        detailsText.delegate = self
        detailsText.backgroundColor = .clear
        detailsText.font = .systemFont(ofSize: 18, weight: .regular)
        detailsText.textColor = .label
        detailsText.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        detailsText.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(detailsText)

        placeholder.textColor = .tertiaryLabel
        placeholder.font = .systemFont(ofSize: 18, weight: .regular)
        placeholder.numberOfLines = 0
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(placeholder)

        // Continue buttons from BaseSignupViewController
        content.addArrangedSubview(secondaryButton)
        content.addArrangedSubview(continueButton)
    }

    override func layout() {
        let g = view.safeAreaLayoutGuide

        // Scroll containment
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: g.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40) // 20+20
        ])

        // Thumb card + image
        NSLayoutConstraint.activate([
            thumbImage.centerXAnchor.constraint(equalTo: thumbCard.centerXAnchor),
            thumbImage.topAnchor.constraint(equalTo: thumbCard.topAnchor, constant: 16),
            thumbImage.bottomAnchor.constraint(equalTo: thumbCard.bottomAnchor, constant: -16),
            thumbImage.leadingAnchor.constraint(equalTo: thumbCard.leadingAnchor, constant: 16),
            thumbImage.trailingAnchor.constraint(equalTo: thumbCard.trailingAnchor, constant: -16),
            thumbImage.heightAnchor.constraint(equalToConstant: 220)
        ])

        // Lift field internals
        NSLayoutConstraint.activate([
            liftCaption.topAnchor.constraint(equalTo: liftField.topAnchor, constant: 16),
            liftCaption.leadingAnchor.constraint(equalTo: liftField.leadingAnchor, constant: 16),
            liftCaption.trailingAnchor.constraint(lessThanOrEqualTo: liftField.trailingAnchor, constant: -16),

            liftValue.topAnchor.constraint(equalTo: liftCaption.bottomAnchor, constant: 6),
            liftValue.leadingAnchor.constraint(equalTo: liftCaption.leadingAnchor),
            liftValue.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            liftValue.bottomAnchor.constraint(equalTo: liftField.bottomAnchor, constant: -16),

            chevron.centerYAnchor.constraint(equalTo: liftField.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: liftField.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Dropdown height (starts collapsed)
        liftTableHeight = liftTable.heightAnchor.constraint(equalToConstant: 0)
        liftTableHeight.isActive = true

        // Details card internals
        NSLayoutConstraint.activate([
            detailsHeader.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 14),
            detailsHeader.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 14),
            detailsHeader.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -14),

            detailsText.topAnchor.constraint(equalTo: detailsHeader.bottomAnchor, constant: 8),
            detailsText.leadingAnchor.constraint(equalTo: detailsHeader.leadingAnchor),
            detailsText.trailingAnchor.constraint(equalTo: detailsHeader.trailingAnchor),
            detailsText.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
            detailsText.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -14),

            placeholder.topAnchor.constraint(equalTo: detailsText.topAnchor),
            placeholder.leadingAnchor.constraint(equalTo: detailsText.leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: detailsText.trailingAnchor),

            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: – Dropdown
    @objc private func toggleDropdown() {
        dropdownOpen.toggle()

        let rows = min(6, lifts.count)
        liftTable.isHidden = false
        liftTableHeight.constant = dropdownOpen ? CGFloat(rows) * 52.0 : 0

        updateCornerMasks(isOpen: dropdownOpen)

        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.chevron.transform = self.dropdownOpen ? CGAffineTransform(rotationAngle: .pi/2) : .identity
            self.view.layoutIfNeeded()
            self.liftTable.alpha = self.dropdownOpen ? 1 : 0
        } completion: { _ in
            if !self.dropdownOpen {
                self.liftTable.isHidden = true
                self.updateCornerMasks(isOpen: false)
            } else if let idx = self.lifts.firstIndex(of: self.selectedLift) {
                let ip = IndexPath(row: idx, section: 0)
                self.liftTable.reloadData()
                self.liftTable.selectRow(at: ip, animated: false, scrollPosition: .middle)
            }
        }
    }

    private func updateCornerMasks(isOpen: Bool) {
        if isOpen {
            liftField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            liftTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            liftField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                             .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            liftTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }

    // MARK: – UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { lifts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "sportCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ??
                   UITableViewCell(style: .default, reuseIdentifier: id)
        let name = lifts[indexPath.row]
        cell.textLabel?.text = name
        cell.textLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        cell.textLabel?.textColor = .label
        cell.backgroundColor = .secondarySystemBackground
        cell.selectionStyle = .none
        let isSel = (name == selectedLift)
        cell.accessoryType = isSel ? .checkmark : .none
        return cell
    }

    // MARK: – UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLift = lifts[indexPath.row]
        let lift = Lift(rawValue: selectedLift.lowercased())!
        placeholder.text = lift.analysisPlaceholder()
        tableView.reloadData()
        toggleDropdown()
    }

    // MARK: – Scroll (keyboard)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    // MARK: – Tap filter (keyboard)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === tapToDismiss else { return true }
        guard let touched = touch.view else { return true }

        // Ignore taps inside inputs/controls so they still work
        if touched is UITextView || touched is UIControl { return false }

        // Ignore taps inside dropdown/table so selection still works
        if touched.isDescendant(of: liftTable) || touched.isDescendant(of: liftField) { return false }

        // Also ignore cell content views so table selection works
        if String(describing: type(of: touched)).contains("UITableViewCellContentView") { return false }

        return true
    }

    // MARK: – Continue
    override func didTapContinue() {
        super.didTapContinue()

        if isSignup {
            setUserDefaults()
            let vc = CreateAccountViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            startVideoUpload()
            navigationController?.dismiss(animated: true)
        }
    }

    private func startVideoUpload() {
        guard let videoURL = videoURL else {
            uploadStateManager?.failUpload(with: "No video URL available")
            return
        }

        // Start upload with snapshot
        uploadStateManager?.startUpload(snapshot: thumbnail)

        // Trigger upload in view model
        viewModel.startVideoUpload(fileURL: videoURL, liftType: selectedLift, uploadStateManager: uploadStateManager)
    }

    private func setUserDefaults() {
        // Save video data for analysis
        UserDefaultsManager.shared.updateVideoAnalysis(
            didUpload: true,
            videoURL: videoURL,
            videoSnapshot: thumbnail,
            liftType: selectedLift
        )
    }

    // MARK: – TextView
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
        if textView.text.count > maxChars {
            textView.text = String(textView.text.prefix(maxChars))
        }
        updateCount()
    }

    private func updateCount() { countLabel.text = "\(detailsText.text.count)/\(maxChars)" }

    private func updateContinueButtonState() {
        continueButton.isEnabled = !selectedLift.isEmpty
        continueButton.alpha = selectedLift.isEmpty ? 0.5 : 1.0
    }
}



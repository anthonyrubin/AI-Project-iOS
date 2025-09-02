import UIKit
import AVFoundation

final class StartAnalysisQuestionsViewController: BaseSignupViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {

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

    private let sportGroup = UIStackView()
    private let sportField = UIView()
    private let sportCaption = UILabel()
    private let sportValue = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let sportTable = UITableView(frame: .zero, style: .plain)
    private var sportTableHeight: NSLayoutConstraint!

    // Dropdown state
    private var dropdownOpen = false
    private let cornerRadius: CGFloat = 12

    // Sports
    private let sports: [String] = [
        "Golf","Tennis","Pickleball","Basketball","Baseball","Soccer","Weightlifting","Running",
        "Track & Field","Football (American)","Volleyball","Hockey","Softball","Lacrosse",
        "Cricket","Badminton","Table Tennis","Rowing","Striking (Boxing / Kickboxing / TKD)"
    ]
    private var selectedSport: String = "Golf" {
        didSet { sportValue.text = selectedSport }
    }

    // Prompt
    private let promptLabel: UILabel = {
        let l = UILabel()
        l.text = "Is there anything you’d like CoachAI to focus on in this video?"
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

    // MARK: – Init
    init(thumbnail: UIImage?, videoURL: URL? = nil, prefill: String? = nil, preselectedSport: String? = nil) {
        self.thumbnail = thumbnail
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
        if let s = preselectedSport, sports.contains(s) { selectedSport = s }
        if let prefill, !prefill.isEmpty {
            detailsText.text = prefill
            placeholder.isHidden = true
            updateCount()
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: – Lifecycle
    override func viewDidLoad() {
        killDefaultLayout = true
        //setupSecondaryButton(text: "Skip for now", selector: #selector(skipTapped))
        super.viewDidLoad()
        setProgress(0.91, animated: false)
        buildUI()
        layoutUI()
    }

    // MARK: – Build
    private func buildUI() {
        // Scroll + content stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
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

        // ✅ Sport group (field + table) with spacing = 0
        sportGroup.axis = .vertical
        sportGroup.alignment = .fill
        sportGroup.spacing = 0
        sportGroup.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(sportGroup)

        // sportField (tappable)
        sportField.backgroundColor = .secondarySystemBackground
        sportField.layer.cornerRadius = cornerRadius
        sportField.layer.cornerCurve = .continuous
        sportField.translatesAutoresizingMaskIntoConstraints = false

        // Field content
        sportCaption.text = "Sport"
        sportCaption.font = .systemFont(ofSize: 16, weight: .semibold)
        sportCaption.textColor = .secondaryLabel
        sportCaption.translatesAutoresizingMaskIntoConstraints = false

        sportValue.text = selectedSport
        sportValue.font = .systemFont(ofSize: 22, weight: .semibold)
        sportValue.translatesAutoresizingMaskIntoConstraints = false

        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit

        sportField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleDropdown)))
        sportField.addSubview(sportCaption)
        sportField.addSubview(sportValue)
        sportField.addSubview(chevron)

        // sportTable (dropdown)
        sportTable.isHidden = true
        sportTable.alpha = 0
        sportTable.layer.masksToBounds = true
        sportTable.layer.cornerRadius = cornerRadius
        sportTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // bottom only; top corners handled by field
        sportTable.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        sportTable.rowHeight = 52
        sportTable.dataSource = self
        sportTable.delegate = self
        sportTable.translatesAutoresizingMaskIntoConstraints = false

        // Assemble group
        sportGroup.addArrangedSubview(sportField)
        sportGroup.addArrangedSubview(sportTable)

        // After group, keep normal spacing before prompt
        content.setCustomSpacing(24, after: sportGroup)

        // Prompt
        content.addArrangedSubview(promptLabel)

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

        placeholder.text = "I would like to know how I can do better on this sport."
        placeholder.textColor = .tertiaryLabel
        placeholder.font = .systemFont(ofSize: 18, weight: .regular)
        placeholder.numberOfLines = 0
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(placeholder)

        // Continue at the bottom of content
        content.addArrangedSubview(secondaryButton)
        content.addArrangedSubview(continueButton)
    }

    private func layoutUI() {
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

        // Sport field internals
        NSLayoutConstraint.activate([
            sportCaption.topAnchor.constraint(equalTo: sportField.topAnchor, constant: 16),
            sportCaption.leadingAnchor.constraint(equalTo: sportField.leadingAnchor, constant: 16),
            sportCaption.trailingAnchor.constraint(lessThanOrEqualTo: sportField.trailingAnchor, constant: -16),

            sportValue.topAnchor.constraint(equalTo: sportCaption.bottomAnchor, constant: 6),
            sportValue.leadingAnchor.constraint(equalTo: sportCaption.leadingAnchor),
            sportValue.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            sportValue.bottomAnchor.constraint(equalTo: sportField.bottomAnchor, constant: -16),

            chevron.centerYAnchor.constraint(equalTo: sportField.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: sportField.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Dropdown height (starts collapsed)
        sportTableHeight = sportTable.heightAnchor.constraint(equalToConstant: 0)
        sportTableHeight.isActive = true

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

        let rows = min(6, sports.count)
        sportTable.isHidden = false
        sportTableHeight.constant = dropdownOpen ? CGFloat(rows) * 52.0 : 0

        updateCornerMasks(isOpen: dropdownOpen)

        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.chevron.transform = self.dropdownOpen ? CGAffineTransform(rotationAngle: .pi/2) : .identity
            self.view.layoutIfNeeded()
            self.sportTable.alpha = self.dropdownOpen ? 1 : 0
        } completion: { _ in
            if !self.dropdownOpen {
                self.sportTable.isHidden = true
                self.updateCornerMasks(isOpen: false)
            } else if let idx = self.sports.firstIndex(of: self.selectedSport) {
                let ip = IndexPath(row: idx, section: 0)
                self.sportTable.reloadData()
                self.sportTable.selectRow(at: ip, animated: false, scrollPosition: .middle)
            }
        }
    }

    private func updateCornerMasks(isOpen: Bool) {
        if isOpen {
            sportField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            sportTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            sportField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                              .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            sportTable.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }

    // MARK: – UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sports.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "sportCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ??
                   UITableViewCell(style: .default, reuseIdentifier: id)
        let name = sports[indexPath.row]
        cell.textLabel?.text = name
        cell.textLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        cell.textLabel?.textColor = .label
        cell.backgroundColor = .secondarySystemBackground
        cell.selectionStyle = .none
        let isSel = (name == selectedSport)
        cell.accessoryType = isSel ? .checkmark : .none
        return cell
    }

    // MARK: – UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSport = sports[indexPath.row]
        tableView.reloadData()
        toggleDropdown()
    }

    // MARK: – Actions
//    @objc private func skipTapped() {
//        setUserDefaults()
//        let vc = CreateAccountViewController()
//        navigationController?.pushViewController(vc, animated: true)
//    }

    override func didTapContinue() {
        super.didTapContinue()
        setUserDefaults()
        let vc = CreateAccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setUserDefaults() {
        UserDefaultsManager.shared.updateProgress(progress: 0.50, step: "sport_selected")
        
        // Save video data for analysis
        UserDefaultsManager.shared.updateVideoAnalysis(
            didUpload: true,
            videoURL: videoURL,
            videoSnapshot: thumbnail
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
}


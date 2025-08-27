import UIKit
import AVFoundation

final class StartAnalysisQuestionsViewController: BaseSignupViewController, UITextViewDelegate {

    // MARK: – Inputs
    private let thumbnail: UIImage?
    private let videoURL: URL?

    // Callers can capture this to receive the values and push the next VC.
    var onContinue: ((String, URL?) -> Void)?

    // MARK: – UI
    private let scroll = UIScrollView()
    private let content = UIView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "A few questions"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Thumbnail card
    private let thumbCard = UIView()
    private let thumbImage = UIImageView()

    // Sport field
    private let sportField = UIView()
    private let sportCaption = UILabel()
    private let sportValue = UILabel()

    // Prompt
    private let promptLabel: UILabel = {
        let l = UILabel()
        l.text =
        "Is there anything you’d like CoachAI to focus on in this video, or any specific feedback?"
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Extra details
    private let detailsCard = UIView()
    private let detailsHeader = UIStackView()
    private let detailsTitle = UILabel()
    private let dotLabel = UILabel()
    private let countLabel = UILabel()

    private let detailsText = UITextView()
    private let placeholder = UILabel()

    private let skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Skip for now", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: – State
    private let maxChars = 500

    // MARK: – Init
    init(thumbnail: UIImage?, videoURL: URL? = nil, prefill: String? = nil) {
        self.thumbnail = thumbnail
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
        if let prefill, !prefill.isEmpty {
            detailsText.text = prefill
            placeholder.isHidden = true
            updateCount()
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setProgress(0.88, animated: false)
        buildUI()
        layoutUI()
        wire()
        continueButton.setTitle("Continue", for: .normal)
        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep scrollable content above the fixed continue button
        let pad = continueButton.bounds.height + 28
        if scroll.contentInset.bottom != pad {
            scroll.contentInset.bottom = pad
            scroll.verticalScrollIndicatorInsets.bottom = pad
        }
    }

    // MARK: – Build
    private func buildUI() {
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(titleLabel)

        // Thumbnail card
        thumbCard.backgroundColor = .secondarySystemBackground
        thumbCard.layer.cornerRadius = 22
        thumbCard.layer.cornerCurve = .continuous
        thumbCard.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(thumbCard)

        thumbImage.image = thumbnail
        thumbImage.contentMode = .scaleAspectFill
        thumbImage.clipsToBounds = true
        thumbImage.layer.cornerRadius = 18
        thumbImage.layer.cornerCurve = .continuous
        thumbImage.translatesAutoresizingMaskIntoConstraints = false
        thumbCard.addSubview(thumbImage)

        // Sport field (readonly)
        sportField.backgroundColor = .secondarySystemBackground
        sportField.layer.cornerRadius = 22
        sportField.layer.cornerCurve = .continuous
        sportField.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(sportField)

        sportCaption.text = "Sport"
        sportCaption.font = .systemFont(ofSize: 16, weight: .semibold)
        sportCaption.textColor = .secondaryLabel
        sportCaption.translatesAutoresizingMaskIntoConstraints = false

        sportValue.text = "sport"
        sportValue.font = .systemFont(ofSize: 22, weight: .semibold)
        sportValue.translatesAutoresizingMaskIntoConstraints = false

        sportField.addSubview(sportCaption)
        sportField.addSubview(sportValue)

        // Prompt
        content.addSubview(promptLabel)

        // Details card
        detailsCard.backgroundColor = .secondarySystemBackground
        detailsCard.layer.cornerRadius = 22
        detailsCard.layer.cornerCurve = .continuous
        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(detailsCard)

        // Header: "Extra details • 0/500"
        detailsHeader.axis = .horizontal
        detailsHeader.alignment = .center
        detailsHeader.spacing = 8
        detailsHeader.translatesAutoresizingMaskIntoConstraints = false

        detailsTitle.text = "Extra details"
        detailsTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        detailsTitle.textColor = .secondaryLabel

        dotLabel.text = "•"
        dotLabel.textColor = .tertiaryLabel

        countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.textColor = .secondaryLabel
        countLabel.text = "0/\(maxChars)"

        detailsHeader.addArrangedSubview(detailsTitle)
        detailsHeader.addArrangedSubview(dotLabel)
        detailsHeader.addArrangedSubview(UIView()) // spacer
        detailsHeader.addArrangedSubview(countLabel)
        detailsCard.addSubview(detailsHeader)

        // TextView + placeholder
        detailsText.delegate = self
        detailsText.backgroundColor = .clear
        detailsText.font = .systemFont(ofSize: 18, weight: .regular)
        detailsText.textColor = .label
        detailsText.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        detailsText.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(detailsText)

        placeholder.text = "I would like to know how I can do better on this \("sport.lowercased()")."
        placeholder.textColor = .tertiaryLabel
        placeholder.font = .systemFont(ofSize: 18, weight: .regular)
        placeholder.numberOfLines = 0
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(placeholder)

        // Skip
        content.addSubview(skipButton)
    }

    private func layoutUI() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Scroll containment
            scroll.topAnchor.constraint(equalTo: g.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            // Thumbnail card
            thumbCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            thumbCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            thumbCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            thumbImage.centerXAnchor.constraint(equalTo: thumbCard.centerXAnchor),
            thumbImage.topAnchor.constraint(equalTo: thumbCard.topAnchor, constant: 16),
            thumbImage.bottomAnchor.constraint(equalTo: thumbCard.bottomAnchor, constant: -16),
            thumbImage.leadingAnchor.constraint(equalTo: thumbCard.leadingAnchor, constant: 16),
            thumbImage.trailingAnchor.constraint(equalTo: thumbCard.trailingAnchor, constant: -16),
            thumbImage.heightAnchor.constraint(equalToConstant: 220),

            // Sport field
            sportField.topAnchor.constraint(equalTo: thumbCard.bottomAnchor, constant: 16),
            sportField.leadingAnchor.constraint(equalTo: thumbCard.leadingAnchor),
            sportField.trailingAnchor.constraint(equalTo: thumbCard.trailingAnchor),

            sportCaption.topAnchor.constraint(equalTo: sportField.topAnchor, constant: 16),
            sportCaption.leadingAnchor.constraint(equalTo: sportField.leadingAnchor, constant: 16),
            sportCaption.trailingAnchor.constraint(lessThanOrEqualTo: sportField.trailingAnchor, constant: -16),

            sportValue.topAnchor.constraint(equalTo: sportCaption.bottomAnchor, constant: 6),
            sportValue.leadingAnchor.constraint(equalTo: sportCaption.leadingAnchor),
            sportValue.trailingAnchor.constraint(lessThanOrEqualTo: sportField.trailingAnchor, constant: -16),
            sportValue.bottomAnchor.constraint(equalTo: sportField.bottomAnchor, constant: -16),

            // Prompt
            promptLabel.topAnchor.constraint(equalTo: sportField.bottomAnchor, constant: 26),
            promptLabel.leadingAnchor.constraint(equalTo: sportField.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: sportField.trailingAnchor),

            // Details card
            detailsCard.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 14),
            detailsCard.leadingAnchor.constraint(equalTo: sportField.leadingAnchor),
            detailsCard.trailingAnchor.constraint(equalTo: sportField.trailingAnchor),

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

            // Skip
            skipButton.topAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: 20),
            skipButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            skipButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12)
        ])
    }

    private func wire() {
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    // MARK: – Actions
    @objc private func skipTapped() {
        onContinue?("", videoURL)
    }

    override func didTapContinue() {
        super.didTapContinue()
        let text = detailsText.text.trimmingCharacters(in: .whitespacesAndNewlines)
        onContinue?(text, videoURL)
    }

    // MARK: – TextView
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
        // enforce max
        if textView.text.count > maxChars {
            textView.text = String(textView.text.prefix(maxChars))
            // optional haptic
        }
        updateCount()
    }

    private func updateCount() {
        countLabel.text = "\(detailsText.text.count)/\(maxChars)"
    }
}

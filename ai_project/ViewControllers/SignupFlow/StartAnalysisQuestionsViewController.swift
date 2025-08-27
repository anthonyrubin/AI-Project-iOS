import UIKit
import AVFoundation

import UIKit

final class StartAnalysisQuestionsViewController: BaseSignupViewController, UITextViewDelegate {

    // MARK: – Inputs
    private let thumbnail: UIImage?
    private let videoURL: URL?

    // MARK: – UI (stacked)
    private let scrollView = UIScrollView()
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

    // Sport field
    private let sportField = UIView()
    private let sportCaption = UILabel()
    private let sportValue = UILabel()

    // Prompt
    private let promptLabel: UILabel = {
        let l = UILabel()
        l.text = "Is there anything you’d like CoachAI to focus on in this video, or any specific feedback?"
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
        killDefaultLayout = true
        buildUI()
        setupSecondaryButton(text: "Skip for now", selector: #selector(skipTapped))
        super.viewDidLoad()

        setProgress(0.88, animated: false)
    }

    // MARK: – Build
    private func buildUI() {
        // scroll + vertical stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        // Title
        content.addArrangedSubview(titleLabel)

        // Thumbnail card
        thumbCard.backgroundColor = .secondarySystemBackground
        thumbCard.layer.cornerRadius = 22
        thumbCard.layer.cornerCurve  = .continuous
        thumbCard.translatesAutoresizingMaskIntoConstraints = false

        thumbImage.image = thumbnail
        thumbImage.contentMode = .scaleAspectFill
        thumbImage.clipsToBounds = true
        thumbImage.layer.cornerRadius = 18
        thumbImage.layer.cornerCurve  = .continuous
        thumbImage.translatesAutoresizingMaskIntoConstraints = false

        thumbCard.addSubview(thumbImage)
        NSLayoutConstraint.activate([
            thumbImage.topAnchor.constraint(equalTo: thumbCard.topAnchor, constant: 16),
            thumbImage.leadingAnchor.constraint(equalTo: thumbCard.leadingAnchor, constant: 16),
            thumbImage.trailingAnchor.constraint(equalTo: thumbCard.trailingAnchor, constant: -16),
            thumbImage.bottomAnchor.constraint(equalTo: thumbCard.bottomAnchor, constant: -16),
            thumbImage.heightAnchor.constraint(equalToConstant: 220)
        ])
        content.addArrangedSubview(thumbCard)

        // Sport field (readonly)
        sportField.backgroundColor = .secondarySystemBackground
        sportField.layer.cornerRadius = 22
        sportField.layer.cornerCurve  = .continuous
        sportField.translatesAutoresizingMaskIntoConstraints = false

        sportCaption.text = "Sport"
        sportCaption.font = .systemFont(ofSize: 16, weight: .semibold)
        sportCaption.textColor = .secondaryLabel
        sportCaption.translatesAutoresizingMaskIntoConstraints = false

        sportValue.text = "sport"
        sportValue.font = .systemFont(ofSize: 22, weight: .semibold)
        sportValue.translatesAutoresizingMaskIntoConstraints = false

        sportField.addSubview(sportCaption)
        sportField.addSubview(sportValue)
        NSLayoutConstraint.activate([
            sportCaption.topAnchor.constraint(equalTo: sportField.topAnchor, constant: 16),
            sportCaption.leadingAnchor.constraint(equalTo: sportField.leadingAnchor, constant: 16),
            sportCaption.trailingAnchor.constraint(lessThanOrEqualTo: sportField.trailingAnchor, constant: -16),

            sportValue.topAnchor.constraint(equalTo: sportCaption.bottomAnchor, constant: 6),
            sportValue.leadingAnchor.constraint(equalTo: sportCaption.leadingAnchor),
            sportValue.trailingAnchor.constraint(lessThanOrEqualTo: sportField.trailingAnchor, constant: -16),
            sportValue.bottomAnchor.constraint(equalTo: sportField.bottomAnchor, constant: -16)
        ])
        content.addArrangedSubview(sportField)

        // Prompt
        content.addArrangedSubview(promptLabel)

        // Details card
        detailsCard.backgroundColor = .secondarySystemBackground
        detailsCard.layer.cornerRadius = 22
        detailsCard.layer.cornerCurve  = .continuous
        detailsCard.translatesAutoresizingMaskIntoConstraints = false

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

        detailsText.delegate = self
        detailsText.backgroundColor = .clear
        detailsText.font = .systemFont(ofSize: 18, weight: .regular)
        detailsText.textColor = .label
        detailsText.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        detailsText.translatesAutoresizingMaskIntoConstraints = false

        placeholder.text = "I would like to know how I can do better on this sport."
        placeholder.textColor = .tertiaryLabel
        placeholder.font = .systemFont(ofSize: 18, weight: .regular)
        placeholder.numberOfLines = 0
        placeholder.translatesAutoresizingMaskIntoConstraints = false

        detailsCard.addSubview(detailsHeader)
        detailsCard.addSubview(detailsText)
        detailsCard.addSubview(placeholder)

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
        ])

        content.addArrangedSubview(detailsCard)

        // Footer actions (stacked so they scroll if needed)
        content.addArrangedSubview(secondaryButton)
        content.addArrangedSubview(continueButton)
    }

    override func layout() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Scroll view pinned to safe area
            scrollView.topAnchor.constraint(equalTo: g.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: g.bottomAnchor),

            // Content stack inside scroll
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Make content match scroll width so it only scrolls when needed
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),

            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: – Actions
    @objc private func skipTapped() {
        let vc = CreateAccountViewController(didUploadVideoForAnalysis: false)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func didTapContinue() {
        super.didTapContinue()
        // Grab the (optional) text and carry forward as needed
        let _ = detailsText.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let vc = CreateAccountViewController(didUploadVideoForAnalysis: true)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: – TextView
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
        if textView.text.count > maxChars {
            textView.text = String(textView.text.prefix(maxChars))
        }
        updateCount()
    }

    private func updateCount() {
        countLabel.text = "\(detailsText.text.count)/\(maxChars)"
    }
}

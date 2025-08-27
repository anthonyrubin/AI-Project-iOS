import UIKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Row with left circular SF icon + multiline text
private final class TipRowView: UIView {
    private let circle = UIView()
    private let icon   = UIImageView()
    private let label  = UILabel()

    init(text: String, symbol: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        circle.layer.cornerRadius = 22
        circle.layer.cornerCurve = .continuous
        addSubview(circle)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.image = UIImage(systemName: symbol)?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = .label
        circle.addSubview(icon)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        addSubview(label)

        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            circle.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 44),
            circle.heightAnchor.constraint(equalToConstant: 44),

            icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Image card (light container with rounded image inside)
private final class MediaCardView: UIView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.label.withAlphaComponent(0.05)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.cornerCurve = .continuous
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Screen
final class StartAnalysisViewController: BaseSignupViewController, PHPickerViewControllerDelegate {

    // Title (scrolls with content)
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Let’s analyze your performance"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.text = "Upload a clip to start your coaching journey."
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Scroll content
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    private let mediaCard = MediaCardView()
    private let tipsStack = UIStackView()

    override func viewDidLoad() {
        buildUI()
        killDefaultLayout = true            // (your base uses this to skip fixed button layout)
        setupSecondaryButton(text: "Skip for now", selector: #selector(didTapSkip))
        super.viewDidLoad()
        setProgress(0.90, animated: false)
        configureData()
    }

    // MARK: UI
    private func buildUI() {
        // Scroll view + content stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        view.addSubview(scrollView)

        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        content.addArrangedSubview(titleLabel)
        content.setCustomSpacing(8, after: titleLabel)
        content.addArrangedSubview(subtitleLabel)
        content.setCustomSpacing(16, after: subtitleLabel)

        // Image card
        content.addArrangedSubview(mediaCard)

        // Tips
        tipsStack.axis = .vertical
        tipsStack.alignment = .fill
        tipsStack.spacing = 18
        tipsStack.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(tipsStack)

        content.addArrangedSubview(secondaryButton)
        content.addArrangedSubview(continueButton)
    }

    override func layout() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: g.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),

            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Make content match scroll width so it only scrolls when needed
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),

            mediaCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configureData() {
        mediaCard.imageView.image = UIImage(named: "golfPreview")
        if mediaCard.imageView.image == nil {
            mediaCard.imageView.backgroundColor = .tertiarySystemFill
        }

        let tips: [(String, String)] = [
            ("Be well lit and fully in frame.", "viewfinder"),
            ("Don’t stand too far from the camera.", "magnifyingglass.circle"),
            ("Use 60 fps if possible.", "speedometer")
        ]
        tips.forEach { tipsStack.addArrangedSubview(TipRowView(text: $0.0, symbol: $0.1)) }
    }

    // MARK: Actions
    @objc private func didTapSkip() {
        // Skip straight to questions (no video)
        let vc = CreateAccountViewController(didUploadVideoForAnalysis: false)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func didTapContinue() {
        super.didTapContinue()
        presentVideoPicker()
    }

    // MARK: Picker
    private func presentVideoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.videos])     // video only

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let result = results.first else { return }
        let provider = result.itemProvider
        let movieUTI = UTType.movie.identifier

        guard provider.hasItemConformingToTypeIdentifier(movieUTI) else { return }

        provider.loadFileRepresentation(forTypeIdentifier: movieUTI) { [weak self] tempURL, error in
            guard let self = self else { return }
            if let error = error {
                print("Picker error:", error)
                return
            }
            guard let src = tempURL else { return }

            // Copy to a stable temporary location (the provided URL may be ephemeral)
            let ext = src.pathExtension.isEmpty ? "mov" : src.pathExtension
            let dst = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)

            do {
                // If a file exists at dst for some reason, remove then copy
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
                try FileManager.default.copyItem(at: src, to: dst)
            } catch {
                print("Copy movie failed:", error)
                return
            }

            // Generate thumbnail
            let image = self.generateThumbnail(for: dst)

            DispatchQueue.main.async {
                let vc = StartAnalysisQuestionsViewController(thumbnail: image, videoURL: dst)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    // MARK: Thumbnail
    private func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let duration = asset.duration.seconds
        let captureSecond = duration.isFinite && duration > 0 ? min(1.0, duration / 2.0) : 0.5
        let time = CMTime(seconds: captureSecond, preferredTimescale: 600)

        do {
            let cg = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cg)
        } catch {
            print("Thumbnail generation failed:", error)
            return nil
        }
    }
}


import UIKit
import Combine

final class VideoAnalysisLoadingViewController: BaseSignupViewController {

    // MARK: - Properties
    private let videoURL: URL
    private let videoSnapshot: UIImage?

    private let viewModel: VideoAnalysisLoadingViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    let progressView = CircularProgressView()
    
    private var progressTimer: Timer?
    private var messageTimer: Timer?
    
    private var currentProgress: CGFloat = 0
    private var messageIndex = 0
    private var didFireFinish = false


    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your first AI analysis is underway"
        l.font = .systemFont(ofSize: 35, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Outer “card”
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.label.withAlphaComponent(0.05) // like your Figma
        v.layer.cornerRadius = 22
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// Horizontal stack: [thumbnail | steps]
    private let hStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    /// Left column – image
    private let videoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18
        iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Right column – progress steps
    private let progressStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 14
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var progressStepViews: [ProgressStepView] = []
    private let liftType: String

    // MARK: - Init
    init(videoURL: URL, videoSnapshot: UIImage?, liftType: String) {
        self.videoURL = videoURL
        self.videoSnapshot = videoSnapshot
        self.liftType = liftType
        self.viewModel = VideoAnalysisLoadingViewModel(
            videoAnalysisRepository: VideoAnalysisRepository(analysisAPI: NetworkManager(tokenManager: TokenManager()))
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        killDefaultLayout = true
        setProgress(0.95, animated: false)
        buildUI()
        hideBackButton = true
        hidesProgressBar = true
        super.viewDidLoad()
        setupProgressSteps()
        setupViewModelBindings()
        startVideoUpload()
    }

    // MARK: - Build
    private func buildUI() {
        view.backgroundColor = .systemBackground

        // Title & card
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        videoImageView.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(hStack)

        // Left (image)
        videoImageView.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(videoImageView)

        // Right (steps)
        hStack.addArrangedSubview(progressStackView)

        // Image content
        if let snapshot = videoSnapshot {
            videoImageView.image = snapshot
        } else {
            videoImageView.backgroundColor = .tertiarySystemFill
        }

    }

    override func layout() {
        let g = view.safeAreaLayoutGuide
        super.layout()

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            // Card
            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: g.bottomAnchor, constant: -28),

            // Stack inside card
            hStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            // Image: size only (do NOT pin to hStack edges)
            videoImageView.widthAnchor.constraint(equalToConstant: 150),
            videoImageView.heightAnchor.constraint(equalTo: videoImageView.widthAnchor, multiplier: 1.2),
            
            progressView.centerXAnchor.constraint(equalTo: videoImageView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: videoImageView.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: videoImageView.widthAnchor, multiplier: 0.55),
            progressView.heightAnchor.constraint(equalTo: progressView.widthAnchor),
        ])

        // Let the right column take extra horizontal space
        progressStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        progressStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        videoImageView.setContentHuggingPriority(.required, for: .horizontal)
        videoImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Optional: make sure the steps never compress vertically
        progressStackView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // MARK: - Steps / VM
    private func setupProgressSteps() {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 0
        
        label.text = "Analyzing Features"
        
        let steps = [
            "• Keyframes",
            "• Motion",
            "• Joints",
            "• Kinematics",
            "• Technique"
        ]
        
        progressStackView.addArrangedSubview(label)
        
        steps.forEach {
            let v = ProgressStepView(text: $0, isCompleted: false)
            progressStepViews.append(v)
            progressStackView.addArrangedSubview(v)
        }
    }
    
    // MARK: - Tuning
    private let expectedUploadDuration: TimeInterval = 25        // ~full run
    private let mainCap: CGFloat = 0.92                          // leave headroom for push
    private let minStepSpacing: TimeInterval = 0.9               // >= time between step flips
    private let pushPhaseSplit: CGFloat = 0.65                   // % of push to ~97%

    // MARK: - Step pacing state
    private var stepThresholds: [CGFloat] = []                   // computed once
    private var lastStepFlipAt: CFTimeInterval = 0               // throttle flips

    private func configureStepThresholds() {
        // Evenly space steps from ~12% to ~90% so they feel tied to progress
        let count = max(progressStepViews.count, 1)
        let start: CGFloat = 0.12
        let end:   CGFloat = min(0.90, mainCap)                  // last step before the push
        if count == 1 { stepThresholds = [min(end, max(start, 0.25))]; return }

        let delta = (end - start) / CGFloat(count - 1)
        stepThresholds = (0..<count).map { start + CGFloat($0) * delta }
        // Example for 5 steps: [0.12, 0.315, 0.51, 0.705, 0.90]
    }

    private func advanceStepsIfNeeded() {
        let now = CACurrentMediaTime()
        while messageIndex < stepThresholds.count,
              currentProgress >= stepThresholds[messageIndex] {

            // Throttle so flips never "machine gun"
            if now - lastStepFlipAt < minStepSpacing { break }
            
            updateProgressSteps(currentIndex: messageIndex)

            messageIndex += 1
            lastStepFlipAt = now
        }
    }

    func startLoading() {
        titleLabel.text = "Your first AI analysis is underway"
        if stepThresholds.isEmpty { configureStepThresholds() }
        lastStepFlipAt = 0

        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            let p = self.currentProgress
            if p < 0.70 { self.currentProgress += 0.015 }
            else if p < 0.86 { self.currentProgress += 0.009 }
            else if p < 0.92 { self.currentProgress += 0.004 }
            else if p < 0.94 { self.currentProgress += 0.001 }
            self.currentProgress = min(self.currentProgress, self.mainCap)
            self.progressView.setProgress(self.currentProgress)

            self.advanceStepsIfNeeded()
        }

        // No step timer anymore.
        messageTimer?.invalidate()
        messageTimer = nil
    }

    func finishLoading(completion: @escaping (() -> Void)) {
        DispatchQueue.main.async {
            let g = UIImpactFeedbackGenerator(style: .soft)
            g.prepare(); g.impactOccurred()
        }

        titleLabel.text = "Your first AI analysis is complete"
        progressTimer?.invalidate()
        messageTimer?.invalidate()
        didFireFinish = false

        // Stretch push so remaining steps don’t violate minStepSpacing
        let remaining = max(0, progressStepViews.count - messageIndex)
        let basePush: TimeInterval = 1.0
        let totalPush = max(basePush, Double(remaining) * minStepSpacing + 0.2)
        let phase1 = totalPush * Double(pushPhaseSplit)           // to ~0.97
        let phase2 = totalPush - phase1
        let tick: TimeInterval = 1.0 / 60.0

        // Phase 1: ease-out toward ~97%
        let start = currentProgress
        let pushTarget: CGFloat = max(mainCap, 0.97)
        var elapsed1: TimeInterval = 0

        progressTimer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            elapsed1 += tick
            let x = min(1.0, elapsed1 / phase1)
            let easeOut = 1 - pow(1 - x, 2)

            self.currentProgress = start + (pushTarget - start) * CGFloat(easeOut)
            self.progressView.setProgress(self.currentProgress)
            self.advanceStepsIfNeeded()

            if elapsed1 >= phase1 {
                t.invalidate(); self.progressTimer = nil

                // Phase 2: ease-in to 100%
                let start2 = self.currentProgress
                var elapsed2: TimeInterval = 0

                self.progressTimer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] t2 in
                    guard let self else { t2.invalidate(); return }
                    elapsed2 += tick
                    let x2 = min(1.0, elapsed2 / phase2)
                    let easeIn = x2 * x2 * x2

                    self.currentProgress = start2 + (1.0 - start2) * CGFloat(easeIn)
                    self.progressView.setProgress(self.currentProgress)
                    self.advanceStepsIfNeeded()

                    if elapsed2 >= phase2 {
                        t2.invalidate(); self.progressTimer = nil
                        self.currentProgress = 1.0
                        self.progressView.setProgress(1.0)

                        // Ensure all steps show complete
                        if self.messageIndex < self.progressStepViews.count {
                            self.messageIndex = self.progressStepViews.count
                        }

                        UINotificationFeedbackGenerator().notificationOccurred(.success)

                        guard !self.didFireFinish else { return }
                        self.didFireFinish = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            completion()
                        }
                    }
                }
            }
        }
    }

    
    
    
    private func setupViewModelBindings() {
//        viewModel.$currentStepIndex
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] idx in self?.updateProgressSteps(currentIndex: idx) }
//            .store(in: &cancellables)

//        viewModel.$isUploadComplete
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] done in
//                self?.continueButton.isEnabled = done
//                self?.continueButton.alpha = done ? 1 : 0.5
//            }
//            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let msg = msg else { return }
                self?.errorModalManager.showError(msg)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.startLoading()
                } else {
                    self?.finishLoading {
                        self?.pushNext()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func startVideoUpload() {
        viewModel.startVideoUpload(videoURL: videoURL, liftType: liftType)
    }

    private func updateProgressSteps(currentIndex: Int) {
        for (i, v) in progressStepViews.enumerated() { v.setCompleted(i <= currentIndex, animated: true) }
    }
    
    private func pushNext() {
        let vc = BecomeAMemberViewController()
        
        navigationController?.pushViewController(vc, animated: true)
    }
}


// MARK: - Progress Step View

class ProgressStepView: UIView {
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemGray4
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(text: String, isCompleted: Bool) {
        super.init(frame: .zero)
        textLabel.text = text
        setupUI()
        setCompleted(isCompleted, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(checkmarkImageView)
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            checkmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),
            
            checkmarkImageView.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func setCompleted(_ completed: Bool, animated: Bool) {
        let changes = {
            self.checkmarkImageView.tintColor = completed ? .systemGreen : .systemGray4
            self.textLabel.textColor = completed ? .label : .secondaryLabel
            let g = UIImpactFeedbackGenerator(style: .soft)
            g.prepare()
            g.impactOccurred()
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: changes)
        } else {
            changes()
        }
    }
}




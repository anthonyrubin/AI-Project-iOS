import UIKit
import AVFoundation
import PryntTrimmerView

final class EditVideoViewController: UIViewController {

    // MARK: Public
    var onFinish: ((CMTimeRange) -> Void)?

    // MARK: Init
    private let videoURL: URL
    private let maxDuration: TimeInterval
    init(videoURL: URL, maxDuration: TimeInterval = 15) {
        self.videoURL = videoURL
        self.maxDuration = maxDuration
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Trim to one full rep (max 15s)"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.numberOfLines = 0
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Drag the ends to crop from the start of the rep to the end of the rep."
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private let content = UIView()

    // Video box preserves aspect
    private let playerBox = UIView()
    private let playerView = UIView()
    private var aspectConstraint: NSLayoutConstraint!
    private var widthEqualConstraint: NSLayoutConstraint!
    private var heightCapConstraint: NSLayoutConstraint!

    // Player loading cover
    private let playerLoadingCover: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        v.alpha = 1
        return v
    }()
    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // Prynt trimmer
    private let trimmer = TrimmerView()
    private let trimmerSkeleton: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemFill
        v.layer.cornerRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Selection info label (between video and trimmer)
    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.baseBackgroundColor = .label
        var attrs = AttributeContainer()
        attrs.font = .systemFont(ofSize: 18, weight: .semibold)
        attrs.foregroundColor = UIColor.systemBackground
        cfg.attributedTitle = AttributedString("Continue", attributes: attrs)
        let b = UIButton(configuration: cfg, primaryAction: UIAction { [weak self] _ in
            self?.didTapContinue()
        })
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isEnabled = false
        return b
    }()

    // MARK: Playback/State
    private var asset: AVAsset!
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private var timeObserverToken: Any?
    private var displayLink: CADisplayLink?
    private var itemStatusObservation: NSKeyValueObservation?

    // Loop/gesture tracking
    private var endBoundaryToken: Any?
    private var isScrubbingBar = false

    // Range tracking
    private var lastStart: CMTime?
    private var lastEnd: CMTime?
    private var initialStart: CMTime?
    private var initialEnd: CMTime?
    private var userAdjustedRange = false

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        configurePlayer()
        setNeutralLoadingState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureTrimmer() // after layout so width exists
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
        playerLayer.cornerRadius = 12
        playerLayer.masksToBounds = true
        updatePlayerHeightCap()
    }

    deinit {
        if let t = timeObserverToken { player.removeTimeObserver(t) }
        if let b = endBoundaryToken { player.removeTimeObserver(b) }
        itemStatusObservation?.invalidate()
        displayLink?.invalidate()
    }

    // MARK: UI
    private func buildUI() {
        [titleLabel, subtitleLabel, content, playerBox, playerView, trimmer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Labels never move
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        playerBox.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(content)
        view.addSubview(continueButton)

        content.addSubview(playerBox)
        playerBox.addSubview(playerView)
        playerView.backgroundColor = .secondarySystemBackground

        // Loading overlay
        playerView.addSubview(playerLoadingCover)
        playerLoadingCover.contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            playerLoadingCover.topAnchor.constraint(equalTo: playerView.topAnchor),
            playerLoadingCover.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            playerLoadingCover.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            playerLoadingCover.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: playerLoadingCover.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: playerLoadingCover.centerYAnchor)
        ])
        spinner.startAnimating()

        content.addSubview(durationLabel)
        content.addSubview(trimmer)
        content.addSubview(trimmerSkeleton)
        trimmer.alpha = 0
        trimmerSkeleton.alpha = 1

        let g = view.safeAreaLayoutGuide

        // Top labels: exact spacings
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])

        // Bottom button
        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Content between subtitle and button with 25 / 25 padding
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 25),
            content.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -25)
        ])

        // Player box, full width tendency, aspect required
        NSLayoutConstraint.activate([
            playerBox.topAnchor.constraint(equalTo: content.topAnchor),
            playerBox.centerXAnchor.constraint(equalTo: content.centerXAnchor),
        ])
        widthEqualConstraint = playerBox.widthAnchor.constraint(equalTo: content.widthAnchor)
        widthEqualConstraint.priority = .defaultHigh
        widthEqualConstraint.isActive = true

        aspectConstraint = playerBox.heightAnchor.constraint(equalTo: playerBox.widthAnchor, multiplier: 9.0/16.0)
        aspectConstraint.isActive = true

        // Dynamic cap so the video never steals space from labels/trimmer
        heightCapConstraint = playerBox.heightAnchor.constraint(lessThanOrEqualTo: content.heightAnchor, constant: -200)
        heightCapConstraint.isActive = true

        // PlayerView fills the box
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerBox.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerBox.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerBox.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerBox.bottomAnchor)
        ])

        // Selection label between video and trimmer (total gap 15: 6 + 9)
        NSLayoutConstraint.activate([
            durationLabel.topAnchor.constraint(equalTo: playerBox.bottomAnchor, constant: 6),
            durationLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor)
        ])

        // Trimmer at bottom (56pt), 9 under label
        NSLayoutConstraint.activate([
            trimmer.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            trimmer.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            trimmer.heightAnchor.constraint(equalToConstant: 56),
            trimmer.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            trimmer.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 9)
        ])

        // Skeleton = trimmer frame
        NSLayoutConstraint.activate([
            trimmerSkeleton.leadingAnchor.constraint(equalTo: trimmer.leadingAnchor),
            trimmerSkeleton.trailingAnchor.constraint(equalTo: trimmer.trailingAnchor),
            trimmerSkeleton.topAnchor.constraint(equalTo: trimmer.topAnchor),
            trimmerSkeleton.bottomAnchor.constraint(equalTo: trimmer.bottomAnchor)
        ])

        // Player layer
        playerLayer.videoGravity = .resizeAspect
        playerView.layer.addSublayer(playerLayer)
    }

    private func updatePlayerHeightCap() {
        let labelHeight = durationLabel.sizeThatFits(CGSize(width: content.bounds.width, height: .greatestFiniteMagnitude)).height
        let reserved: CGFloat = 6 + labelHeight + 9 + 56
        heightCapConstraint.constant = -reserved
    }

    // MARK: Player
    private func configurePlayer() {
        asset = AVAsset(url: videoURL)

        // Use presentation size for aspect
        if let track = asset.tracks(withMediaType: .video).first {
            let n = track.naturalSize
            let t = track.preferredTransform
            let s = n.applying(t)
            let w = max(abs(s.width), 1)
            let h = max(abs(s.height), 1)
            let mult = h / w
            aspectConstraint.isActive = false
            aspectConstraint = playerBox.heightAnchor.constraint(equalTo: playerBox.widthAnchor, multiplier: mult)
            aspectConstraint.isActive = true
            view.setNeedsLayout()
        }

        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        player.actionAtItemEnd = .none            // <-- don’t pause at end
        playerLayer.player = player

        // Hide loading when ready
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if itm.status == .readyToPlay { self.hidePlayerLoading() }
            }
        }

        // Periodic observer only handles the FULL-ASSET loop (before user adjusts)
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            guard !self.userAdjustedRange else { return } // trimmed loop handled by boundary observer
            let now = self.player.currentTime()
            let end = self.asset.duration
            // Tiny epsilon to avoid flapping at exact boundary
            let eps = CMTime(value: 1, timescale: 600)
            if now + eps >= end {
                self.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    if !self.isScrubbingBar { self.player.play() }
                }
            }
        }

        player.play()
        startDisplayLink()
    }

    private func hidePlayerLoading() {
        guard playerLoadingCover.alpha > 0 else { return }
        spinner.stopAnimating()
        UIView.animate(withDuration: 0.2) { self.playerLoadingCover.alpha = 0 }
    }

    private func startDisplayLink() {
        displayLink?.invalidate()
        let dl = CADisplayLink(target: self, selector: #selector(frameTick))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    // Re-arm a moving boundary that fires just before the (current) end handle
    private func refreshEndBoundaryObserver() {
        if let b = endBoundaryToken {
            player.removeTimeObserver(b)
            endBoundaryToken = nil
        }
        guard userAdjustedRange, let end = trimmer.endTime else { return }
        // Trigger slightly before end (1/30s) to avoid overshoot
        var preEnd = end - CMTime(value: 1, timescale: 30)
        if preEnd < .zero { preEnd = .zero }
        endBoundaryToken = player.addBoundaryTimeObserver(forTimes: [NSValue(time: preEnd)], queue: .main) { [weak self] in
            guard let self = self else { return }
            let start = self.trimmer.startTime ?? .zero
            self.player.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                if !self.isScrubbingBar { self.player.play() } // keep playing after loop
            }
        }
    }

    @objc private func frameTick() {
        trimmer.seek(to: player.currentTime())

        if let s = trimmer.startTime, let e = trimmer.endTime {
            if initialStart == nil || initialEnd == nil {
                initialStart = s; initialEnd = e
            } else if !userAdjustedRange {
                let tol = CMTime(value: 1, timescale: 600)
                if abs((s - initialStart!).seconds) > tol.seconds || abs((e - initialEnd!).seconds) > tol.seconds {
                    userAdjustedRange = true
                    refreshEndBoundaryObserver() // first time they adjust, arm boundary
                }
            }

            if s != lastStart || e != lastEnd {
                lastStart = s; lastEnd = e
                refreshEndBoundaryObserver() // end moved -> update boundary
                updateDurationAndValidity()
                // If we just expanded the right handle and we're sitting paused at 0, kick playback
                if !isScrubbingBar, player.rate == 0 { player.play() }
            }

            if trimmer.alpha == 0 {
                UIView.transition(with: trimmer, duration: 0.18, options: .transitionCrossDissolve, animations: {
                    self.trimmer.alpha = 1
                    self.trimmerSkeleton.alpha = 0
                }, completion: { _ in
                    self.trimmerSkeleton.isHidden = true
                })
            }
        }
    }

    // MARK: Trimmer
    private func configureTrimmer() {
        // Build the AVAsset once
        if asset == nil { asset = AVAsset(url: videoURL) }

        // Load duration first (safer for iCloud/remote URLs)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                var error: NSError?
                guard self.asset.statusOfValue(forKey: "duration", error: &error) == .loaded else { return }

                let dur = self.asset.duration.seconds

                // Set BEFORE assigning the asset so initial selection spans the full clip
                if dur.isFinite, dur > 0 {
                    self.trimmer.minDuration = 0
                    self.trimmer.maxDuration = dur
                } else {
                    self.trimmer.minDuration = 0
                    self.trimmer.maxDuration = .greatestFiniteMagnitude
                }

                self.trimmer.mainColor = .secondarySystemBackground
                self.trimmer.handleColor = .systemGray3
                self.trimmer.positionBarColor = .systemGray5
                self.trimmer.delegate = self

                self.trimmer.asset = self.asset

                // Fade skeleton when thumbnails appear
                UIView.transition(with: self.trimmer, duration: 0.18, options: .transitionCrossDissolve, animations: {
                    self.trimmer.alpha = 1
                    self.trimmerSkeleton.alpha = 0
                }, completion: { _ in
                    self.trimmerSkeleton.isHidden = true
                })

                self.updateDurationAndValidity()
            }
        }
    }

    private func setNeutralLoadingState() {
        continueButton.isEnabled = false
        var cfg = continueButton.configuration
        cfg?.baseBackgroundColor = .tertiaryLabel
        continueButton.configuration = cfg
        durationLabel.text = "Loading…"
    }

    // MARK: UI State
    private func updateDurationAndValidity() {
        guard let s = trimmer.startTime, let e = trimmer.endTime else {
            setNeutralLoadingState()
            return
        }

        let sel = max(0, CMTimeGetSeconds(e - s))
        let valid = sel > 0.0 && sel <= maxDuration

        durationLabel.text = String(format: "Selection: %.1fs / %ds max", sel, Int(maxDuration))

        // Button
        continueButton.isEnabled = valid
        var cfg = continueButton.configuration
        cfg?.baseBackgroundColor = valid ? .label : .tertiaryLabel
        continueButton.configuration = cfg

        // ALWAYS color the trimmer based on validity (no gating on userAdjustedRange)
        let tint: UIColor = valid ? .systemGreen : .systemRed
        trimmer.handleColor = tint
        trimmer.positionBarColor = tint
    }


    // MARK: Actions
    private func didTapContinue() {
        if let start = trimmer.startTime, let end = trimmer.endTime {
            onFinish?(CMTimeRange(start: start, end: end))
        }
    }
}

// MARK: - PryntTrimmerView delegate
extension EditVideoViewController: TrimmerViewDelegate {
    func didChangePositionBar(_ playerTime: CMTime) {
        isScrubbingBar = true
        player.pause()
        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        isScrubbingBar = false
        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }
}



//import UIKit
//import AVFoundation
//import PryntTrimmerView
//
//final class EditVideoViewController: UIViewController {
//
//    // MARK: Public
//    var onFinish: ((CMTimeRange) -> Void)?
//
//    // MARK: Init
//    private let videoURL: URL
//    private let maxDuration: TimeInterval
//    init(videoURL: URL, maxDuration: TimeInterval = 15) {
//        self.videoURL = videoURL
//        self.maxDuration = maxDuration
//        super.init(nibName: nil, bundle: nil)
//    }
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//
//    // MARK: UI
//    private let titleLabel: UILabel = {
//        let l = UILabel()
//        l.text = "Trim to one full rep (max 15s)"
//        l.font = .systemFont(ofSize: 28, weight: .bold)
//        l.numberOfLines = 0
//        return l
//    }()
//    private let subtitleLabel: UILabel = {
//        let l = UILabel()
//        l.text = "Drag the ends to crop from the start of the rep to the end of the rep."
//        l.font = .systemFont(ofSize: 15, weight: .regular)
//        l.textColor = .secondaryLabel
//        l.numberOfLines = 0
//        return l
//    }()
//
//    private let content = UIView()
//
//    // Video box preserves aspect
//    private let playerBox = UIView()
//    private let playerView = UIView()
//    private var aspectConstraint: NSLayoutConstraint!
//    private var widthEqualConstraint: NSLayoutConstraint!
//    private var heightCapConstraint: NSLayoutConstraint!
//
//    // Player loading cover
//    private let playerLoadingCover: UIVisualEffectView = {
//        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
//        v.translatesAutoresizingMaskIntoConstraints = false
//        v.isUserInteractionEnabled = false
//        v.alpha = 1
//        return v
//    }()
//    private let spinner: UIActivityIndicatorView = {
//        let s = UIActivityIndicatorView(style: .large)
//        s.hidesWhenStopped = true
//        s.translatesAutoresizingMaskIntoConstraints = false
//        return s
//    }()
//
//    // Prynt trimmer
//    private let trimmer = TrimmerView()
//    private let trimmerSkeleton: UIView = {
//        let v = UIView()
//        v.backgroundColor = .secondarySystemFill
//        v.layer.cornerRadius = 6
//        v.translatesAutoresizingMaskIntoConstraints = false
//        return v
//    }()
//
//    // Selection info label (between video and trimmer)
//    private let durationLabel: UILabel = {
//        let l = UILabel()
//        l.font = .systemFont(ofSize: 13, weight: .semibold)
//        l.textColor = .secondaryLabel
//        l.textAlignment = .right
//        l.translatesAutoresizingMaskIntoConstraints = false
//        return l
//    }()
//
//    private lazy var continueButton: UIButton = {
//        var cfg = UIButton.Configuration.filled()
//        cfg.cornerStyle = .capsule
//        cfg.baseBackgroundColor = .label
//        var attrs = AttributeContainer()
//        attrs.font = .systemFont(ofSize: 18, weight: .semibold)
//        attrs.foregroundColor = UIColor.systemBackground
//        cfg.attributedTitle = AttributedString("Continue", attributes: attrs)
//        let b = UIButton(configuration: cfg, primaryAction: UIAction { [weak self] _ in
//            self?.didTapContinue()
//        })
//        b.translatesAutoresizingMaskIntoConstraints = false
//        b.isEnabled = false
//        return b
//    }()
//
//    // MARK: Playback/State
//    private var asset: AVAsset!
//    private let player = AVPlayer()
//    private let playerLayer = AVPlayerLayer()
//    private var timeObserverToken: Any?
//    private var displayLink: CADisplayLink?
//    private var itemStatusObservation: NSKeyValueObservation?
//
//    // Range tracking
//    private var lastStart: CMTime?
//    private var lastEnd: CMTime?
//    private var initialStart: CMTime?
//    private var initialEnd: CMTime?
//    private var userAdjustedRange = false
//
//    // MARK: Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        buildUI()
//        configurePlayer()
//        setNeutralLoadingState()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        configureTrimmer() // after layout so width exists
//        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
//    }
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        playerLayer.frame = playerView.bounds
//        playerLayer.cornerRadius = 12
//        playerLayer.masksToBounds = true
//        updatePlayerHeightCap()
//    }
//
//    deinit {
//        if let t = timeObserverToken { player.removeTimeObserver(t) }
//        itemStatusObservation?.invalidate()
//        displayLink?.invalidate()
//    }
//
//    // MARK: UI
//    private func buildUI() {
//        [titleLabel, subtitleLabel, content, playerBox, playerView, trimmer].forEach {
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        // Labels never move
//        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//        titleLabel.setContentHuggingPriority(.required, for: .vertical)
//        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
//        playerBox.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
//
//        view.addSubview(titleLabel)
//        view.addSubview(subtitleLabel)
//        view.addSubview(content)
//        view.addSubview(continueButton)
//
//        content.addSubview(playerBox)
//        playerBox.addSubview(playerView)
//        playerView.backgroundColor = .secondarySystemBackground
//
//        // Loading overlay
//        playerView.addSubview(playerLoadingCover)
//        playerLoadingCover.contentView.addSubview(spinner)
//        NSLayoutConstraint.activate([
//            playerLoadingCover.topAnchor.constraint(equalTo: playerView.topAnchor),
//            playerLoadingCover.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
//            playerLoadingCover.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
//            playerLoadingCover.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
//            spinner.centerXAnchor.constraint(equalTo: playerLoadingCover.centerXAnchor),
//            spinner.centerYAnchor.constraint(equalTo: playerLoadingCover.centerYAnchor)
//        ])
//        spinner.startAnimating()
//
//        content.addSubview(durationLabel)
//        content.addSubview(trimmer)
//        content.addSubview(trimmerSkeleton)
//        trimmer.alpha = 0
//        trimmerSkeleton.alpha = 1
//
//        let g = view.safeAreaLayoutGuide
//
//        // Top labels: exact spacings
//        NSLayoutConstraint.activate([
//            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 16),
//            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
//            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
//
//            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
//            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
//        ])
//
//        // Bottom button
//        NSLayoutConstraint.activate([
//            continueButton.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
//            continueButton.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
//            continueButton.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),
//            continueButton.heightAnchor.constraint(equalToConstant: 56)
//        ])
//
//        // Content between subtitle and button with 25 / 25 padding
//        NSLayoutConstraint.activate([
//            content.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 25),
//            content.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            content.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
//            content.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -25)
//        ])
//
//        // Player box, full width tendency, aspect required
//        NSLayoutConstraint.activate([
//            playerBox.topAnchor.constraint(equalTo: content.topAnchor),
//            playerBox.centerXAnchor.constraint(equalTo: content.centerXAnchor),
//        ])
//        widthEqualConstraint = playerBox.widthAnchor.constraint(equalTo: content.widthAnchor)
//        widthEqualConstraint.priority = .defaultHigh
//        widthEqualConstraint.isActive = true
//
//        aspectConstraint = playerBox.heightAnchor.constraint(equalTo: playerBox.widthAnchor, multiplier: 9.0/16.0)
//        aspectConstraint.isActive = true
//
//        // Dynamic cap so the video never steals space from labels/trimmer
//        heightCapConstraint = playerBox.heightAnchor.constraint(lessThanOrEqualTo: content.heightAnchor, constant: -200)
//        heightCapConstraint.isActive = true
//
//        // PlayerView fills the box
//        NSLayoutConstraint.activate([
//            playerView.topAnchor.constraint(equalTo: playerBox.topAnchor),
//            playerView.leadingAnchor.constraint(equalTo: playerBox.leadingAnchor),
//            playerView.trailingAnchor.constraint(equalTo: playerBox.trailingAnchor),
//            playerView.bottomAnchor.constraint(equalTo: playerBox.bottomAnchor)
//        ])
//
//        // Selection label between video and trimmer (total gap 15: 6 + 9)
//        NSLayoutConstraint.activate([
//            durationLabel.topAnchor.constraint(equalTo: playerBox.bottomAnchor, constant: 6),
//            durationLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
//            durationLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor)
//        ])
//
//        // Trimmer at bottom (56pt), 9 under label
//        NSLayoutConstraint.activate([
//            trimmer.leadingAnchor.constraint(equalTo: content.leadingAnchor),
//            trimmer.trailingAnchor.constraint(equalTo: content.trailingAnchor),
//            trimmer.heightAnchor.constraint(equalToConstant: 56),
//            trimmer.bottomAnchor.constraint(equalTo: content.bottomAnchor),
//            trimmer.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 9)
//        ])
//
//        // Skeleton = trimmer frame
//        NSLayoutConstraint.activate([
//            trimmerSkeleton.leadingAnchor.constraint(equalTo: trimmer.leadingAnchor),
//            trimmerSkeleton.trailingAnchor.constraint(equalTo: trimmer.trailingAnchor),
//            trimmerSkeleton.topAnchor.constraint(equalTo: trimmer.topAnchor),
//            trimmerSkeleton.bottomAnchor.constraint(equalTo: trimmer.bottomAnchor)
//        ])
//
//        // Player layer
//        playerLayer.videoGravity = .resizeAspect
//        playerView.layer.addSublayer(playerLayer)
//    }
//
//    private func updatePlayerHeightCap() {
//        let labelHeight = durationLabel.sizeThatFits(CGSize(width: content.bounds.width, height: .greatestFiniteMagnitude)).height
//        let reserved: CGFloat = 6 + labelHeight + 9 + 56
//        heightCapConstraint.constant = -reserved
//    }
//
//    // MARK: Player
//    private func configurePlayer() {
//        asset = AVAsset(url: videoURL)
//
//        // Use presentation size for aspect
//        if let track = asset.tracks(withMediaType: .video).first {
//            let n = track.naturalSize
//            let t = track.preferredTransform
//            let s = n.applying(t)
//            let w = max(abs(s.width), 1)
//            let h = max(abs(s.height), 1)
//            let mult = h / w
//            aspectConstraint.isActive = false
//            aspectConstraint = playerBox.heightAnchor.constraint(equalTo: playerBox.widthAnchor, multiplier: mult)
//            aspectConstraint.isActive = true
//            view.setNeedsLayout()
//        }
//
//        let item = AVPlayerItem(asset: asset)
//        player.replaceCurrentItem(with: item)
//        playerLayer.player = player
//
//        // Hide loading when ready
//        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] itm, _ in
//            guard let self = self else { return }
//            DispatchQueue.main.async {
//                if itm.status == .readyToPlay { self.hidePlayerLoading() }
//            }
//        }
//
//        // Loop whole asset until user adjusts, then loop selection
//        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
//        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
//            guard let self = self else { return }
//            let now = self.player.currentTime()
//            if self.userAdjustedRange, let s = self.trimmer.startTime, let e = self.trimmer.endTime {
//                if now >= e { self.player.seek(to: s, toleranceBefore: .zero, toleranceAfter: .zero) }
//            } else {
//                if now >= self.asset.duration { self.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) }
//            }
//        }
//
//        player.play()
//        startDisplayLink()
//    }
//
//    private func hidePlayerLoading() {
//        guard playerLoadingCover.alpha > 0 else { return }
//        spinner.stopAnimating()
//        UIView.animate(withDuration: 0.2) { self.playerLoadingCover.alpha = 0 }
//    }
//
//    private func startDisplayLink() {
//        displayLink?.invalidate()
//        let dl = CADisplayLink(target: self, selector: #selector(frameTick))
//        dl.add(to: .main, forMode: .common)
//        displayLink = dl
//    }
//
//    @objc private func frameTick() {
//        trimmer.seek(to: player.currentTime())
//
//        if let s = trimmer.startTime, let e = trimmer.endTime {
//            if initialStart == nil || initialEnd == nil {
//                initialStart = s; initialEnd = e
//            } else if !userAdjustedRange {
//                let tol = CMTime(value: 1, timescale: 600)
//                if abs((s - initialStart!).seconds) > tol.seconds || abs((e - initialEnd!).seconds) > tol.seconds {
//                    userAdjustedRange = true
//                }
//            }
//
//            if s != lastStart || e != lastEnd {
//                lastStart = s; lastEnd = e
//                updateDurationAndValidity()
//            }
//
//            if trimmer.alpha == 0 {
//                UIView.transition(with: trimmer, duration: 0.18, options: .transitionCrossDissolve, animations: {
//                    self.trimmer.alpha = 1
//                    self.trimmerSkeleton.alpha = 0
//                }, completion: { _ in
//                    self.trimmerSkeleton.isHidden = true
//                })
//            }
//        }
//    }
//
//    // MARK: Trimmer
//    private func configureTrimmer() {
//        // Build the AVAsset once
//        // (If you already created `asset` elsewhere, reuse it)
//        if asset == nil { asset = AVAsset(url: videoURL) }
//
//        // Load duration first (safer for iCloud/remote URLs)
//        asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
//            DispatchQueue.main.async {
//                guard let self = self else { return }
//                var error: NSError?
//                guard self.asset.statusOfValue(forKey: "duration", error: &error) == .loaded else { return }
//
//                let dur = self.asset.duration.seconds
//
//                // IMPORTANT: set these BEFORE assigning the asset so the initial
//                // selection stretches from 0...duration instead of a fixed window.
//                if dur.isFinite, dur > 0 {
//                    // Public API on most SPM/CocoaPods versions
//                    self.trimmer.minDuration = 0
//                    self.trimmer.maxDuration = dur
//                } else {
//                    self.trimmer.minDuration = 0
//                    self.trimmer.maxDuration = .greatestFiniteMagnitude
//                }
//
//                // Colors/appearance
//                self.trimmer.mainColor = .secondarySystemBackground
//                self.trimmer.handleColor = .systemGray3
//                self.trimmer.positionBarColor = .systemGray5
//                self.trimmer.delegate = self
//
//                // Now assign the asset (this is what computes the initial handles)
//                self.trimmer.asset = self.asset
//
//                // If your SPM build somehow moved the property (older commit mentions this),
//                // you can defensively set via Obj-C selectors as a fallback:
//                // (Safe no-ops if the selectors don’t exist.)
//                let setMax = NSSelectorFromString("setMaxDuration:")
//                if self.trimmer.responds(to: setMax) { _ = self.trimmer.perform(setMax, with: NSNumber(value: dur)) }
//                let setMin = NSSelectorFromString("setMinDuration:")
//                if self.trimmer.responds(to: setMin) { _ = self.trimmer.perform(setMin, with: NSNumber(value: 0.0)) }
//
//                // Fade out your skeleton once thumbnails/track are visible
//                UIView.transition(with: self.trimmer, duration: 0.18, options: .transitionCrossDissolve, animations: {
//                    self.trimmer.alpha = 1
//                    self.trimmerSkeleton.alpha = 0
//                }, completion: { _ in
//                    self.trimmerSkeleton.isHidden = true
//                })
//
//                // Update label/button state (full-range is >15s, so disabled/red)
//                self.updateDurationAndValidity()
//            }
//        }
//    }
//
//    /// Some SPM versions of PryntTrimmerView expose `maxDuration` / `minDuration`.
//    /// Using Obj-C selectors keeps this compatible across versions without touching internals.
//    private func forceFullSpanSelection() {
//        let dur = asset.duration.seconds
//
//        // If available, allow the overlay to expand to full duration
//        let setMax = NSSelectorFromString("setMaxDuration:")
//        if trimmer.responds(to: setMax) {
//            _ = trimmer.perform(setMax, with: NSNumber(value: dur))
//        }
//        // Ensure we don't enforce a minimum window
//        let setMin = NSSelectorFromString("setMinDuration:")
//        if trimmer.responds(to: setMin) {
//            _ = trimmer.perform(setMin, with: NSNumber(value: 0.0))
//        }
//    }
//
//    private func setNeutralLoadingState() {
//        continueButton.isEnabled = false
//        var cfg = continueButton.configuration
//        cfg?.baseBackgroundColor = .tertiaryLabel
//        continueButton.configuration = cfg
//        durationLabel.text = "Loading…"
//    }
//
//    // MARK: UI State
//    private func updateDurationAndValidity() {
//        guard let s = trimmer.startTime, let e = trimmer.endTime else {
//            setNeutralLoadingState(); return
//        }
//        let sel = max(0, CMTimeGetSeconds(e - s))
//        let valid = sel > 0.0 && sel <= maxDuration
//
//        durationLabel.text = String(format: "Selection: %.1fs / %ds max", sel, Int(maxDuration))
//
//        continueButton.isEnabled = valid
//        var cfg = continueButton.configuration
//        cfg?.baseBackgroundColor = valid ? .label : .tertiaryLabel
//        continueButton.configuration = cfg
//
//        let tint = userAdjustedRange ? (valid ? UIColor.systemGreen : UIColor.systemRed) : UIColor.systemGray3
//        trimmer.handleColor = tint
//        trimmer.positionBarColor = userAdjustedRange ? tint : .systemGray5
//    }
//
//    // MARK: Actions
//    private func didTapContinue() {
//        if let start = trimmer.startTime, let end = trimmer.endTime {
//            onFinish?(CMTimeRange(start: start, end: end))
//        }
//    }
//}
//
//// MARK: - PryntTrimmerView delegate
//extension EditVideoViewController: TrimmerViewDelegate {
//    func didChangePositionBar(_ playerTime: CMTime) {
//        player.pause()
//        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
//    }
//    func positionBarStoppedMoving(_ playerTime: CMTime) {
//        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
//        player.play()
//    }
//}

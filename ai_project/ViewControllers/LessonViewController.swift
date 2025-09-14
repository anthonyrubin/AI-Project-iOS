import UIKit
import AVKit
import AVFoundation
import RealmSwift
import Combine

final class LessonViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: LessonViewModel
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var statusObs: NSKeyValueObservation?
    private var sizeObs: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Split + UI constants
    private let sideMargin: CGFloat = 20
    private let topMargin: CGFloat = 16
    private let interSectionSpacing: CGFloat = 8

    // Ratios for draggable range
    private let minVideoHeightRatio: CGFloat = 0.25 // 25%
    private let maxVideoHeightRatio: CGFloat = 0.50 // 50%

    // MARK: - UI
    private let videoContainerView = UIView()
    private var videoHeightConstraint: NSLayoutConstraint?

    private let handleContainer = UIView()
    private let handlePill = UIView()
    private var panOnHandle: UIPanGestureRecognizer!

    private let metricsContainerView = UIView()
    private let metricsTableView = UITableView()

    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()

    // MARK: - State
    private var initialVideoHeightOnPan: CGFloat = 0
    private var isDragEnabled: Bool = false
    private var didApplyInitialSizing = false

    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    // MARK: - Init
    init(analysis: VideoAnalysisObject) {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        layout.minimumInteritemSpacing = 12
//        layout.minimumLineSpacing = 12
//        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
//        self.metricsTableView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        self.viewModel = LessonViewModel(
            analysis: analysis,
            repository: VideoAnalysisRepository(
                analysisAPI: NetworkManager(tokenManager: TokenManager())
            )
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()
        setupUI()
        bindViewModel()
        setupNotifications()
        fetchVideoURL()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // After full-screen presentation, bounds/safe area finalize here.
        if player?.currentItem?.status == .readyToPlay {
            updateVideoSizingForCurrentAsset()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if player?.currentItem?.status == .readyToPlay {
            updateVideoSizingForCurrentAsset()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
        // First time we know bounds, apply initial sizing if ready
        if !didApplyInitialSizing, player?.currentItem?.status == .readyToPlay {
            updateVideoSizingForCurrentAsset()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        teardownPlayer()
    }

    // MARK: - ViewModel
    private func bindViewModel() {
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let self, let msg else { return }
                self.errorModalManager.showError(msg)
                self.viewModel.clearError()
            }
            .store(in: &cancellables)

        viewModel.$videoUrl
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlStr in
                guard let self, let urlStr else { return }
                self.configurePlayer(with: urlStr)
            }
            .store(in: &cancellables)

        viewModel.$isRefreshingUrl
            .receive(on: DispatchQueue.main)
            .sink { refreshing in
                print("🔄 URL refreshing: \(refreshing)")
            }
            .store(in: &cancellables)
    }

    private func fetchVideoURL() {
        viewModel.getVideoUrl()
    }

    // MARK: - Player Setup
    private func configurePlayer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        teardownPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player

        playerLayer?.removeFromSuperlayer()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect // preserve aspect, no cropping
        layer.frame = videoContainerView.bounds
        videoContainerView.layer.insertSublayer(layer, at: 0)
        self.playerLayer = layer

        didApplyInitialSizing = false

        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.onReadyToPlay(item)
            case .failed:
                print("❌ Player failed: \(item.error?.localizedDescription ?? "Unknown error")")
            case .unknown:
                break
            @unknown default: break
            }
        }

        sizeObs = item.observe(\.presentationSize, options: [.new]) { [weak self] _, _ in
            self?.updateVideoSizingForCurrentAsset()
        }
    }

    private func onReadyToPlay(_ item: AVPlayerItem) {
        if let dur = safeSeconds(item.duration) {
            progressSlider.maximumValue = Float(dur)
            updateTimeLabel(current: .zero, duration: item.duration)
        } else {
            progressSlider.maximumValue = 0
            timeLabel.text = "00:00 / --:--"
        }
        updateVideoSizingForCurrentAsset()
        addPeriodicTimeObserverIfNeeded()
    }

    private func addPeriodicTimeObserverIfNeeded() {
        guard timeObserver == nil, let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            self?.updatePlaybackUI(time: t)
        }
    }

    private func teardownPlayer() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        statusObs = nil
        sizeObs = nil
        player?.pause()
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }

    // MARK: - Time Utilities
    private func safeSeconds(_ t: CMTime) -> Double? {
        guard CMTIME_IS_VALID(t), CMTIME_IS_NUMERIC(t) else { return nil }
        let s = CMTimeGetSeconds(t)
        guard s.isFinite else { return nil }
        return s
    }

    private func formatTime(_ t: CMTime) -> String {
        guard let s = safeSeconds(t) else { return "--:--" }
        let total = max(0, Int(s))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - UI Updates
    private func updatePlaybackUI(time: CMTime) {
        if let cur = safeSeconds(time) { progressSlider.value = Float(cur) }
        if let duration = player?.currentItem?.duration {
            updateTimeLabel(current: time, duration: duration)
        }
    }

    private func updateTimeLabel(current: CMTime, duration: CMTime) {
        timeLabel.text = "\(formatTime(current)) / \(formatTime(duration))"
    }

    // MARK: - Actions
    @objc private func playButtonTapped() { togglePlayback() }

    @objc private func videoTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.videoContainerView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) { self.videoContainerView.alpha = 1.0 }
        }
        togglePlayback()
    }

    private func togglePlayback() {
        guard let player else { return }
        if player.rate == 0 {
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.3, delay: 1.0, options: []) { self.playButton.alpha = 0.3 }
        } else {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.2) { self.playButton.alpha = 1.0 }
        }
    }

    @objc private func sliderValueChanged() {
        guard let _ = player?.currentItem else { return }
        guard progressSlider.maximumValue > 0 else { return }
        let target = CMTime(seconds: Double(progressSlider.value), preferredTimescale: 600)
        player?.seek(to: target)
    }

    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSeekToTimestamp),
            name: .seekToTimestamp,
            object: nil
        )
    }

    @objc private func handleSeekToTimestamp(_ note: Notification) {
        guard let ts = note.userInfo?["timestamp"] as? Double else { return }
        seekToTimestamp(ts)
    }

    func seekToTimestamp(_ ts: Double) {
        let target = CMTime(seconds: ts, preferredTimescale: 600)
        player?.seek(to: target)
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    // MARK: - UI Build
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Video Analysis"

        // Video container
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.backgroundColor = .black
        videoContainerView.layer.cornerRadius = 12
        videoContainerView.clipsToBounds = true
        view.addSubview(videoContainerView)

        // Single adjustable height constraint for the video
        let initialVideoH = max(220, view.bounds.height * maxVideoHeightRatio * 0.9)
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(equalToConstant: initialVideoH)

        // Handle between video and metrics (bigger hit area for presented controllers)
        handleContainer.translatesAutoresizingMaskIntoConstraints = false
        handleContainer.isUserInteractionEnabled = true
        view.addSubview(handleContainer)

        handlePill.translatesAutoresizingMaskIntoConstraints = false
        handlePill.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.5)
        handlePill.layer.cornerRadius = 3
        handleContainer.addSubview(handlePill)

        // Pan recognizer configured for coexistence with scroll/nav
        panOnHandle = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panOnHandle.delegate = self
        handleContainer.addGestureRecognizer(panOnHandle)

        // Metrics container + collection view
        metricsContainerView.translatesAutoresizingMaskIntoConstraints = false
        metricsContainerView.backgroundColor = .systemBackground
        view.addSubview(metricsContainerView)

//        if let flow = metricsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            flow.scrollDirection = .vertical
//            flow.minimumInteritemSpacing = 12
//            flow.minimumLineSpacing = 12
//            flow.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
//        }
        metricsTableView.translatesAutoresizingMaskIntoConstraints = false
        metricsTableView.backgroundColor = .clear
        metricsTableView.delegate = self
        metricsTableView.dataSource = self
        metricsTableView.alwaysBounceVertical = true
        metricsTableView.keyboardDismissMode = .onDrag
        metricsTableView.register(StrengthsCardCell.self, forCellReuseIdentifier: "StrengthsCardCell")
        metricsTableView.register(AreasForImprovementCardCell.self, forCellReuseIdentifier: "AreasForImprovementCardCell")
        metricsTableView.register(OverallPerformanceCardCell.self, forCellReuseIdentifier: "OverallPerformanceCardCell")
        metricsContainerView.addSubview(metricsTableView)

        // Video controls
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        playButton.layer.cornerRadius = 25
        playButton.alpha = 1.0
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)

        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        timeLabel.text = "00:00 / 00:00"

        videoContainerView.addSubview(playButton)
        videoContainerView.addSubview(progressSlider)
        videoContainerView.addSubview(timeLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tap)
        videoContainerView.isUserInteractionEnabled = true

        // Constraints
        NSLayoutConstraint.activate([
            // Video box within 20 side margins
            videoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
            videoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            videoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            videoHeightConstraint!,

            // Handle just below video (make it a bit taller to ensure easy hit after presentation)
            handleContainer.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: interSectionSpacing),
            handleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            handleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            handleContainer.heightAnchor.constraint(equalToConstant: 32),

            // Centered pill in the handle
            handlePill.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
            handlePill.centerYAnchor.constraint(equalTo: handleContainer.centerYAnchor),
            handlePill.widthAnchor.constraint(equalToConstant: 44),
            handlePill.heightAnchor.constraint(equalToConstant: 6),

            // Metrics fills the rest
            metricsContainerView.topAnchor.constraint(equalTo: handleContainer.bottomAnchor, constant: interSectionSpacing),
            metricsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metricsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metricsContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Collection view fills metrics container
            metricsTableView.topAnchor.constraint(equalTo: metricsContainerView.topAnchor),
            metricsTableView.leadingAnchor.constraint(equalTo: metricsContainerView.leadingAnchor),
            metricsTableView.trailingAnchor.constraint(equalTo: metricsContainerView.trailingAnchor),
            metricsTableView.bottomAnchor.constraint(equalTo: metricsContainerView.bottomAnchor),

            // Video controls inside video container
            playButton.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalToConstant: 50),

            progressSlider.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: -16),
            progressSlider.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: -16),

            timeLabel.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -8)
        ])

        // Make sure handle sits above everything after presentation
        view.bringSubviewToFront(handleContainer)
    }

    // MARK: - Aspect & Initial Layout Rules
    private func updateVideoSizingForCurrentAsset() {
        guard
            let size = player?.currentItem?.presentationSize,
            size.width > 0, size.height > 0
        else { return }

        let availableWidth = view.bounds.width - (sideMargin * 2)
        let naturalAspect = size.height / size.width // H/W
        let naturalHeightAtMaxWidth = availableWidth * naturalAspect

        let screenH = view.bounds.height
        let maxInitialVideoH = screenH * maxVideoHeightRatio // 50%

        // Portrait (tall) clips that would exceed 50% get capped at 50%.
        // Landscape clips use their natural height at max width (which is < 50%).
        let targetInitialH = min(naturalHeightAtMaxWidth, maxInitialVideoH)
        videoHeightConstraint?.constant = targetInitialH
        view.layoutIfNeeded()

        // Drag enabled only when portrait is capped by 50%.
        let portraitCappedBy50 = naturalHeightAtMaxWidth > maxInitialVideoH
        isDragEnabled = portraitCappedBy50
        handlePill.alpha = isDragEnabled ? 1.0 : 0.3
        panOnHandle.isEnabled = true // keep enabled; we gate in handler

        didApplyInitialSizing = true
    }

    // MARK: - Dragging
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // If we haven’t measured yet, try now (presentation/safe area may have just finalized)
        if player?.currentItem?.presentationSize == .zero || !didApplyInitialSizing {
            updateVideoSizingForCurrentAsset()
        }
        guard isDragEnabled else { return } // locked for landscape clips

        let screenH = view.bounds.height
        let minVideoH = screenH * minVideoHeightRatio   // 25%
        let maxVideoH = screenH * maxVideoHeightRatio   // 50%

        switch gesture.state {
        case .began:
            initialVideoHeightOnPan = videoHeightConstraint?.constant ?? 0

        case .changed:
            let dy = gesture.translation(in: view).y
            // Drag up (dy < 0) -> shrink video (smaller height) -> grow metrics
            var newVideoH = initialVideoHeightOnPan + dy
            newVideoH = max(minVideoH, min(maxVideoH, newVideoH))
            videoHeightConstraint?.constant = newVideoH
            view.layoutIfNeeded()

        case .ended, .cancelled:
            let currentH = videoHeightConstraint?.constant ?? 0
            let snapTarget = (abs(currentH - minVideoH) < abs(currentH - maxVideoH)) ? minVideoH : maxVideoH
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
                self.videoHeightConstraint?.constant = snapTarget
                self.view.layoutIfNeeded()
            }

        default: break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension LessonViewController: UIGestureRecognizerDelegate {
    // Allow the handle pan to coexist with collection view scroll and nav gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panOnHandle
    }
    // Prefer vertical drags on the handle; don’t start if mostly horizontal
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panOnHandle,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: view)
        return abs(v.y) > abs(v.x)
    }
}

// MARK: - UICollectionViewDataSource
extension LessonViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 1
        if viewModel.analysis.strengthsArray?.isEmpty == false {
            numberOfSections += 1
        }
        if viewModel.analysis.areasForImprovementArray?.isEmpty == false {
            numberOfSections += 1
        }
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OverallPerformanceCardCell", for: indexPath) as! OverallPerformanceCardCell
            cell.configure(with: viewModel.analysis)
            return cell
        } else if indexPath.section == 1 {
            if !viewModel.analysis.strengthsArray!.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "StrengthsCardCell", for: indexPath) as! StrengthsCardCell
                cell.configure(with: viewModel.analysis.strengthsArray!)
                return cell
            } else {
                if !viewModel.analysis.areasForImprovementArray!.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AreasForImprovementCardCell", for: indexPath) as! AreasForImprovementCardCell
                    cell.configure(with: viewModel.analysis.areasForImprovementArray!)
                    return cell
                }
            }
        }
            let cell = tableView.dequeueReusableCell(withIdentifier: "AreasForImprovementCardCell", for: indexPath) as! AreasForImprovementCardCell
            cell.configure(with: viewModel.analysis.areasForImprovementArray!)
            return cell
    }
}

// MARK: - UICollectionViewDelegate
extension LessonViewController: UITableViewDelegate {

}

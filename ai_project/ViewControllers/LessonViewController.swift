import UIKit
import AVKit
import AVFoundation
import Combine

final class LessonViewController: UIViewController {

    // MARK: - Section model
    private enum Section { case overview, strengths, areas }
    private var sections: [Section] {
        var s: [Section] = [.overview]
        if let arr = viewModel.analysis.strengthsArray, !arr.isEmpty { s.append(.strengths) }
        if let arr = viewModel.analysis.areasForImprovementArray, !arr.isEmpty { s.append(.areas) }
        return s
    }

    // MARK: - Dependencies
    private let viewModel: LessonViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Player
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var statusObs: NSKeyValueObservation?
    private var sizeObs: NSKeyValueObservation?

    // MARK: - Layout constants
    private let sideMargin: CGFloat = 20
    private let topMargin: CGFloat = 16
    private let gap: CGFloat = 8
    private let minVideoHeightRatio: CGFloat = 0.25 // 25%
    private let maxVideoHeightRatio: CGFloat = 0.50 // 50%

    // MARK: - UI
    private let videoContainerView = UIView()
    private var videoHeightConstraint: NSLayoutConstraint?

    private let videoPlaceholder = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)

    private let handleContainer = UIView()
    private let handlePill = UIView()
    private lazy var panOnHandle = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))

    private let tableContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .grouped) // grouped = non-sticky headers

    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()

    // MARK: - State
    private var initialVideoHeightOnPan: CGFloat = 0
    private var didApplyInitialSizing = false
    private var dragEnabled = false

    // MARK: - Init
    init(analysis: VideoAnalysisObject) {
        self.viewModel = LessonViewModel(
            analysis: analysis,
            repository: VideoAnalysisRepository(analysisAPI: NetworkManager(tokenManager: TokenManager()))
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let timeObserver, let player { player.removeTimeObserver(timeObserver) }
        statusObs = nil; sizeObs = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()
        setupMenu()
        setupUI()
        bindViewModel()
        fetchVideoURL()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
        if !didApplyInitialSizing, player?.currentItem?.status == .readyToPlay {
            updateVideoSizingForCurrentAsset()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if player?.currentItem?.status == .readyToPlay {
            updateVideoSizingForCurrentAsset()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        teardownPlayer()
    }

    // MARK: - ViewModel bind / data
    private func bindViewModel() {
        viewModel.$videoUrl
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlStr in
                guard let self, let urlStr else { return }
                self.configurePlayer(with: urlStr)
            }
            .store(in: &cancellables)
    }

    private func fetchVideoURL() { viewModel.getVideoUrl() }

    // MARK: - Player setup
    private func configurePlayer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        teardownPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player

        // Player layer behind controls; start hidden for a clean crossfade
        playerLayer?.removeFromSuperlayer()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = videoContainerView.bounds
        layer.opacity = 0 // fade in on ready
        videoContainerView.layer.insertSublayer(layer, at: 0)
        self.playerLayer = layer

        // Show placeholder until ready
        videoPlaceholder.isHidden = false
        spinner.startAnimating()
        didApplyInitialSizing = false

        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.onReadyToPlay(item)
            case .failed:
                print("❌ Player failed: \(item.error?.localizedDescription ?? "Unknown error")")
                self.fadeInPlaceholder() // keep placeholder if fail
            case .unknown: break
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

        // Crossfade from placeholder to video
        spinner.stopAnimating()
        UIView.transition(with: videoContainerView, duration: 0.25, options: [.transitionCrossDissolve]) {
            self.videoPlaceholder.isHidden = true
            self.playerLayer?.opacity = 1
        }
    }

    private func addPeriodicTimeObserverIfNeeded() {
        guard timeObserver == nil, let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            self?.updatePlaybackUI(time: t)
        }
    }

    private func teardownPlayer() {
        if let timeObserver, let player { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        statusObs = nil
        sizeObs = nil
        player?.pause()
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Video Analysis"

        // Video container
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.backgroundColor = .black
        videoContainerView.layer.cornerRadius = 12
        videoContainerView.clipsToBounds = true
        view.addSubview(videoContainerView)

        // Placeholder (elegant first paint)
        videoPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        videoPlaceholder.backgroundColor = UIColor.black
        videoPlaceholder.isHidden = false
        videoContainerView.addSubview(videoPlaceholder)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        videoPlaceholder.addSubview(spinner)

        // Initial height guess = 16:9 at available width, capped by 50% screen
        let guessAspect: CGFloat = 9.0 / 16.0
        let availableWidth = view.bounds.width - (sideMargin * 2)
        let guessedH = availableWidth * guessAspect
        let maxH = view.bounds.height * maxVideoHeightRatio
        let initialVideoH = min(max(220, guessedH), maxH)
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(equalToConstant: initialVideoH)

        // Drag handle
        handleContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(handleContainer)

        handlePill.translatesAutoresizingMaskIntoConstraints = false
        handlePill.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.5)
        handlePill.layer.cornerRadius = 3
        handleContainer.addSubview(handlePill)

        panOnHandle.delegate = self
        handleContainer.addGestureRecognizer(panOnHandle)

        // Table (grouped so headers scroll)
        tableContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableContainer)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }

        tableView.register(OverallPerformanceCardCell.self, forCellReuseIdentifier: "OverallPerformanceCardCell")
        tableView.register(StrengthsCardCell.self, forCellReuseIdentifier: "StrengthsCardCell")
        tableView.register(AreasForImprovementCardCell.self, forCellReuseIdentifier: "AreasForImprovementCardCell")

        tableContainer.addSubview(tableView)

        // Video controls
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        playButton.layer.cornerRadius = 25
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

        // Tap-to-toggle
        let tap = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tap)
        videoContainerView.isUserInteractionEnabled = true

        // Constraints
        NSLayoutConstraint.activate([
            // Video
            videoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
            videoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            videoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            videoHeightConstraint!,

            // Placeholder + spinner
            videoPlaceholder.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoPlaceholder.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            videoPlaceholder.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            videoPlaceholder.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: videoPlaceholder.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: videoPlaceholder.centerYAnchor),

            // Handle
            handleContainer.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: gap),
            handleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            handleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            handleContainer.heightAnchor.constraint(equalToConstant: 32),

            handlePill.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
            handlePill.centerYAnchor.constraint(equalTo: handleContainer.centerYAnchor),
            handlePill.widthAnchor.constraint(equalToConstant: 44),
            handlePill.heightAnchor.constraint(equalToConstant: 6),

            // Table container
            tableContainer.topAnchor.constraint(equalTo: handleContainer.bottomAnchor, constant: gap),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Table
            tableView.topAnchor.constraint(equalTo: tableContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: tableContainer.bottomAnchor),

            // Controls inside video
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

        view.bringSubviewToFront(handleContainer)
    }

    // MARK: - Nav buttons

    private func setupMenu() {
        setupOverflowMenu(items: [
            OverflowMenuItem(title: "Share", systemImage: "square.and.arrow.up") { [weak self] in
                guard let self else { return }
                // share flow
            },
            OverflowMenuItem(title: "Save", systemImage: "tray.and.arrow.down") {
                // save
            },
            OverflowMenuItem(title: "Delete", systemImage: "trash", isDestructive: true) {
                Alert(self).danger(
                    titleText: "Delete Analysis",
                    bodyText: "Are you sure you want to delete this analysis? This action is permanent and cannot be undone",
                    buttonText: "Delete")
            }
        ], position: .right)
    }
    
    private func handleDelete() {
        // TODO: your delete logic
        print("🗑️ Delete tapped")
    }

    // MARK: - Playback UI updates
    private func updatePlaybackUI(time: CMTime) {
        if let cur = safeSeconds(time) { progressSlider.value = Float(cur) }
        if let dur = player?.currentItem?.duration { updateTimeLabel(current: time, duration: dur) }
    }
    private func updateTimeLabel(current: CMTime, duration: CMTime) {
        timeLabel.text = "\(formatTime(current)) / \(formatTime(duration))"
    }
    private func safeSeconds(_ t: CMTime) -> Double? {
        guard CMTIME_IS_VALID(t), CMTIME_IS_NUMERIC(t) else { return nil }
        let s = CMTimeGetSeconds(t); return s.isFinite ? s : nil
    }
    private func formatTime(_ t: CMTime) -> String {
        guard let s = safeSeconds(t) else { return "--:--" }
        let total = max(0, Int(s)); return String(format: "%02d:%02d", total/60, total%60)
    }

    // MARK: - Aspect + initial sizing
    private func updateVideoSizingForCurrentAsset() {
        guard let size = player?.currentItem?.presentationSize, size.width > 0, size.height > 0 else { return }
        let availableWidth = view.bounds.width - (sideMargin * 2)
        let aspect = size.height / size.width
        let naturalH = availableWidth * aspect

        let screenH = view.bounds.height
        let cappedH = min(naturalH, screenH * maxVideoHeightRatio) // cap at 50%
        videoHeightConstraint?.constant = cappedH
        view.layoutIfNeeded()

        // Enable drag if portrait exceeded cap
        dragEnabled = naturalH > cappedH
        handlePill.alpha = dragEnabled ? 1.0 : 0.3
        didApplyInitialSizing = true
    }

    private func fadeInPlaceholder() {
        videoPlaceholder.isHidden = false
        playerLayer?.opacity = 0
        spinner.startAnimating()
    }

    // MARK: - Actions
    @objc private func playButtonTapped() { togglePlayback() }
    @objc private func videoTapped() {
        UIView.animate(withDuration: 0.08, animations: { self.videoContainerView.alpha = 0.85 }) {
            _ in UIView.animate(withDuration: 0.08) { self.videoContainerView.alpha = 1.0 }
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
        guard progressSlider.maximumValue > 0, let _ = player?.currentItem else { return }
        let t = CMTime(seconds: Double(progressSlider.value), preferredTimescale: 600)
        player?.seek(to: t)
    }

    // MARK: - Dragging
    @objc private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        if player?.currentItem?.presentationSize == .zero || !didApplyInitialSizing { updateVideoSizingForCurrentAsset() }
        guard dragEnabled else { return }

        let screenH = view.bounds.height
        let minH = screenH * minVideoHeightRatio
        let maxH = screenH * maxVideoHeightRatio

        switch pan.state {
        case .began:
            initialVideoHeightOnPan = videoHeightConstraint?.constant ?? 0
        case .changed:
            let dy = pan.translation(in: view).y
            var newH = initialVideoHeightOnPan + dy
            newH = max(minH, min(maxH, newH))
            videoHeightConstraint?.constant = newH
            view.layoutIfNeeded()
        case .ended, .cancelled:
            let cur = videoHeightConstraint?.constant ?? 0
            let snap = abs(cur - minH) < abs(cur - maxH) ? minH : maxH
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
                self.videoHeightConstraint?.constant = snap
                self.view.layoutIfNeeded()
            }
        default: break
        }
    }

    // MARK: - Notifications (optional seek-to-timestamp)
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSeekToTimestamp), name: .seekToTimestamp, object: nil)
    }
    @objc private func handleSeekToTimestamp(_ note: Notification) {
        guard let ts = note.userInfo?["timestamp"] as? Double else { return }
        let t = CMTime(seconds: ts, preferredTimescale: 600)
        player?.seek(to: t)
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
}

// MARK: - UITableViewDataSource
extension LessonViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .overview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OverallPerformanceCardCell", for: indexPath) as! OverallPerformanceCardCell
            cell.configure(with: viewModel.analysis)
            cell.selectionStyle = .none
            return cell

        case .strengths:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StrengthsCardCell", for: indexPath) as! StrengthsCardCell
            if let s = viewModel.analysis.strengthsArray { cell.configure(with: s) }
            cell.selectionStyle = .none
            return cell

        case .areas:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AreasForImprovementCardCell", for: indexPath) as! AreasForImprovementCardCell
            if let a = viewModel.analysis.areasForImprovementArray { cell.configure(with: a) }
            cell.selectionStyle = .none
            return cell
        }
    }
}

// MARK: - UITableViewDelegate (scrolling headers)
extension LessonViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.text = {
            switch sections[section] {
            case .overview:  return "Overview"
            case .strengths: return "Strengths"
            case .areas:     return "Areas for improvement"
            }
        }()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: sideMargin),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -sideMargin),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 34 }

    // kill grouped footers’ default gap for a “plain” look
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}

// MARK: - Gestures coexistence
extension LessonViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === panOnHandle
    }
}


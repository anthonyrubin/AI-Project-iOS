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

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let videoContainerView = UIView()
    private var videoHeightConstraint: NSLayoutConstraint?

    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let eventsView = UIView()

    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    // MARK: - Init
    init(analysis: VideoAnalysisObject) {
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
        setupUI()
        bindViewModel()
        setupNotifications()
        fetchVideoURL()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeNavBarTransparent(for: self)
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.barTintColor = .white
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
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

        // Clean any old player first
        teardownPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player

        // Layer
        playerLayer?.removeFromSuperlayer()
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(layer)
        layer.frame = videoContainerView.bounds
        self.playerLayer = layer

        // KVO: status + presentationSize (tokens auto-clean on deinit/assignment)
        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.onReadyToPlay(item)
            case .failed:
                print("❌ Player failed: \(item.error?.localizedDescription ?? "Unknown error")")
            case .unknown:
                break
            @unknown default:
                break
            }
        }

        sizeObs = item.observe(\.presentationSize, options: [.new]) { [weak self] _, _ in
            self?.updateVideoAspectRatio()
        }
    }

    private func onReadyToPlay(_ item: AVPlayerItem) {
        // Duration may still be indefinite—guard it.
        if let dur = safeSeconds(item.duration) {
            progressSlider.maximumValue = Float(dur)
            updateTimeLabel(current: .zero, duration: item.duration)
        } else {
            progressSlider.maximumValue = 0
            timeLabel.text = "00:00 / --:--"
        }

        updateVideoAspectRatio()
        addPeriodicTimeObserverIfNeeded()
    }

    private func addPeriodicTimeObserverIfNeeded() {
        guard timeObserver == nil, let player = player else { return }
        // 600 is a common timescale for smooth UI updates
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
        if let cur = safeSeconds(time) {
            progressSlider.value = Float(cur)
        }
        if let duration = player?.currentItem?.duration {
            updateTimeLabel(current: time, duration: duration)
        }
    }

    private func updateTimeLabel(current: CMTime, duration: CMTime) {
        timeLabel.text = "\(formatTime(current)) / \(formatTime(duration))"
    }

    private func updateVideoAspectRatio() {
        guard let size = player?.currentItem?.presentationSize,
              size.width > 0, size.height > 0 else { return }
        let aspect = size.height / size.width

        videoHeightConstraint?.isActive = false
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(
            equalTo: videoContainerView.widthAnchor,
            multiplier: aspect
        )
        videoHeightConstraint?.isActive = true

        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - Actions
    @objc private func playButtonTapped() { togglePlayback() }

    @objc private func videoTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.videoContainerView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.videoContainerView.alpha = 1.0
            }
        }
        togglePlayback()
    }

    private func togglePlayback() {
        guard let player else { return }
        if player.rate == 0 {
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.3, delay: 1.0, options: []) {
                self.playButton.alpha = 0.3
            }
        } else {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.2) { self.playButton.alpha = 1.0 }
        }
    }

    @objc private func sliderValueChanged() {
        guard let _ = player?.currentItem else { return }
        guard progressSlider.maximumValue > 0 else { return } // ignore seeks until duration known
        let target = CMTime(seconds: Double(progressSlider.value), preferredTimescale: 600)
        player?.seek(to: target)
    }

    // MARK: - Notifications (seeking to event timestamps)
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

        // Scroll + content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Video container
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.backgroundColor = .black
        videoContainerView.layer.cornerRadius = 12
        videoContainerView.clipsToBounds = true
        contentView.addSubview(videoContainerView)

        // default 16:9 height; will update when we know presentationSize
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(
            equalTo: videoContainerView.widthAnchor, multiplier: 9.0 / 16.0
        )

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            videoHeightConstraint!
        ])

        // Tap to toggle
        let tap = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tap)
        videoContainerView.isUserInteractionEnabled = true

        // Play button
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        playButton.layer.cornerRadius = 25
        playButton.alpha = 1.0
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)

        // Slider
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        timeLabel.text = "00:00 / 00:00"

        videoContainerView.addSubview(playButton)
        videoContainerView.addSubview(progressSlider)
        videoContainerView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
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

        // Events list container
        eventsView.layer.borderWidth = 1
        eventsView.layer.cornerRadius = 12
        eventsView.layer.borderColor = UIColor.systemGray.cgColor
        eventsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventsView)

        NSLayoutConstraint.activate([
            eventsView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 20),
            eventsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            eventsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        // Build event rows if you already have them loaded
        buildEvents()
    }

    private func buildEvents() {
        var previous: UIView?
        for (idx, analysisEvent) in viewModel.analysisEvents.enumerated() {
            let el = EventElement()
            el.onTap = { [weak self] in
                self?.viewModel.seekToTimestamp(analysisEvent.timestamp)
            }
            el.configure(with: analysisEvent)

            eventsView.addSubview(el)
            el.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                el.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor),
                el.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor)
            ])

            if let prev = previous {
                el.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 20).isActive = true
            } else {
                el.topAnchor.constraint(equalTo: eventsView.topAnchor, constant: 20).isActive = true
            }

            if idx == viewModel.analysisEvents.count - 1 {
                el.bottomAnchor.constraint(equalTo: eventsView.bottomAnchor, constant: -20).isActive = true
            }

            previous = el
        }
    }
}

// MARK: - EventElement (unchanged API; safe to reuse)
final class EventElement: UIView {
    private let timestampLabel = UILabel()
    private let eventLabel = UILabel()
    private let feedbackLabel = UILabel()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame); setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear

        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        timestampLabel.textColor = .systemBlue
        timestampLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        timestampLabel.layer.cornerRadius = 8
        timestampLabel.clipsToBounds = true
        timestampLabel.textAlignment = .center

        eventLabel.translatesAutoresizingMaskIntoConstraints = false
        eventLabel.font = .systemFont(ofSize: 16, weight: .medium)
        eventLabel.textColor = .label
        eventLabel.numberOfLines = 0

        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.font = .systemFont(ofSize: 14)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0

        addSubview(timestampLabel)
        addSubview(eventLabel)
        addSubview(feedbackLabel)

        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            timestampLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timestampLabel.widthAnchor.constraint(equalToConstant: 60),
            timestampLabel.heightAnchor.constraint(equalToConstant: 30),

            eventLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 12),
            eventLabel.topAnchor.constraint(equalTo: topAnchor),
            eventLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            feedbackLabel.leadingAnchor.constraint(equalTo: eventLabel.leadingAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 4),
            feedbackLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            feedbackLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        timestampLabel.isUserInteractionEnabled = true
        timestampLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTimestampTap))
        )
    }

    func configure(with event: AnalysisEventObject) {
        timestampLabel.text = formatTimestamp(event.timestamp)
        eventLabel.text = event.label.capitalized
        feedbackLabel.text = event.feedback
    }

    @objc private func handleTimestampTap() { onTap?() }

    private func formatTimestamp(_ t: Double) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

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
    private var metricsContainerHeightConstraint: NSLayoutConstraint?

    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    
    // New metrics grid
    private let metricsCollectionView: UICollectionView
    private let metricsContainerView = UIView()
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private var initialMetricsHeight: CGFloat = 0
    private let minVideoHeightRatio: CGFloat = 0.25 // 25% of screen height
    private let maxVideoHeightRatio: CGFloat = 0.5  // 50% of screen height

    private lazy var errorModalManager = ErrorModalManager(viewController: self)

    // MARK: - Init
    init(analysis: VideoAnalysisObject) {
        // Setup collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        self.metricsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
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

        // Default height constraint - will be updated based on video aspect ratio
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(
            equalTo: view.heightAnchor, multiplier: maxVideoHeightRatio
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

        // Metrics container
        metricsContainerView.translatesAutoresizingMaskIntoConstraints = false
        metricsContainerView.backgroundColor = .systemBackground
        contentView.addSubview(metricsContainerView)
        
        // Collection view
        metricsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        metricsCollectionView.backgroundColor = .clear
        metricsCollectionView.delegate = self
        metricsCollectionView.dataSource = self
        metricsCollectionView.register(MetricGridCell.self, forCellWithReuseIdentifier: "MetricGridCell")
        metricsContainerView.addSubview(metricsCollectionView)
        
        // Pan gesture for resizing
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        metricsContainerView.addGestureRecognizer(panGestureRecognizer)
        
        // Initial height constraint
        metricsContainerHeightConstraint = metricsContainerView.heightAnchor.constraint(
            equalTo: view.heightAnchor, multiplier: 1.0 - maxVideoHeightRatio
        )
        
        NSLayoutConstraint.activate([
            metricsContainerView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 8),
            metricsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metricsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            metricsContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            metricsContainerHeightConstraint!,
            
            metricsCollectionView.topAnchor.constraint(equalTo: metricsContainerView.topAnchor),
            metricsCollectionView.leadingAnchor.constraint(equalTo: metricsContainerView.leadingAnchor),
            metricsCollectionView.trailingAnchor.constraint(equalTo: metricsContainerView.trailingAnchor),
            metricsCollectionView.bottomAnchor.constraint(equalTo: metricsContainerView.bottomAnchor)
        ])

        // Metrics will be loaded automatically via collection view data source
    }

    
    // MARK: - Gesture Handling
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            initialMetricsHeight = metricsContainerView.frame.height
            
        case .changed:
            let newHeight = initialMetricsHeight - translation.y
            let screenHeight = view.frame.height
            let minHeight = screenHeight * minVideoHeightRatio
            let maxHeight = screenHeight * (1.0 - minVideoHeightRatio)
            
            let clampedHeight = max(minHeight, min(maxHeight, newHeight))
            let videoHeight = screenHeight - clampedHeight
            
            // Update constraints
            videoHeightConstraint?.constant = videoHeight - view.safeAreaInsets.top - 16
            metricsContainerHeightConstraint?.constant = clampedHeight
            
            // Update video aspect ratio if needed
            if let playerLayer = playerLayer {
                let videoSize = playerLayer.videoRect.size
                if videoSize.width > 0 && videoSize.height > 0 {
                    let aspectRatio = videoSize.height / videoSize.width
                    let newVideoHeight = videoContainerView.frame.width * aspectRatio
                    videoHeightConstraint?.constant = newVideoHeight
                }
            }
            
        case .ended, .cancelled:
            // Snap to nearest ratio
            let screenHeight = view.frame.height
            let currentRatio = metricsContainerView.frame.height / screenHeight
            
            let targetRatio: CGFloat
            if currentRatio < 0.4 {
                targetRatio = minVideoHeightRatio
            } else {
                targetRatio = maxVideoHeightRatio
            }
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.metricsContainerHeightConstraint?.constant = screenHeight * (1.0 - targetRatio)
                self.videoHeightConstraint?.constant = screenHeight * targetRatio - self.view.safeAreaInsets.top - 16
                self.view.layoutIfNeeded()
            }
            
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDataSource
extension LessonViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.analysis.metricsBreakdownDict?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricGridCell", for: indexPath) as! MetricGridCell
        
        if let metricsBreakdown = viewModel.analysis.metricsBreakdownDict {
            let metricNames = Array(metricsBreakdown.keys)
            if indexPath.item < metricNames.count {
                let metricName = metricNames[indexPath.item]
                let metricData = metricsBreakdown[metricName]!
                cell.configure(with: metricName, metricBreakdown: metricData)
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension LessonViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if let metricsBreakdown = viewModel.analysis.metricsBreakdownDict {
            let metricNames = Array(metricsBreakdown.keys)
            if indexPath.item < metricNames.count {
                let metricName = metricNames[indexPath.item]
                let metricData = metricsBreakdown[metricName]!
                
                let metricVC = MetricViewController(metricName: metricName, metricBreakdown: metricData)
                navigationController?.pushViewController(metricVC, animated: true)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LessonViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 12
        let availableWidth = collectionView.frame.width - (padding * 2) - spacing
        let cellWidth = availableWidth / 2
        let cellHeight: CGFloat = 140 // Fixed height for consistency
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

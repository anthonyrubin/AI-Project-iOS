import UIKit
import AVKit
import AVFoundation
import RealmSwift
import Combine

class LessonViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: LessonViewModel
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let iconView = UIImageView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let videoContainerView = UIView()
    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let eventsView = UIView()

    //private let eventsTableView = UITableView()
    private var videoHeightConstraint: NSLayoutConstraint?
    private lazy var errorModalManager = ErrorModalManager(viewController: self)
    
    // MARK: - Initialization
    init(analysis: VideoAnalysisObject) {
        self.viewModel = LessonViewModel(
            analysis: analysis,
            repository: VideoAnalysisRepository(
                analysisAPI: NetworkManager(tokenManager: TokenManager())
            )
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModelBindings()
        setupVideoPlayer()
        setupEventsView()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setBackgroundGradient()
        makeNavBarTransparent(for: self)
        
        // Ensure tab bar has correct background
        tabBarController?.tabBar.backgroundColor = .white
        tabBarController?.tabBar.barTintColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBackgroundGradient()
        playerLayer?.frame = videoContainerView.bounds
    }
    
    // MARK: - ViewModel Bindings
    
    private func setupViewModelBindings() {
        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorModalManager.showError(errorMessage)
                    self?.viewModel.clearError()
                }
            }
            .store(in: &cancellables)
        
        // Bind video URL changes
        viewModel.$videoUrl
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videoUrl in
                if let videoUrl = videoUrl {
                    self?.setupVideoPlayerWithUrl(videoUrl)
                }
            }
            .store(in: &cancellables)
        
        // Bind URL refresh state
        viewModel.$isRefreshingUrl
            .receive(on: DispatchQueue.main)
            .sink { isRefreshing in
                // Could show loading indicator for URL refresh
                print("🔄 LessonViewController: URL refresh state changed to: \(isRefreshing)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Video Aspect Ratio Management
    private func updateVideoAspectRatio() {
        guard let playerItem = player?.currentItem else { return }
        let videoSize = playerItem.presentationSize
        guard videoSize.width > 0 && videoSize.height > 0 else {
            return
        }
        let aspectRatio = videoSize.height / videoSize.width

        // Update the height constraint with the correct aspect ratio
        videoHeightConstraint?.isActive = false
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(equalTo: videoContainerView.widthAnchor, multiplier: aspectRatio)
        videoHeightConstraint?.isActive = true
        
        // Animate the constraint change
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        
        // Remove observers safely
        if let playerItem = player?.currentItem {
            playerItem.removeObserver(self, forKeyPath: "status")
            playerItem.removeObserver(self, forKeyPath: "presentationSize")
        }
    }
    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
//        return viewModel.getEventsCount()
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
//        
//        if let event = viewModel.getEvent(at: indexPath.row) {
//            cell.configure(with: event)
//        }
//        
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        
//        if let event = viewModel.getEvent(at: indexPath.row) {
//            viewModel.seekToTimestamp(event.timestamp)
//        }
//    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Video Analysis"
        
        setupScrollView()
        setupVideoContainer()
        setupPlaybackControls()
    }
    
    private func setupScrollView() {
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
    }
    
    private func setupVideoContainer() {
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.backgroundColor = .black
        videoContainerView.layer.cornerRadius = 12
        videoContainerView.clipsToBounds = true
        
        // Add tap gesture recognizer for play/pause functionality
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
        videoContainerView.isUserInteractionEnabled = true
        
        contentView.addSubview(videoContainerView)
        
        // Create a default 16:9 aspect ratio constraint that we'll update later
        videoHeightConstraint = videoContainerView.heightAnchor.constraint(equalTo: videoContainerView.widthAnchor, multiplier: 9.0/16.0)
        
        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            videoHeightConstraint!
        ])
    }
    
    private func setupPlaybackControls() {
        // Play button
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        playButton.layer.cornerRadius = 25
        playButton.alpha = 1.0 // Ensure it's visible initially
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // Progress slider
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
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
    }
    
    // MARK: - Video Player Setup
    private func setupVideoPlayer() {
        // Trigger video URL fetch - the binding will handle the response
        viewModel.getVideoUrl()
    }
    
    private func setupVideoPlayerWithUrl(_ urlString: String) {
        guard let videoUrl = URL(string: urlString) else {
            return
        }
        
        let player = AVPlayer(url: videoUrl)
        setupPlayerLayer(with: player)
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updatePlaybackUI(time: time)
        }
        
        // Store references for cleanup
        self.player = player
        self.timeObserver = timeObserver
        
        // Add observer for when video is ready to play
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Add observer for video size changes
        player.currentItem?.addObserver(self, forKeyPath: "presentationSize", options: [.new, .old], context: nil)
    }
    
    private func setupPlayerLayer(with player: AVPlayer) {
        playerLayer?.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(playerLayer!)
        
        // Set initial frame
        playerLayer?.frame = videoContainerView.bounds
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    progressSlider.maximumValue = Float(CMTimeGetSeconds(item.duration))
                    updateTimeLabel(current: .zero, duration: item.duration)
                    
                    // Update aspect ratio when video is ready
                    updateVideoAspectRatio()
                case .failed:
                    // TODO: Log this
                    print("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    // TODO: Log this
                    break
                @unknown default:
                    // TODO: Log this
                    break
                }
            }
        } else if keyPath == "presentationSize" {
            // Update aspect ratio when video size changes
            updateVideoAspectRatio()
        }
    }

    
    // MARK: - Playback Controls
    @objc private func playButtonTapped() {
        togglePlayback()
    }
    
    @objc private func videoTapped() {
        // Add visual feedback
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
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // Animate play button fade out
            UIView.animate(withDuration: 0.3, delay: 1.0, options: [], animations: {
                self.playButton.alpha = 0.3
            })
        } else {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            
            // Show play button when paused
            UIView.animate(withDuration: 0.2) {
                self.playButton.alpha = 1.0
            }
        }
    }
    
    @objc private func sliderValueChanged() {
        guard (player?.currentItem?.duration) != nil else { return }
        let targetTime = CMTime(seconds: Double(progressSlider.value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: targetTime)
    }
    
    private func updatePlaybackUI(time: CMTime) {
        let currentSeconds = CMTimeGetSeconds(time)
        progressSlider.value = Float(currentSeconds)
        
        guard let duration = player?.currentItem?.duration else { return }
        updateTimeLabel(current: time, duration: duration)
    }
    
    private func updateTimeLabel(current: CMTime, duration: CMTime) {
        let currentString = formatTime(current)
        let durationString = formatTime(duration)
        timeLabel.text = "\(currentString) / \(durationString)"
    }
    
    private func formatTime(_ time: CMTime) -> String {
        let seconds = CMTimeGetSeconds(time)
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
    
    @objc private func handleSeekToTimestamp(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let timestamp = userInfo["timestamp"] as? Double else { return }
        
        seekToTimestamp(timestamp)
    }
    
    // MARK: - Video Seeking
    func seekToTimestamp(_ timestamp: Double) {
        let targetTime = CMTime(seconds: timestamp, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: targetTime)
        
        // Resume playback if it was playing
        if player?.rate == 0 {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    func setupEventsView() {
        
        eventsView.layer.borderWidth = 1
        eventsView.layer.cornerRadius = 12
        eventsView.layer.borderColor = UIColor.systemGray.cgColor
        
        contentView.addSubview(eventsView)
        eventsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            eventsView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 20),
            eventsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            eventsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        var analysisEventElements: [EventElement] = []
        
        
        for (index, analysisEvent) in viewModel.analysisEvents.enumerated() {
            let eventElement = EventElement()
            eventElement.onTap = { [weak self] in
                self?.viewModel.seekToTimestamp(analysisEvent.timestamp)
            }
            eventElement.configure(with: analysisEvent)
            analysisEventElements.append(eventElement)
            
            eventsView.addSubview(eventElement)
            eventElement.translatesAutoresizingMaskIntoConstraints = false
                    
            NSLayoutConstraint.activate([
                eventElement.leadingAnchor.constraint(equalTo: eventsView.leadingAnchor),
                eventElement.trailingAnchor.constraint(equalTo: eventsView.trailingAnchor),
            ])
            
            if index == 0 {
                NSLayoutConstraint.activate([
                    eventElement.topAnchor.constraint(equalTo: eventsView.topAnchor, constant: 20),
                ])
            } else {
                NSLayoutConstraint.activate([
                    eventElement.topAnchor.constraint(equalTo: analysisEventElements[index-1].bottomAnchor, constant: 20),
                ])
            }
            
            
            if (index == viewModel.analysisEvents.count - 1) {
                NSLayoutConstraint.activate([
                    eventElement.bottomAnchor.constraint(equalTo: eventsView.bottomAnchor, constant: -20),
                ])
            }
        }
    }
}

// MARK: - Event Table View Cell
class EventElement: UIView {
    private let timestampLabel = UILabel()
    private let eventLabel = UILabel()
    private let feedbackLabel = UILabel()
    private var event: AnalysisEventObject?
    var onTap: (() -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Timestamp label
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        timestampLabel.textColor = .systemBlue
        timestampLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        timestampLabel.layer.cornerRadius = 8
        timestampLabel.clipsToBounds = true
        timestampLabel.textAlignment = .center
        
        // Event label
        eventLabel.translatesAutoresizingMaskIntoConstraints = false
        eventLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        eventLabel.textColor = .label
        eventLabel.numberOfLines = 0
        
        // Feedback label
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.font = UIFont.systemFont(ofSize: 14)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        
        addSubview(timestampLabel)
        addSubview(eventLabel)
        addSubview(feedbackLabel)
        
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            timestampLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            timestampLabel.widthAnchor.constraint(equalToConstant: 60),
            timestampLabel.heightAnchor.constraint(equalToConstant: 30),
            
            eventLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 12),
            eventLabel.topAnchor.constraint(equalTo: self.topAnchor),
            eventLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            
            feedbackLabel.leadingAnchor.constraint(equalTo: eventLabel.leadingAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 4),
            feedbackLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            feedbackLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor)
        ])
    }
    
    func configure(with event: AnalysisEventObject) {
        timestampLabel.text = formatTimestamp(event.timestamp)
        eventLabel.text = event.label.capitalized
        feedbackLabel.text = event.feedback
        
        timestampLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTimestampTap))
        timestampLabel.addGestureRecognizer(tap)
    }
    
    @objc func handleTimestampTap() {
        onTap?()
    }
    
    private func formatTimestamp(_ timestamp: Double) -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

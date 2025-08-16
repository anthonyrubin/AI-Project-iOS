import UIKit
import AVKit
import AVFoundation
import RealmSwift

class LessonViewController: UIViewController {
    
    // MARK: - Properties
    private let analysis: VideoAnalysisObject
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let videoContainerView = UIView()
    private let playButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let timeLabel = UILabel()
    private let analysisStackView = UIStackView()
    private let eventsTableView = UITableView()
    private var videoHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(analysis: VideoAnalysisObject) {
        self.analysis = analysis
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideoPlayer()
        setupAnalysisData()
        setupEventsTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavBarHairline()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }
    
    // MARK: - Video Aspect Ratio Management
    private func updateVideoAspectRatio() {
        guard let playerItem = player?.currentItem else { return }
        
        let videoSize = playerItem.presentationSize
        guard videoSize.width > 0 && videoSize.height > 0 else { 
            print("📐 Video size not available yet, using default 16:9")
            return 
        }
        
        let aspectRatio = videoSize.height / videoSize.width
        print("📐 Video size: \(videoSize), Aspect ratio: \(aspectRatio)")
        
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
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Video Analysis"
        
        setupScrollView()
        setupVideoContainer()
        setupPlaybackControls()
        setupAnalysisStackView()
        setupEventsTable()
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
    
    private func setupAnalysisStackView() {
        analysisStackView.translatesAutoresizingMaskIntoConstraints = false
        analysisStackView.axis = .vertical
        analysisStackView.spacing = 16
        analysisStackView.alignment = .fill
        
        contentView.addSubview(analysisStackView)
        
        NSLayoutConstraint.activate([
            analysisStackView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 24),
            analysisStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            analysisStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupEventsTable() {
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
        eventsTableView.backgroundColor = .clear
        eventsTableView.separatorStyle = .none
        eventsTableView.isScrollEnabled = false // Let scroll view handle scrolling
        
        contentView.addSubview(eventsTableView)
        
        NSLayoutConstraint.activate([
            eventsTableView.topAnchor.constraint(equalTo: analysisStackView.bottomAnchor, constant: 24),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            eventsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            eventsTableView.heightAnchor.constraint(equalToConstant: CGFloat(analysis.events.count * 80)) // Approximate height
        ])
    }
    
    // MARK: - Video Player Setup
    private func setupVideoPlayer() {
        guard let video = analysis.video else {
            print("❌ No video object found")
            return
        }
        
        setupVideoPlayerWithUrl(video.signedVideoUrl)
    }
    
    private func setupVideoPlayerWithUrl(_ urlString: String) {
        guard let videoUrl = URL(string: urlString) else {
            print("❌ Invalid video URL")
            return
        }
        
        player = AVPlayer(url: videoUrl)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            videoContainerView.layer.addSublayer(playerLayer)
            playerLayer.frame = videoContainerView.bounds
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updatePlaybackUI(time: time)
        }
        
        // Add observer for when video is ready to play
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Add observer for video size changes
        player?.currentItem?.addObserver(self, forKeyPath: "presentationSize", options: [.new, .old], context: nil)
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
                    print("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        } else if keyPath == "presentationSize" {
            // Update aspect ratio when video size changes
            updateVideoAspectRatio()
        }
    }
    
    // MARK: - Analysis Data Setup
    private func setupAnalysisData() {
        // Add video info section
        if let video = analysis.video {
            var videoInfo = "Filename: \(video.originalFilename)\n"
            videoInfo += "File size: \(formatFileSize(video.fileSize))\n"
            
            if video.hasDuration {
                videoInfo += "Duration: \(video.formattedDuration)"
            } else {
                videoInfo += "Duration: Unknown"
            }
            
            addSection(title: "Video Information", content: videoInfo)
        }
        
        guard let analysisData = analysis.analysisDataDict else {
            addSection(title: "Analysis", content: "Analysis data not available")
            return
        }
        
        // Overall Assessment
        if let overallAssessment = analysisData["overall_assessment"] as? String {
            addSection(title: "Overall Assessment", content: overallAssessment)
        }
        
        // Key Observations
        if let keyObservations = analysisData["key_observations"] as? [String] {
            addSection(title: "Key Observations", content: keyObservations.joined(separator: "\n• "))
        }
        
        // Technique Analysis
        if let techniqueAnalysis = analysisData["technique_analysis"] as? [String: Any] {
            var techniqueContent = ""
            
            if let strengths = techniqueAnalysis["strengths"] as? [String] {
                techniqueContent += "Strengths:\n• " + strengths.joined(separator: "\n• ") + "\n\n"
            }
            
            if let improvements = techniqueAnalysis["areas_for_improvement"] as? [String] {
                techniqueContent += "Areas for Improvement:\n• " + improvements.joined(separator: "\n• ") + "\n\n"
            }
            
            if let feedback = techniqueAnalysis["specific_feedback"] as? [String] {
                techniqueContent += "Specific Feedback:\n• " + feedback.joined(separator: "\n• ")
            }
            
            if !techniqueContent.isEmpty {
                addSection(title: "Technique Analysis", content: techniqueContent)
            }
        }
        
        // Recommendations
        if let recommendations = analysisData["recommendations"] as? [String] {
            addSection(title: "Recommendations", content: recommendations.joined(separator: "\n• "))
        }
        
        // Safety Considerations
        if let safety = analysisData["safety_considerations"] as? [String] {
            addSection(title: "Safety Considerations", content: safety.joined(separator: "\n• "))
        }
    }
    
    private func addSection(title: String, content: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        
        analysisStackView.addArrangedSubview(titleLabel)
        analysisStackView.addArrangedSubview(contentLabel)
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
}

// MARK: - UITableViewDataSource
extension LessonViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("📊 LessonViewController: Found \(analysis.events.count) events")
        print("📊 Analysis data: \(analysis.analysisData)")
        if let analysisDataDict = analysis.analysisDataDict {
            print("📊 Parsed analysis data keys: \(analysisDataDict.keys)")
            if let events = analysisDataDict["events"] as? [[String: Any]] {
                print("📊 Raw events count: \(events.count)")
                for (index, event) in events.enumerated() {
                    print("📊 Event \(index + 1): \(event)")
                }
            }
        }
        return analysis.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
        
        let event = analysis.events[indexPath.row]
        cell.configure(with: event)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LessonViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let event = analysis.events[indexPath.row]
        seekToTimestamp(event.timestamp)
    }
}

// MARK: - Event Table View Cell
class EventTableViewCell: UITableViewCell {
    private let timestampLabel = UILabel()
    private let eventLabel = UILabel()
    private let feedbackLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
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
        eventLabel.numberOfLines = 2
        
        // Feedback label
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.font = UIFont.systemFont(ofSize: 14)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 2
        
        contentView.addSubview(timestampLabel)
        contentView.addSubview(eventLabel)
        contentView.addSubview(feedbackLabel)
        
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timestampLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timestampLabel.widthAnchor.constraint(equalToConstant: 60),
            timestampLabel.heightAnchor.constraint(equalToConstant: 30),
            
            eventLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: 12),
            eventLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            eventLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            feedbackLabel.leadingAnchor.constraint(equalTo: eventLabel.leadingAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: 4),
            feedbackLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            feedbackLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with event: AnalysisEventObject) {
        timestampLabel.text = formatTimestamp(event.timestamp)
        eventLabel.text = event.label
        feedbackLabel.text = event.feedback
    }
    
    private func formatTimestamp(_ timestamp: Double) -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

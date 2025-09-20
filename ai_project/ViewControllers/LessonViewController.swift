import UIKit
import AVKit
import AVFoundation
import Combine

// UIView backed by AVPlayerLayer
private final class PlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

final class LessonViewController: UIViewController {

    // MARK: - Sections
    private enum Section { case overview, strengths, areas }
    private var sections: [Section] {
        var s: [Section] = [.overview]
        if let a = viewModel.analysis.strengthsArray, !a.isEmpty { s.append(.strengths) }
        if let a = viewModel.analysis.areasForImprovementArray, !a.isEmpty { s.append(.areas) }
        return s
    }

    // MARK: - Deps
    private let viewModel: LessonViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Player
    private var player: AVPlayer?
    private var statusObs: NSKeyValueObservation?
    private var sizeObs: NSKeyValueObservation?

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .grouped)

    // Header (frame-based)
    private let headerContainer = UIView()
    private let playerView = PlayerView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let playButton = UIButton(type: .system)
    private let fullscreenButton = UIButton(type: .system)

    // Layout state
    private var headerSetUp = false
    private var lastHeaderWidth: CGFloat = 0
    private var pendingAspectSize: CGSize? = nil  // from presentationSize
    
    private let chatButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Chat with Coach", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.tintColor = .white
        b.layer.cornerRadius = 10
        return b
    }()

    // MARK: - Init
    init(analysis: VideoAnalysisObject) {
        self.viewModel = LessonViewModel(
            analysis: analysis,
            repository: VideoAnalysisRepository(analysisAPI: NetworkManager(tokenManager: TokenManager()))
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { teardownPlayer() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupCloseButton(position: .left)
        super.viewDidLoad()
        setupTable()
        setupHeaderViews()     // configure subviews (no autolayout)
        bindViewModel()
        fetchVideoURL()
        setupChatButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.window != nil else { return }
        let width = tableView.bounds.width
        if !headerSetUp || abs(width - lastHeaderWidth) > 0.5 {
            lastHeaderWidth = width
            applyHeaderFrame(forWidth: width)  // sets tableHeaderView with frame
        } else {
            // keep player filling current header on rotations
            playerView.frame = headerContainer.bounds
            layoutControls()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }

    // MARK: - Table
    private func setupTable() {
        view.backgroundColor = .systemBackground
        title = "Video Analysis"

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none

        // Match background to avoid “black bars” outside the video
        tableView.backgroundColor = view.backgroundColor
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }

        tableView.register(OverallPerformanceCardCell.self, forCellReuseIdentifier: "OverallPerformanceCardCell")
        tableView.register(StrengthsCardCell.self, forCellReuseIdentifier: "StrengthsCardCell")
        tableView.register(AreasForImprovementCardCell.self, forCellReuseIdentifier: "AreasForImprovementCardCell")

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupChatButton() {
        view.addSubview(chatButton)
        chatButton.addTarget(self, action: #selector(startChat), for: .touchUpInside)

        NSLayoutConstraint.activate([
            chatButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chatButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            chatButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // let tableView stop above button
        tableView.bottomAnchor.constraint(equalTo: chatButton.topAnchor, constant: -8).isActive = true
    }

    // MARK: - Header subviews (frame-based, no Auto Layout)
    private func setupHeaderViews() {
        // Make header match table bg so side areas don’t look like bars
        headerContainer.backgroundColor = tableView.backgroundColor

        playerView.backgroundColor = .clear     // only video shows
        playerView.clipsToBounds = true
        headerContainer.addSubview(playerView)

        spinner.hidesWhenStopped = true
        playerView.addSubview(spinner)

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        playButton.layer.cornerRadius = 28
        playButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        playerView.addSubview(playButton)

        fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        fullscreenButton.tintColor = .white
        fullscreenButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        fullscreenButton.layer.cornerRadius = 16
        fullscreenButton.addTarget(self, action: #selector(openFullscreen), for: .touchUpInside)
        playerView.addSubview(fullscreenButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePlayback))
        playerView.addGestureRecognizer(tap)
    }

    // MARK: - Header layout using frames (preserve aspect, no cropping)
    private func applyHeaderFrame(forWidth width: CGFloat) {
        let maxH = max(120, view.bounds.height * 0.20)

        // Defaults before we know aspect
        var headerH = maxH
        var videoW = width
        var videoH = headerH

        if let s = pendingAspectSize, s.width > 0, s.height > 0 {
            let aspect = s.width / s.height           // W/H
            let fullWidthNaturalH = width / aspect    // height if we used full width

            if fullWidthNaturalH <= maxH {
                // Landscape / not-too-tall: full width, natural height (<= 20%)
                videoW = width
                videoH = max(120, fullWidthNaturalH)
                headerH = videoH
            } else {
                // Portrait / very tall: cap height at 20%, shrink width to keep aspect (no cropping)
                videoH = maxH
                videoW = videoH * aspect
                headerH = maxH
            }
        }

        // Size header and player
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: headerH)
        // Center horizontally if narrower than table
        let videoX = (width - videoW) * 0.5
        playerView.frame = CGRect(x: videoX, y: 0, width: videoW, height: videoH)

        // Video always preserves aspect, no cropping
        playerView.playerLayer.videoGravity = .resizeAspect

        // Place controls inside the video bounds
        layoutControls()

        // Assign/update table header
        tableView.tableHeaderView = headerContainer
        headerSetUp = true
    }

    private func layoutControls() {
        // Controls sit ON the video, not the side area
        spinner.center = CGPoint(x: playerView.bounds.midX, y: playerView.bounds.midY)

        playButton.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        playButton.center = spinner.center

        fullscreenButton.frame = CGRect(x: playerView.bounds.maxX - 32 - 12,
                                        y: playerView.bounds.maxY - 32 - 12,
                                        width: 32, height: 32)

        // Ensure on top
        playerView.bringSubviewToFront(spinner)
        playerView.bringSubviewToFront(playButton)
        playerView.bringSubviewToFront(fullscreenButton)
    }

    // MARK: - ViewModel / Data
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

    // MARK: - Player
    private func configurePlayer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        teardownPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        self.playerView.player = player
        self.playerView.playerLayer.videoGravity = .resizeAspect

        spinner.startAnimating()

        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                self.spinner.stopAnimating()

                let s = item.presentationSize
                if s.width > 0, s.height > 0 {
                    self.pendingAspectSize = s
                    if self.view.window != nil {
                        self.applyHeaderFrame(forWidth: self.tableView.bounds.width)
                    }
                }

                // Nudge to render first frame
                self.player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    self.player?.play()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        self.player?.pause()
                    }
                }
            }
        }

        sizeObs = item.observe(\.presentationSize, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            let s = item.presentationSize
            if s.width > 0, s.height > 0 {
                self.pendingAspectSize = s
                if self.view.window != nil {
                    self.applyHeaderFrame(forWidth: self.tableView.bounds.width)
                }
            }
        }
    }

    private func teardownPlayer() {
        statusObs = nil
        sizeObs = nil
        player?.pause()
        playerView.player = nil
        player = nil
    }

    // MARK: - Actions
    @objc private func togglePlayback() {
        guard let player else { return }
        if player.rate == 0 {
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            UIView.animate(withDuration: 0.25) { self.playButton.alpha = 0.35 }
        } else {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            UIView.animate(withDuration: 0.15) { self.playButton.alpha = 1.0 }
        }
    }

    @objc private func openFullscreen() {
        guard let player else { return }
        let vc = AVPlayerViewController()
        vc.player = player
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func startChat() {
        let vc = BasicChatViewController()
        navigationController?.pushViewController(vc, animated: true)
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

// MARK: - UITableViewDelegate
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
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 34 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}


import UIKit
import MessageKit
import InputBarAccessoryView

final class BasicChatViewController: MessagesViewController {

    private let me = Sender(senderId: "user", displayName: "You")
    private let coach = Sender(senderId: "coach", displayName: "CoachCam AI")

    private var messages: [MessageType] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.isHidden = true // we just want to show a static message for now

        // seed initial message
        let first = MockMessage(text: "Let’s talk about your deadlift video.",
                                user: coach,
                                messageId: UUID().uuidString,
                                date: Date())
        messages.append(first)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }
}

// MARK: - MessageKit boilerplate

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct MockMessage: MessageType {
    var text: String
    var user: Sender
    var messageId: String
    var date: Date

    var sender: SenderType { user }
    var sentDate: Date { date }
    var kind: MessageKind { .text(text) }
}

extension BasicChatViewController: MessagesDataSource {
    var currentSender: any MessageKit.SenderType {
        me
    }
    func numberOfSections(in _: MessagesCollectionView) -> Int { messages.count }
    func messageForItem(at indexPath: IndexPath, in _: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
}

extension BasicChatViewController: MessagesLayoutDelegate {
    func avatarSize(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> CGSize { .zero }
}

extension BasicChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .systemBlue : .secondarySystemBackground
    }
    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .white : .label
    }
}

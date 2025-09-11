import UIKit

// MARK: - Step badge
final class StepBadgeView: UIView {
    private let label = UILabel()
    var isActive: Bool = false { didSet { update() } }

    init(number: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(number)"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .center
        addSubview(label)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 32),
            heightAnchor.constraint(equalToConstant: 32),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        layer.cornerRadius = 16
        layer.masksToBounds = true
        update()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func update() {
        if isActive {
            backgroundColor = .label
            label.textColor = .systemBackground
        } else {
            backgroundColor = .secondarySystemBackground
            label.textColor = .secondaryLabel
        }
    }
}

// MARK: - Cell that hosts an arbitrary step view
final class StepCell: UICollectionViewCell {
    private var hosted: UIView?

    func setView(_ view: UIView) {
        hosted?.removeFromSuperview()
        hosted = view
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hosted?.removeFromSuperview()
        hosted = nil
    }
}

// MARK: - Single VC implementation
final class UploadInstructionsViewController: UIViewController,
                                             UICollectionViewDataSource,
                                             UICollectionViewDelegate,
                                             UIScrollViewDelegate {

    // Provide views (one per step). Replace placeholders with your real content views.
    private let stepViews: [UIView]

    // Called when last step's button is tapped
    var onFinish: (() -> Void)?

    // UI
    private let closeButton = UIButton(type: .system)
    private let stepStack   = UIStackView()
    private var badges: [StepBadgeView] = []

    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let bottomButton = UIButton(type: .system)

    // State
    private var currentIndex: Int = 0

    // MARK: Init
    convenience init() {
        // Placeholder content boxes to prove the layout; swap with your own views later.
        func box(_ text: String) -> UIView {
            let wrapper = UIView()
            let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = .tertiarySystemFill; v.layer.cornerRadius = 16
            let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false
            l.text = text; l.font = .systemFont(ofSize: 22, weight: .semibold); l.textAlignment = .center
            wrapper.addSubview(v); v.addSubview(l)
            NSLayoutConstraint.activate([
                v.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 24),
                v.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -24),
                v.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
                v.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -8),
                l.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                l.centerYAnchor.constraint(equalTo: v.centerYAnchor)
            ])
            return wrapper
        }
        self.init(steps: [box("Step 1 content"), box("Step 2 content"), box("Step 3 content")])
    }

    init(steps: [UIView]) {
        self.stepViews = steps
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildHeader()
        buildCollection()
        buildBottomButton()
        updateUI(for: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure full-width paging
        layout.itemSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }

    // MARK: Build UI
    private func buildHeader() {
        // Close
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.applyTactileTap()

        // Badges
        stepStack.translatesAutoresizingMaskIntoConstraints = false
        stepStack.axis = .horizontal
        stepStack.spacing = 12
        stepStack.alignment = .center
        badges = (0..<stepViews.count).map { StepBadgeView(number: $0 + 1) }
        badges.forEach { stepStack.addArrangedSubview($0) }

        view.addSubview(closeButton)
        view.addSubview(stepStack)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            stepStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stepStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        ])
    }

    private func buildCollection() {
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.register(StepCell.self, forCellWithReuseIdentifier: "cell")

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100) // space for button
        ])
    }

    private func buildBottomButton() {
        bottomButton.translatesAutoresizingMaskIntoConstraints = false
        bottomButton.setTitle("Next", for: .normal)
        bottomButton.setTitleColor(.white, for: .normal)
        bottomButton.backgroundColor = .black
        bottomButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        bottomButton.layer.cornerRadius = 26
        bottomButton.contentEdgeInsets = UIEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        bottomButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        bottomButton.applyTactileTap()

        view.addSubview(bottomButton)
        NSLayoutConstraint.activate([
            bottomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bottomButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }

    // MARK: Actions
    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func nextTapped() {
        if currentIndex < stepViews.count - 1 {
            currentIndex += 1
            scrollToCurrent(animated: true)
        } else {
            onFinish?()
            dismiss(animated: true)
        }
        updateUI(for: currentIndex)
    }

    // MARK: Collection DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stepViews.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StepCell
        cell.setView(stepViews[indexPath.item])
        return cell
    }

    // MARK: Paging sync
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { syncIndexFromScroll() }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { syncIndexFromScroll() }
    }

    private func syncIndexFromScroll() {
        let page = Int(round(collectionView.contentOffset.x / max(collectionView.bounds.width, 1)))
        if page != currentIndex {
            currentIndex = page
            updateUI(for: page)
        }
    }

    private func scrollToCurrent(animated: Bool) {
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0),
                                    at: .centeredHorizontally,
                                    animated: animated)
    }

    private func updateUI(for index: Int) {
        for (i, b) in badges.enumerated() { b.isActive = (i == index) }
        let isLast = index == stepViews.count - 1
        bottomButton.setTitle(isLast ? "Upload Workout" : "Next", for: .normal)
    }
}

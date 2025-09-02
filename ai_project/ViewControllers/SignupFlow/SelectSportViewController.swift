import UIKit

// MARK: - ViewController
final class SelectSportViewController: BaseSignupTableViewController {

    private var items: [LeftSFIconCellData] = []
    private var sports: [Sport] = []

    private var selectedItem: Sport?   // ← single selection

    override func viewDidLoad() {
        setData()
        super.viewDidLoad()
        setProgress(0.09, animated: false)
        updateContinueState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.cascadeReset()                 // reset state & reload
        tableView.cascadePrepareInitialIfNeeded()// prep icon cells BEFORE screen is shown (no flash)
        // Kick the cascade exactly with the nav transition (instant start)
        tableView.cascadeRunInitialIfNeeded(coordinator: transitionCoordinator)
    }
    
    override func setupTable() {
        super.setupTable()
        tableView.dataSource = self
        tableView.enableCascade(delegate: self)
        tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.register(LeftSFIconCell.self, forCellReuseIdentifier: LeftSFIconCell.reuseID)
        tableView.allowsMultipleSelection = false
    }

    private func updateContinueState() {
        let enabled = (selectedItem != nil)
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.4
    }
    
    override func didTapContinue() {
        super.didTapContinue()
        UserDefaultsManager.shared.updateGoals(sport: selectedItem!.rawValue)
        let vc = GoalsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setData() {
        Sport.allCases.forEach({ sport in
            items.append(LeftSFIconCellData(
                title: sport.rawValue.capitalized,
                iconName: sport.data().icon))
            sports.append(sport)
        })
    }
}

// MARK: - Data Source & Delegate
extension SelectSportViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "What sport are you here for?",
                subtitle: "Pick one to start. You can change add more any time.",
                fontSize: 35
            )
            return cell
        }
        let item = items[indexPath.row]
        let sport = sports[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: LeftSFIconCell.reuseID, for: indexPath) as! LeftSFIconCell
        cell.configure(item, selected: selectedItem == sport)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        firePressHaptic()
        tableView.deselectRow(at: indexPath, animated: false)

        let tapped = sports[indexPath.row]

        if selectedItem == tapped {
            // tap again to clear (optional—keeps UX flexible)
            selectedItem = nil
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(false, animated: true)
            }
        } else {
            // turn off previous
            if let prev = selectedItem, let prevRow = sports.firstIndex(of: prev) {
                let prevPath = IndexPath(row: prevRow, section: 1)
                if let prevCell = tableView.cellForRow(at: prevPath) as? LeftSFIconCell {
                    prevCell.setSelectedAppearance(false, animated: true)
                } else {
                    tableView.reloadRows(at: [prevPath], with: .none)
                }
            }
            // select new
            selectedItem = sports[indexPath.row]
            if let cell = tableView.cellForRow(at: indexPath) as? LeftSFIconCell {
                cell.setSelectedAppearance(true, animated: true)
            }
        }

        updateContinueState()
    }
}




import UIKit
import AVFoundation

/// Scans a base image and reveals a matching overlay from top→bottom with a red line.
/// - Corner radius applies to the *image content only* (not the letterbox areas).
/// - Scan line width matches the *image content* width.
/// - Linear timing.
final class LoadingScannerView: UIView {

    // MARK: - Public API

    /// Set/replace images. They should be aligned and same aspect.
    func setImages(base: UIImage, overlay: UIImage) {
        baseImage = base
        overlayImage = overlay
        baseImageView.image = base
        overlayImageView.image = overlay
        setNeedsLayout()
    }

    /// Corner radius on the actual image content (contentView), not the letterbox.
    var contentCornerRadius: CGFloat = 0 {
        didSet {
            contentView.layer.cornerRadius = contentCornerRadius
            contentView.layer.masksToBounds = contentCornerRadius > 0
            if #available(iOS 13.0, *) { contentView.layer.cornerCurve = .continuous }
        }
    }

    /// Which corners to round on the image content.
    var maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] {
        didSet { contentView.layer.maskedCorners = maskedCorners }
    }

    /// Start the scan (linear). Safe to call before layout; it will defer.
    func startScan(duration: TimeInterval = 2.0) {
        layoutIfNeeded()
        let h = overlayImageView.bounds.height
        let w = overlayImageView.bounds.width
        if h <= 0 || w <= 0 {
            pendingScanDuration = max(0.25, duration)
            return
        }
        runScan(duration: max(0.25, duration))
    }

    /// Instantly reveal everything; parks the line at the bottom.
    func revealImmediately() {
        cancelAnimations()
        overlayImageView.isHidden = false
        overlayImageView.layer.mask = overlayMask

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayMask.anchorPoint = CGPoint(x: 0, y: 0)
        overlayMask.position = .zero
        overlayMask.bounds = overlayImageView.bounds
        ensureScanLinePathWidth(overlayImageView.bounds.width)
        scanLine.position = CGPoint(x: 0, y: overlayImageView.bounds.height)
        scanLine.isHidden = false
        CATransaction.commit()
    }

    /// Hide overlay + line and clear masks.
    func reset() {
        cancelAnimations()
        overlayImageView.layer.mask = nil
        overlayImageView.isHidden = true
        scanLine.isHidden = true
        pendingScanDuration = nil
    }

    // MARK: - Init

    init(base: UIImage, overlay: UIImage) {
        self.baseImage = base
        self.overlayImage = overlay
        super.init(frame: .zero)
        commonInit()
        setImages(base: base, overlay: overlay)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Private

    private var baseImage: UIImage?
    private var overlayImage: UIImage?

    /// Holds exactly the *image content* area (aspect-fit rect). Corner radius is applied here.
    private let contentView = UIView()

    private let baseImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        // We size contentView to the exact aspect-fit rect, so fill is safe.
        iv.contentMode = .scaleToFill
        return iv
    }()

    private let overlayImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleToFill
        iv.isHidden = true
        return iv
    }()

    private let overlayMask: CALayer = {
        let l = CALayer()
        // Mask uses alpha. Opaque fill reveals; transparent hides.
        l.backgroundColor = UIColor.white.cgColor
        // Kill implicit easing on mask changes.
        l.actions = ["bounds": NSNull(), "position": NSNull(), "frame": NSNull()]
        return l
    }()

    private let scanLine: CAShapeLayer = {
        let l = CAShapeLayer()
        l.strokeColor = UIColor.red.cgColor
        l.lineWidth = 4
        l.lineDashPattern = [8, 6] // remove for solid
        l.isHidden = true
        l.actions = ["position": NSNull(), "bounds": NSNull(), "path": NSNull()]
        return l
    }()

    private var pendingScanDuration: TimeInterval?

    private func commonInit() {
        isOpaque = false

        // contentView will be sized to the image's aspect-fit rect inside self.bounds
        addSubview(contentView)
        contentView.layer.masksToBounds = contentCornerRadius > 0

        // Fill contentView with the two image views
        contentView.addSubview(baseImageView)
        contentView.addSubview(overlayImageView)

        baseImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            baseImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            baseImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            baseImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            baseImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Put the scan line in the overlay's coordinate space (same as image content).
        overlayImageView.layer.addSublayer(scanLine)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Compute the aspect-fit rect of the base image inside self.bounds.
        // If base is nil, fall back to overlay.
        let imgSize = baseImage?.size ?? overlayImage?.size ?? .zero
        var fitted = bounds
        if imgSize != .zero {
            fitted = AVMakeRect(aspectRatio: imgSize, insideRect: bounds)
        }

        // Place contentView to exactly match the visible image area.
        contentView.frame = fitted

        // Keep the overlay mask width equal to the image content width when active.
        if overlayImageView.layer.mask === overlayMask {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            overlayMask.bounds.size.width = contentView.bounds.width
            CATransaction.commit()
        }

        // Ensure scan line spans the *image* width, not the letterbox.
        ensureScanLinePathWidth(contentView.bounds.width)

        // If we deferred scanning until we had bounds, run it now.
        if let d = pendingScanDuration,
           contentView.bounds.width > 0,
           contentView.bounds.height > 0 {
            pendingScanDuration = nil
            runScan(duration: d)
        }
    }

    private func runScan(duration d: TimeInterval) {
        cancelAnimations()

        overlayImageView.isHidden = false
        overlayImageView.layer.mask = overlayMask
        scanLine.isHidden = false

        let w = contentView.bounds.width
        let h = contentView.bounds.height

        // Final model-layer state (no implicit animations)
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Mask grows DOWN from the top-left of the image content
        overlayMask.anchorPoint = CGPoint(x: 0, y: 0)
        overlayMask.position = .zero
        overlayMask.bounds = CGRect(x: 0, y: 0, width: w, height: h)

        ensureScanLinePathWidth(w)
        scanLine.position = CGPoint(x: 0, y: h) // final Y at bottom of image content

        CATransaction.commit()

        // Explicit linear animations
        let maskAnim = CABasicAnimation(keyPath: "bounds.size.height")
        maskAnim.fromValue = 0
        maskAnim.toValue = h
        maskAnim.duration = d
        maskAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        maskAnim.fillMode = .forwards
        maskAnim.isRemovedOnCompletion = false
        overlayMask.add(maskAnim, forKey: "reveal")

        let lineAnim = CABasicAnimation(keyPath: "position.y")
        lineAnim.fromValue = 0
        lineAnim.toValue = h
        lineAnim.duration = d
        lineAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        lineAnim.fillMode = .forwards
        lineAnim.isRemovedOnCompletion = false
        scanLine.add(lineAnim, forKey: "move")
    }

    private func ensureScanLinePathWidth(_ width: CGFloat) {
        let p = UIBezierPath()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: width, y: 0))
        scanLine.path = p.cgPath
    }

    private func cancelAnimations() {
        overlayMask.removeAllAnimations()
        scanLine.removeAllAnimations()
    }
}

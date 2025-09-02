import UIKit
import ObjectiveC

import UIKit
import ObjectiveC

// ============================================================================
// MARK: - TableCascadeAnimator
// ============================================================================

/// Drives a one-time "cascade" entrance animation for table view rows and a
/// lighter entrance for rows that appear later while scrolling.
///
/// This class does **not** override or swizzle anything. It is a simple engine
/// invoked by a delegate proxy. You decide **when** to:
///   1) *prepare* the initial visible cells (set them to an off-screen state)
///   2) *run* the cascade (animate those prepared cells)
///   3) animate rows that appear later while scrolling
///
/// Typical lifecycle wiring (through the UITableView extension below):
/// - `viewDidLoad`
///     - `tableView.enableCascade(delegate: self)`
///     - `tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }`
/// - `viewWillAppear`
///     - `tableView.cascadeReset()`
///     - `tableView.cascadePrepareInitialIfNeeded()`
///     - `tableView.cascadeRunInitialIfNeeded(coordinator: transitionCoordinator)`
///
/// Notes:
/// - Only cells for which `shouldAnimateCell` returns true will be animated.
/// - Non-matching cells are never faded or transformed. They stay visible.
/// - The cascade is intended to start *during the navigation transition* for an
///   "instant" feel. Pass `transitionCoordinator` into `runInitialIfNeeded(using:)`.
final class TableCascadeAnimator {

    // -----------------------------
    // MARK: Public configuration
    // -----------------------------

    /// The table view to animate. Held weakly to avoid retain cycles.
    weak var tableView: UITableView?

    /// Predicate used to decide which cells participate in the animation.
    /// Set this to something like `{ $0 is LeftSFIconCell }`.
    /// Default: animate all cells.
    var shouldAnimateCell: (UITableViewCell) -> Bool = { _ in true }

    /// Per-row additional delay for the initial cascade (in seconds).
    /// Row `i` starts at `rowDelay * i`.
    var rowDelay: TimeInterval = 0.06

    /// Duration for each row in the initial cascade (in seconds).
    var initialDuration: TimeInterval = 0.50

    /// Duration for rows that appear later due to scrolling (in seconds).
    var scrollInDuration: TimeInterval = 0.30

    /// Vertical offset (points) applied at the start (positive = below final).
    /// The cell will translate from this offset up to 0 during the animation.
    var startTranslationY: CGFloat = 20

    /// Starting scale applied to the cell content. 0.96 means a subtle "grow in."
    var startScale: CGFloat = 0.80

    /// Spring damping for the animation. 1 = critically damped (no oscillation).
    var damping: CGFloat = 0.90

    /// Initial spring velocity. Small positive value adds a bit of "snap."
    var velocity: CGFloat = 0.15

    // -----------------------------
    // MARK: Private state
    // -----------------------------

    /// True after we have prepared the initial visible cells (alpha 0, transform).
    private var didPrepInitial = false

    /// True after the initial cascade was scheduled and run.
    private var didRunInitial = false

    /// Tracks which index paths have been animated already (initial or scroll-in).
    /// Prevents re-animating the same row on reuse or reloads in place.
    private var animated = Set<IndexPath>()

    // -----------------------------
    // MARK: Init
    // -----------------------------

    /// - Parameter tableView: The table view whose rows will be animated.
    init(tableView: UITableView) {
        self.tableView = tableView
    }

    // -----------------------------
    // MARK: Public control
    // -----------------------------

    /// Resets all animation state and reloads the table.
    ///
    /// Call this in `viewWillAppear` so a returned-to screen can run a fresh
    /// cascade again. This ensures:
    /// - initial prep will occur again on currently visible rows
    /// - initial cascade will schedule again
    /// - previously animated index paths are cleared
    func reset() {
        didPrepInitial = false
        didRunInitial = false
        animated.removeAll()
        tableView?.reloadData()
    }

    /// Prepares **only** the currently visible rows that should animate by
    /// putting them into the "pre-animation" state (alpha 0, small scale, slight
    /// downward translation).
    ///
    /// You typically call this in `viewWillAppear` or `viewWillLayoutSubviews`.
    /// It runs `layoutIfNeeded()` to ensure the table has valid visible rows and
    /// then applies the pre-animation state to those rows.
    ///
    /// Safe to call multiple times; it runs once.
    func prepareInitialIfNeeded() {
        guard let tv = tableView, !didPrepInitial else { return }
        tv.layoutIfNeeded()

        for ip in tv.indexPathsForVisibleRows ?? [] {
            if let cell = tv.cellForRow(at: ip), shouldAnimateCell(cell) {
                prep(cell)
            }
        }
        didPrepInitial = true
    }

    /// Starts the initial top-to-bottom cascade by animating the rows that were
    /// prepared in `prepareInitialIfNeeded()`.
    ///
    /// Pass the navigation `transitionCoordinator` to start **alongside** the push
    /// or pop transition. If the coordinator is `nil`, the animations start
    /// immediately.
    ///
    /// - Parameter coordinator: The current view controller transition coordinator,
    ///   usually `transitionCoordinator` from your view controller.
    ///
    /// This method also gracefully handles the scenario where `prepareInitialIfNeeded`
    /// was not called yet (rare). In that case it prepares the visible rows
    /// synchronously in the same run loop turn and then animates them, which avoids
    /// a "flash" frame.
    func runInitialIfNeeded(using coordinator: UIViewControllerTransitionCoordinator?) {
        guard let tv = tableView, !didRunInitial else { return }
        tv.layoutIfNeeded()

        let visible = tv.indexPathsForVisibleRows ?? []

        // Safety: if prepare step was skipped, do it now to avoid any flash.
        if !didPrepInitial {
            for ip in visible {
                if let c = tv.cellForRow(at: ip), shouldAnimateCell(c) { prep(c) }
            }
            didPrepInitial = true
        }

        // Sort by Y so the cascade appears top-to-bottom regardless of index order.
        let ordered = visible.sorted { tv.rectForRow(at: $0).minY < tv.rectForRow(at: $1).minY }

        let animateBlock = { [weak self] in
            guard let self = self else { return }
            for (i, ip) in ordered.enumerated() {
                guard let c = tv.cellForRow(at: ip), self.shouldAnimateCell(c) else { continue }
                UIView.animate(
                    withDuration: self.initialDuration,
                    delay: self.rowDelay * Double(i),
                    usingSpringWithDamping: self.damping,
                    initialSpringVelocity: self.velocity,
                    options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
                    animations: { self.finish(c) },
                    completion: nil
                )
                self.animated.insert(ip)
            }
        }

        if let co = coordinator {
            // Start exactly when the navigation transition starts.
            co.animate(alongsideTransition: { _ in animateBlock() }, completion: nil)
        } else {
            animateBlock()
        }

        didRunInitial = true
    }

    /// Animates a row that becomes visible later due to scrolling.
    ///
    /// Call from `tableView(_:willDisplay:forRowAt:)`. This will:
    /// - ignore cells that do not match `shouldAnimateCell`
    /// - ignore rows that have already been animated
    /// - apply the pre-animation state immediately and then animate to the final state
    ///
    /// - Parameters:
    ///   - cell: The cell that will be displayed.
    ///   - indexPath: Index path for that cell.
    func willDisplay(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard shouldAnimateCell(cell) else { return }
        guard !animated.contains(indexPath) else { return }

        prep(cell)

        UIView.animate(
            withDuration: scrollInDuration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: { self.finish(cell) },
            completion: nil
        )

        animated.insert(indexPath)
    }

    // -----------------------------
    // MARK: Internal helpers
    // -----------------------------

    /// Applies the pre-animation visual state to a cell's content:
    /// - alpha = 0
    /// - small downward translation
    /// - slight scale down
    /// - rasterization on during animation (performance)
    ///
    /// This targets `contentView` so UIKit's selection/highlight overlays are not affected.
    private func prep(_ cell: UITableViewCell) {
        let v = cell.contentView
        v.alpha = 0
        v.transform = CGAffineTransform(translationX: 0, y: startTranslationY)
            .scaledBy(x: startScale, y: startScale)
        v.layer.shouldRasterize = true
        v.layer.rasterizationScale = UIScreen.main.scale
    }

    /// Restores a cell's content to the final visual state:
    /// - alpha = 1
    /// - identity transform
    /// - rasterization off (crisp text after animation)
    private func finish(_ cell: UITableViewCell) {
        let v = cell.contentView
        v.alpha = 1
        v.transform = .identity
        v.layer.shouldRasterize = false
    }
}


// ============================================================================
// MARK: - CascadingTableDelegateProxy
// ============================================================================

/// A lightweight `UITableViewDelegate` proxy that:
/// - forwards delegate calls to your real delegate
/// - injects the cascade "scroll-in" animation by handling `willDisplay`
/// - exposes lifecycle hooks to `reset`, `prepare`, and `run` the initial cascade
///
/// The proxy does **not** interfere with any other delegate methods. It only
/// intercepts `willDisplay` to add the animation and forwards the call to your
/// original delegate afterward.
///
/// Usage via extension:
///     tableView.enableCascade(delegate: self)
///     tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }
///     tableView.cascadeReset()
///     tableView.cascadePrepareInitialIfNeeded()
///     tableView.cascadeRunInitialIfNeeded(coordinator: transitionCoordinator)
final class CascadingTableDelegateProxy: NSObject, UITableViewDelegate {

    /// The real delegate to forward to after injecting animation behavior.
    weak var forward: (NSObjectProtocol & UITableViewDelegate)?

    /// The animation engine.
    let animator: TableCascadeAnimator

    /// - Parameters:
    ///   - tableView: Table view to animate.
    ///   - forward: Your existing delegate (usually `self` from your VC).
    init(tableView: UITableView, forward: (NSObjectProtocol & UITableViewDelegate)?) {
        self.animator = TableCascadeAnimator(tableView: tableView)
        self.forward = forward
        super.init()
    }

    // MARK: Lifecycle hooks you call from your VC

    /// Clears animation state and reloads the table. Call in `viewWillAppear`.
    func resetForAppearance() { animator.reset() }

    /// Prepares initial visible rows (alpha 0, transform). Call in `viewWillAppear`
    /// or `viewWillLayoutSubviews`.
    func prepareInitialIfNeeded() { animator.prepareInitialIfNeeded() }

    /// Runs the initial cascade. Pass the view controller’s `transitionCoordinator`
    /// to start animations alongside the push/pop transition for instant feel.
    func runInitialIfNeeded(using coordinator: UIViewControllerTransitionCoordinator?) {
        animator.runInitialIfNeeded(using: coordinator)
    }

    // MARK: Baked-in scroll-in animation

    /// Injected handler: animate rows that appear later during scrolling.
    /// This calls your original delegate afterward to keep your behavior intact.
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        animator.willDisplay(cell, at: indexPath)
        forward?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }

    // MARK: Forwarding for all other delegate methods

    /// Report that we respond to selectors our forward target responds to.
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return forward?.responds(to: aSelector) ?? false
    }

    /// Forward unhandled selectors to the real delegate.
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        (forward?.responds(to: aSelector) == true) ? forward : super.forwardingTarget(for: aSelector)
    }
}


// ============================================================================
// MARK: - UITableView + Cascade convenience
// ============================================================================

private var kCascadeProxyKey: UInt8 = 0

extension UITableView {

    /// Associated proxy stored on the table view. Retained for the life of the table.
    private var cascadeProxy: CascadingTableDelegateProxy? {
        get { objc_getAssociatedObject(self, &kCascadeProxyKey) as? CascadingTableDelegateProxy }
        set { objc_setAssociatedObject(self, &kCascadeProxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Installs the delegate proxy that injects cascade behavior and forwards to
    /// your real delegate.
    ///
    /// Call this once per screen, typically in `viewDidLoad`, **instead of**
    /// setting `tableView.delegate = self`.
    ///
    /// Example:
    ///     tableView.dataSource = self
    ///     tableView.enableCascade(delegate: self)
    ///
    /// After enabling, you should:
    ///     tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }
    ///     // In viewWillAppear:
    ///     tableView.cascadeReset()
    ///     tableView.cascadePrepareInitialIfNeeded()
    ///     tableView.cascadeRunInitialIfNeeded(coordinator: transitionCoordinator)
    func enableCascade(delegate: (NSObjectProtocol & UITableViewDelegate)) {
        let proxy = CascadingTableDelegateProxy(tableView: self, forward: delegate)
        self.cascadeProxy = proxy
        self.delegate = proxy
    }

    /// Configures which cells should animate. Set this once per screen.
    ///
    /// Example:
    ///     tableView.cascadeShouldAnimateCell = { $0 is LeftSFIconCell }
    var cascadeShouldAnimateCell: ((UITableViewCell) -> Bool)? {
        get { cascadeProxy?.animator.shouldAnimateCell }
        set { if let newValue = newValue { cascadeProxy?.animator.shouldAnimateCell = newValue } }
    }

    /// Clears state and reloads the table so the cascade can run fresh.
    /// Call in `viewWillAppear`.
    func cascadeReset() { cascadeProxy?.resetForAppearance() }

    /// Prepares the initial visible rows (alpha 0 + transform) **before** the screen is visible.
    /// Call in `viewWillAppear` or `viewWillLayoutSubviews`.
    func cascadePrepareInitialIfNeeded() { cascadeProxy?.prepareInitialIfNeeded() }

    /// Starts the initial cascade. Pass your VC’s `transitionCoordinator` to align
    /// with the navigation transition for an instant start.
    func cascadeRunInitialIfNeeded(coordinator: UIViewControllerTransitionCoordinator?) {
        cascadeProxy?.runInitialIfNeeded(using: coordinator)
    }

    // -----------------------------
    // MARK: Tunable passthroughs
    // -----------------------------

    /// Per-row additional delay for the initial cascade.
    var cascadeRowDelay: TimeInterval {
        get { cascadeProxy?.animator.rowDelay ?? 0.06 }
        set { cascadeProxy?.animator.rowDelay = newValue }
    }

    /// Duration for each row in the initial cascade.
    var cascadeInitialDuration: TimeInterval {
        get { cascadeProxy?.animator.initialDuration ?? 0.5 }
        set { cascadeProxy?.animator.initialDuration = newValue }
    }

    /// Duration for rows that appear later due to scrolling.
    var cascadeScrollInDuration: TimeInterval {
        get { cascadeProxy?.animator.scrollInDuration ?? 0.3 }
        set { cascadeProxy?.animator.scrollInDuration = newValue }
    }

    /// Starting vertical offset for animated rows (points).
    var cascadeStartTranslationY: CGFloat {
        get { cascadeProxy?.animator.startTranslationY ?? 12 }
        set { cascadeProxy?.animator.startTranslationY = newValue }
    }

    /// Starting scale for animated rows.
    var cascadeStartScale: CGFloat {
        get { cascadeProxy?.animator.startScale ?? 0.96 }
        set { cascadeProxy?.animator.startScale = newValue }
    }

    /// Spring damping for the animations.
    var cascadeDamping: CGFloat {
        get { cascadeProxy?.animator.damping ?? 0.9 }
        set { cascadeProxy?.animator.damping = newValue }
    }

    /// Initial spring velocity.
    var cascadeVelocity: CGFloat {
        get { cascadeProxy?.animator.velocity ?? 0.15 }
        set { cascadeProxy?.animator.velocity = newValue }
    }
}

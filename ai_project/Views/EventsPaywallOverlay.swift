import UIKit

// =======================================================
// MARK: EventsPaywallOverlay (view)
// =======================================================

/// Overlay that hides everything *after a pixel cutoff* inside a card.
/// The overlay has two vertical regions:
///  1) A top scrim (transparent → white) to softly fade out underlying content.
///  2) A solid-white block that contains a lock + message.
///
/// HOW TO USE (pixel-based cutoff):
///  - Add this overlay as a subview of your card (e.g., eventsView).
///  - Pin overlay.leading/trailing/bottom to the card.
///  - Keep a reference to the overlay's TOP constraint and set its `constant` to the
///    **cutoff in points** (the amount of content you want to leave visible at the top).
///  - Separately, make sure the *card’s height* is:  cutoff + requiredOverlayHeight(for: cardWidth)
///    so the scrim + lock/message have room to render below the cutoff.
///
/// NOTES:
///  - The overlay itself doesn’t decide the cutoff—YOU pass the pixel amount via the top constraint.
///  - `requiredOverlayHeight(for:)` guarantees the lock/message are fully below the faded region.
///  - The overlay never darkens content (it fades to white).
final class EventsPaywallOverlay: UIView {

    // MARK: - Public knobs

    /// Clear gap (pts) before the scrim fade starts.
    /// Increase if you want a bit of fully-clear area right under your cutoff.
    var clearHeadroom: CGFloat = 8 { didSet { scrimTop.constant = clearHeadroom } }

    /// Height (pts) of the fade from clear → white.
    var fadeHeight: CGFloat = 80 { didSet { scrimHeight.constant = fadeHeight } }

    /// Minimum overall height for the overlay (scrim + solid block).
    var minOverlayHeight: CGFloat = 200

    /// Bottom padding (pts) from the message to the overlay’s bottom.
    var bottomMargin: CGFloat = 30 { didSet { stackBottom?.constant = -bottomMargin } }

    /// Horizontal text padding (pts) inside the solid block.
    var horizontalPadding: CGFloat = 20 {
        didSet {
            content.layoutMargins = UIEdgeInsets(
                top: 0, left: horizontalPadding, bottom: bottomMargin, right: horizontalPadding
            )
        }
    }

    // MARK: - Subviews

    private let scrim = FadeScrimView()   // transparent → white gradient
    private let content = UIView()        // solid white region for lock/message
    let lockLabel = UILabel()
    let textLabel = UILabel()
    private let stack = UIStackView()

    // MARK: - Adjustable constraints (internal)

    private var scrimTop: NSLayoutConstraint!
    private var scrimHeight: NSLayoutConstraint!
    private var stackBottom: NSLayoutConstraint?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }

    // MARK: - Build

    private func build() {
        backgroundColor = .clear

        // Scrim
        scrim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)

        // Solid content
        content.backgroundColor = .white
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        // Lock + message stack
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false

        lockLabel.text = "🔒"
        lockLabel.font = .systemFont(ofSize: 42, weight: .regular)
        lockLabel.textAlignment = .center

        textLabel.text = "Unlock the full timestamped analysis of your performance."
        textLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        textLabel.textAlignment = .center
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        content.addSubview(stack)
        stack.addArrangedSubview(lockLabel)
        stack.addArrangedSubview(textLabel)
        content.layoutMargins = UIEdgeInsets(top: 0, left: horizontalPadding, bottom: bottomMargin, right: horizontalPadding)

        // Constraints (internal)
        scrimTop = scrim.topAnchor.constraint(equalTo: topAnchor, constant: clearHeadroom)
        scrimHeight = scrim.heightAnchor.constraint(equalToConstant: fadeHeight)
        stackBottom = stack.bottomAnchor.constraint(equalTo: content.layoutMarginsGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            // Scrim spans width; top/height adjustable via knobs
            scrimTop,
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrimHeight,

            // Solid content fills below scrim down to bottom
            content.topAnchor.constraint(equalTo: scrim.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Center stack; wrap by margins; honor bottom padding
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: content.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.layoutMarginsGuide.trailingAnchor),
            stackBottom!
        ])
    }

    // MARK: - Sizing

    /// Calculates how tall the overlay must be (scrim + solid) for a given width.
    /// Use this to size the *card* height:  cardHeight = cutoff (pts visible) + requiredOverlayHeight(for: width)
    func requiredOverlayHeight(for width: CGFloat) -> CGFloat {
        let textWidth = max(0, width - 2 * horizontalPadding)
        let lockH = lockLabel.intrinsicContentSize.height
        let textH = textLabel.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        let contentH = lockH + 12 + textH + bottomMargin + 12 // tiny safety
        return max(minOverlayHeight, clearHeadroom + fadeHeight + contentH)
    }
}

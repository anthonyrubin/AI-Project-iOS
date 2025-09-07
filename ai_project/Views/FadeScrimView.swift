import UIKit

/// Gradient view (clear → white). We resize the gradient layer on layout
/// so it always matches the view’s bounds after Auto Layout changes.
final class FadeScrimView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        let g = layer as! CAGradientLayer
        g.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.cgColor
        ]
        g.locations = [0.0, 0.6, 1.0]
        g.startPoint = CGPoint(x: 0.5, y: 0.0)
        g.endPoint   = CGPoint(x: 0.5, y: 1.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as! CAGradientLayer).frame = bounds
    }
}


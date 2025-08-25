import UIKit
import ObjectiveC

private enum _Assoc {
    static var scale: UInt8 = 0
    static var haptic: UInt8 = 0
}

extension UIButton {

    /// Call once (e.g. in viewDidLoad) to enable shrink + haptic without any color change.
    func applyTactileTap(scale: CGFloat = 0.98,
                         haptic: UIImpactFeedbackGenerator.FeedbackStyle = .light,
                         preserveColors: Bool = true) {
        // store params
        objc_setAssociatedObject(self, &_Assoc.scale, scale as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &_Assoc.haptic, haptic.rawValue as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // keep visual colors identical across states (no dim)
        if preserveColors {
            if #available(iOS 15.0, *), var cfg = self.configuration {
                let baseBG = cfg.baseBackgroundColor
                let baseFG = cfg.baseForegroundColor
                cfg.background.backgroundColorTransformer = UIConfigurationColorTransformer { _ in baseBG ?? .clear }
//                cfg.foregroundColorTransformer = UIConfigurationColorTransformer { _ in baseFG ?? .label }
                self.configuration = cfg
            }
            self.adjustsImageWhenHighlighted = false
        }

        // touch handlers
        removeTarget(self, action: #selector(_tactileDown), for: .touchDown)
        removeTarget(self, action: #selector(_tactileUpInside), for: .touchUpInside)
        removeTarget(self, action: #selector(_tactileCancel), for: [.touchDragExit, .touchCancel, .touchUpOutside])

        addTarget(self, action: #selector(_tactileDown), for: .touchDown)
        addTarget(self, action: #selector(_tactileUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(_tactileCancel), for: [.touchDragExit, .touchCancel, .touchUpOutside])
    }

    @objc private func _tactileDown() {
        let scale = (objc_getAssociatedObject(self, &_Assoc.scale) as? NSNumber)?.cgFloatValue ?? 0.98
        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc private func _tactileUpInside() {
        // haptic
        if let raw = objc_getAssociatedObject(self, &_Assoc.haptic) as? NSNumber,
           let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: raw.intValue) {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        // spring back
        UIView.animate(withDuration: 0.20,
                       delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.9,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.transform = .identity
        }
    }

    @objc private func _tactileCancel() {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.transform = .identity
        }
    }
}

private extension NSNumber {
    var cgFloatValue: CGFloat { CGFloat(truncating: self) }
}

import UIKit

public struct LanguageOption: Equatable {
    let code: String
    let display: String
    let flag: String
}

final class LanguagePickerViewController: UIViewController {

    // MARK: Input / Output
    private let options: [LanguageOption] = [
        .init(code: "en", display: "English",     flag: "🇺🇸"),
        .init(code: "zh", display: "中文",         flag: "🇨🇳"),
        .init(code: "hi", display: "हिन्दी",      flag: "🇮🇳"),
        .init(code: "es", display: "Español",     flag: "🇪🇸"),
        .init(code: "fr", display: "Français",    flag: "🇫🇷"),
        .init(code: "de", display: "Deutsch",     flag: "🇩🇪"),
        .init(code: "ru", display: "Русский",     flag: "🇷🇺"),
        .init(code: "pt", display: "Português",   flag: "🇵🇹"),
        .init(code: "it", display: "Italiano",    flag: "🇮🇹"),
        .init(code: "ro", display: "Română",      flag: "🇷🇴"),
        .init(code: "az", display: "Azərbaycan",  flag: "🇦🇿"),
        .init(code: "nl", display: "Nederlands",  flag: "🇳🇱")
    ]
    private var selected: LanguageOption?
    private let onPick: (LanguageOption) -> Void

    // MARK: UI
    private let overlay = UIView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private var centerYConstraint: NSLayoutConstraint?

    // MARK: Init
    init(selectedCode: String? = nil, onPick: @escaping (LanguageOption) -> Void) {
        self.onPick = onPick
        self.selected = options.first(where: { $0.code == selectedCode })
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // run once
        if centerYConstraint?.constant == 0 { return }
        animateIn()
    }

    // MARK: UI Build
    private func buildUI() {
        view.backgroundColor = .clear

        // overlay
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFromBackground))
        overlay.addGestureRecognizer(tap)

        // container (the white sheet)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        view.addSubview(container)

        let leading = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        let trailing = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        let centerX = container.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let centerY = container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        self.centerYConstraint = centerY
        NSLayoutConstraint.activate([leading, trailing, centerX, centerY])

        // title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select language"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor(named: "Label") ?? UIColor.black
        titleLabel.textAlignment = .left

        // close (X)
        var closeCfg = UIButton.Configuration.plain()
        closeCfg.image = UIImage(systemName: "xmark")
        closeCfg.baseForegroundColor = UIColor.secondaryLabel
        closeCfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        closeButton.configuration = closeCfg
        closeButton.addTarget(self, action: #selector(dismissFromX), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "id_language_close"

        // scroll content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16)

        // add subviews
        container.addSubview(titleLabel)
        container.addSubview(closeButton)
        container.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        buildLanguageRows()
    }

    // MARK: Rows
    private func buildLanguageRows() {
        options.forEach { opt in
            let button = makeRowButton(for: opt)
            stack.addArrangedSubview(button)
        }
        // initial highlight
        updateSelectionUI(animated: false)
    }

    private func makeRowButton(for option: LanguageOption) -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        b.layer.cornerRadius = 14
        b.layer.masksToBounds = true
        b.backgroundColor = UIColor.secondarySystemBackground

        // content
        var cfg = UIButton.Configuration.plain()
        cfg.contentInsets = .init(top: 14, leading: 18, bottom: 14, trailing: 18)
        cfg.attributedTitle = AttributedString("\(option.display) \(option.flag)", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.label
        ]))
        cfg.titleAlignment = .leading
        b.configuration = cfg

        b.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.selected = option
            self.updateSelectionUI(animated: true)
            self.dismissWithSlideDown {
                self.onPick(option)
            }
        }, for: .touchUpInside)

        b.accessibilityIdentifier = "id_language_\(option.code)"
        return b
    }

    private func updateSelectionUI(animated: Bool) {
        guard let selected = selected else { return }
        for case let b as UIButton in stack.arrangedSubviews {
            // crude parse: last path component of identifier is code
            let code = b.accessibilityIdentifier?.replacingOccurrences(of: "id_language_", with: "") ?? ""
            let isSelected = code == selected.code
            let changes = {
                if isSelected {
                    b.backgroundColor = UIColor.black // dark pill like screenshot
                    var cfg = b.configuration!
                    cfg.attributedTitle = AttributedString(cfg.attributedTitle?.string ?? "", attributes: AttributeContainer([
                        .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                        .foregroundColor: UIColor.white
                    ]))
                    b.configuration = cfg
                } else {
                    b.backgroundColor = UIColor.secondarySystemBackground
                    var cfg = b.configuration!
                    cfg.attributedTitle = AttributedString(cfg.attributedTitle?.string ?? "", attributes: AttributeContainer([
                        .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                        .foregroundColor: UIColor.label
                    ]))
                    b.configuration = cfg
                }
            }
            animated ? UIView.animate(withDuration: 0.15, animations: changes) : changes()
        }
    }

    // MARK: Animations (match Alert)
    private func animateIn() {
        view.layoutIfNeeded()
        guard let centerY = centerYConstraint else { return }
        centerY.constant = -view.bounds.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.50,
                       delay: 0.01,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut],
                       animations: {
            centerY.constant = 0
            self.view.layoutIfNeeded()
        })
    }

    private func dismissWithSlideDown(completion: (() -> Void)? = nil) {
        guard let centerY = centerYConstraint else { return }
        centerY.constant = view.bounds.height
        UIView.animate(withDuration: 0.30,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut],
                       animations: { self.view.layoutIfNeeded() },
                       completion: { _ in
            self.dismiss(animated: true, completion: completion)
        })
    }

    // MARK: Actions
    @objc private func dismissFromX() {
        dismissWithSlideDown()
    }

    @objc private func dismissFromBackground() {
        dismissWithSlideDown()
    }
}

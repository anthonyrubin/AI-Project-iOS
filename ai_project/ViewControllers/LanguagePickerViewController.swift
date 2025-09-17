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
    private let rootStack = UIStackView()
    private let header = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let listStack = UIStackView()

    private var centerYConstraint: NSLayoutConstraint!
    private var hasAnimatedIn = false

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
        buildRows()
    }

    // === Make it animate IDENTICAL to Alert: run the spring in viewDidLayoutSubviews ===
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true

        // start above screen, then settle to center
        centerYConstraint.constant = -view.bounds.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.50,
                       delay: 0.01,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut],
                       animations: {
            self.centerYConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
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
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissFromBackground)))

        // container
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        view.addSubview(container)

        let leading = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        let trailing = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        let centerX = container.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        centerYConstraint = container.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        // min/max height so it doesn't collapse
        let minH = container.heightAnchor.constraint(greaterThanOrEqualToConstant: 220)
        let maxH = container.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
        NSLayoutConstraint.activate([leading, trailing, centerX, centerYConstraint, minH, maxH])

        // root stack
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = 0
        container.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: container.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // header
        header.translatesAutoresizingMaskIntoConstraints = false
        header.heightAnchor.constraint(equalToConstant: 56).isActive = true
        rootStack.addArrangedSubview(header)

        // title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select language"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        header.addSubview(titleLabel)

        // reuse the extension's circular X
        let closeItem = makeCloseBarItem()
        guard let x = closeItem.customView as? UIButton else { return }

        // remove default target; hook custom slide-down dismiss
        x.removeTarget(nil, action: nil, for: .allEvents)
        x.addTarget(self, action: #selector(dismissFromX), for: .touchUpInside)

        // place X in header (top-right)
        x.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(x)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            x.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            x.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        // scroll area
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        rootStack.addArrangedSubview(scrollView)

        // list stack
        listStack.translatesAutoresizingMaskIntoConstraints = false
        listStack.axis = .vertical
        listStack.alignment = .fill
        listStack.spacing = 12
        listStack.isLayoutMarginsRelativeArrangement = true
        listStack.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        scrollView.addSubview(listStack)

        NSLayoutConstraint.activate([
            listStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            listStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            listStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            listStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            listStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }


    private func buildRows() {
        options.forEach { opt in
            let b = UIButton(type: .system)
            b.translatesAutoresizingMaskIntoConstraints = false
            b.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            b.layer.cornerRadius = 14
            b.layer.masksToBounds = true
            b.backgroundColor = .secondarySystemBackground
            b.accessibilityIdentifier = "id_language_\(opt.code)"

            var cfg = UIButton.Configuration.plain()
            cfg.title = "\(opt.display) \(opt.flag)"     // plain title == source of truth
            cfg.contentInsets = .init(top: 14, leading: 18, bottom: 14, trailing: 18)
            cfg.titleAlignment = .leading
            b.configuration = cfg

            b.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                self.selected = opt
                self.updateSelectionUI(animated: true)
                self.dismissWithSlideDown { self.onPick(opt) }
            }, for: .touchUpInside)

            listStack.addArrangedSubview(b)
        }
        updateSelectionUI(animated: false)
    }

    private func updateSelectionUI(animated: Bool) {
        guard let selected = selected else { return }
        let apply = { [weak self] in
            guard let self = self else { return }
            for case let b as UIButton in self.listStack.arrangedSubviews {
                let code = (b.accessibilityIdentifier ?? "").replacingOccurrences(of: "id_language_", with: "")
                let isSel = code == selected.code
                b.backgroundColor = isSel ? .black : .secondarySystemBackground

                guard var cfg = b.configuration else { continue }
                let title = cfg.title ?? (b.titleLabel?.text ?? "")
                let color: UIColor = isSel ? .white : .label
                cfg.attributedTitle = AttributedString(
                    title,
                    attributes: AttributeContainer([
                        .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                        .foregroundColor: color
                    ])
                )
                b.configuration = cfg
            }
        }
        animated ? UIView.animate(withDuration: 0.15, animations: apply) : apply()
    }

    // MARK: Dismiss (same pattern as Alert)
    private func dismissWithSlideDown(completion: (() -> Void)? = nil) {
        centerYConstraint.constant = view.bounds.height
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

    @objc private func dismissFromX() { dismissWithSlideDown() }
    @objc private func dismissFromBackground() { dismissWithSlideDown() }
}

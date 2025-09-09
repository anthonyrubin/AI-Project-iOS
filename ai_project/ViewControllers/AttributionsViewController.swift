import UIKit
import SafariServices

// MARK: - Data Model

struct AttributionItem: Hashable {
    let id = UUID()
    let title: String                    // e.g., "Front squat demo"
    let author: String                   // e.g., "Isiwal"
    let sourceURL: URL                   // Wikimedia file page
    let licenseName: String              // e.g., "CC BY-SA 4.0"
    let licenseURL: URL                  // https://creativecommons.org/licenses/by-sa/4.0/
    let changes: String?                 // e.g., "cropped, color corrected" (nil = "no changes")
    let adaptedDownloadURL: URL?         // optional public link to your adapted asset
        
    public init(title: String, author: String, sourceURL: URL, licenseName: String, licenseURL: URL, changes: String?, adaptedDownloadURL: URL?) {
        self.title = title
        self.author = author
        self.sourceURL = sourceURL
        self.licenseName = licenseName
        self.licenseURL = licenseURL
        self.changes = changes
        self.adaptedDownloadURL = adaptedDownloadURL
    }
}

// MARK: - View Controller

final class AttributionsViewController: UITableViewController {

    private var items = [
        AttributionItem(
            title: "Sargis Martirosjan clean and jerk-4970",
            author: "Isiwal",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Sargis_Martirosjan_clean_and_jerk-4970.jpg")!,
            licenseName: "CC BY-SA 4.0",
            licenseURL: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/deed.en")!,
            changes: nil,
            adaptedDownloadURL: nil
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always // optional: force large title
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.register(AttributionCell.self, forCellReuseIdentifier: AttributionCell.reuseID)
        tableView.register(StandardTitleCell.self, forCellReuseIdentifier: "StandardTitleCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.separatorStyle = .none
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardTitleCell", for: indexPath) as! StandardTitleCell
            cell.configure(
                with: "Attribution & Licenses",
                subtitle: "On this page you fill find credit for some of the assets used in the app.",
                fontSize: 35)
            return cell
        }

        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AttributionCell.reuseID,
                                                 for: indexPath) as! AttributionCell
        cell.configure(with: item)
        cell.onOpenURL = { [weak self] url in
            guard let self = self else { return }
            let safari = SFSafariViewController(url: url)
            self.present(safari, animated: true)
        }
        return cell
    }
}

// MARK: - Cell

final class AttributionCell: UITableViewCell {

    static let reuseID = "AttributionCell"

    var onOpenURL: ((URL) -> Void)?

    private let card = UIView()
    private let vstack = UIStackView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let changesLabel = UILabel()
    private let buttonsStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selectionStyle = .none
        setupUI()
    }

    private func setupUI() {
        contentView.layoutMargins = .init(top: 8, left: 16, bottom: 8, right: 16)

        // Card background
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.masksToBounds = true
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            card.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])

        // Vertical stack inside card
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.axis = .vertical
        vstack.alignment = .fill
        vstack.spacing = 8
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.directionalLayoutMargins = .init(top: 14, leading: 14, bottom: 14, trailing: 14)
        card.addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            vstack.topAnchor.constraint(equalTo: card.topAnchor),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.numberOfLines = 0

        // Author line
        authorLabel.font = .systemFont(ofSize: 15, weight: .regular)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = 0

        // Changes line
        changesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        changesLabel.textColor = .secondaryLabel
        changesLabel.numberOfLines = 0

        // Buttons row
        buttonsStack.axis = .horizontal
        buttonsStack.alignment = .fill
        buttonsStack.distribution = .fillProportionally
        buttonsStack.spacing = 8

        vstack.addArrangedSubview(titleLabel)
        vstack.addArrangedSubview(authorLabel)
        vstack.addArrangedSubview(changesLabel)
        vstack.setCustomSpacing(10, after: changesLabel)
        vstack.addArrangedSubview(buttonsStack)
    }

    func configure(with item: AttributionItem) {
        titleLabel.text = "“\(item.title)”"
        authorLabel.text = "by \(item.author), via Wikimedia Commons • \(item.licenseName)"
        changesLabel.text = "Changes: \(item.changes?.isEmpty == false ? item.changes! : "no changes")"

        // Clear old buttons
        buttonsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Build buttons
        let fileBtn = linkButton(title: "File", systemImage: "link")
        fileBtn.addAction(UIAction { [weak self] _ in self?.onOpenURL?(item.sourceURL) }, for: .touchUpInside)

        let licenseBtn = linkButton(title: "License", systemImage: "doc.plaintext")
        licenseBtn.addAction(UIAction { [weak self] _ in self?.onOpenURL?(item.licenseURL) }, for: .touchUpInside)

        buttonsStack.addArrangedSubview(fileBtn)
        buttonsStack.addArrangedSubview(licenseBtn)

        if let adaptedURL = item.adaptedDownloadURL {
            let dlBtn = linkButton(title: "Download adapted", systemImage: "arrow.down.circle")
            dlBtn.addAction(UIAction { [weak self] _ in self?.onOpenURL?(adaptedURL) }, for: .touchUpInside)
            buttonsStack.addArrangedSubview(dlBtn)
        }
    }

    private func linkButton(title: String, systemImage: String) -> UIButton {
        var config = UIButton.Configuration.bordered()
        config.cornerStyle = .capsule
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 6
        config.baseForegroundColor = tintColor
        config.background.strokeColor = tintColor
        config.background.strokeWidth = 1
        config.background.backgroundColor = .clear

        let button = UIButton(type: .system)
        button.configuration = config
        return button
    }
}

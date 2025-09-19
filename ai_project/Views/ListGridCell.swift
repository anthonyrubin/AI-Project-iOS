import UIKit

// MARK: - Public item model
public struct ListGridItem: Hashable {
    public let id = UUID()
    public let title: String            // e.g., "Overhead Press"
    public let icon: String             // SF Symbol name or asset name
    public init(title: String, subtitle: String? = nil, icon: String) {
        self.title = title
        self.icon = icon
    }
}

// MARK: - View
public final class ListGridView: UIView,
                                 UISearchBarDelegate,
                                 UICollectionViewDataSource,
                                 UICollectionViewDelegate,
                                 UICollectionViewDelegateFlowLayout {

    // Public API
    public var items: [ListGridItem] = [] {
        didSet { filtered = items; collectionView.reloadData() }
    }
    public var onSelect: ((Int, ListGridItem) -> Void)?
    public var showsSearchBar: Bool = true { didSet { searchBar.isHidden = !showsSearchBar } }

    // UI
    private let searchBar = UISearchBar()
    private let collectionView: UICollectionView

    // Data
    private var filtered: [ListGridItem] = []

    // Layout constants
    private let interItem: CGFloat = 8
    private let lineSpacing: CGFloat = 8

    // MARK: Init
    public override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = interItem
        layout.minimumLineSpacing = lineSpacing
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Build UI
    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        // Search
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search exercises"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .done
        searchBar.enablesReturnKeyAutomatically = false

        // Collection
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        collectionView.keyboardDismissMode = .onDrag // dismiss keyboard on scroll
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseID)

        // Dismiss keyboard on tap anywhere (without blocking taps)
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tapToDismiss.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapToDismiss)

        // Layout
        let stack = UIStackView(arrangedSubviews: [searchBar, collectionView])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: Search
    @objc private func endEditingTap() { endEditing(true) }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        filtered = items
        collectionView.reloadData()
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        filtered = q.isEmpty
            ? items
            : items.filter {
                $0.title.localizedCaseInsensitiveContains(q)
            }
        collectionView.reloadData()
    }

    // MARK: DataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filtered.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseID,
                                                      for: indexPath) as! GridCell
        cell.configure(filtered[indexPath.item])
        return cell
    }

    // MARK: Delegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = filtered[indexPath.item]
        let originalIndex = items.firstIndex(of: item) ?? indexPath.item
        onSelect?(originalIndex, item)
    }

    // MARK: Flow layout (responsive columns + two-line height)
    public override func layoutSubviews() {
        super.layoutSubviews()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.invalidateLayout()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        // Columns by width (defensive)
        let columns: CGFloat
        if width >= 700 { columns = 5 }
        else if width >= 430 { columns = 4 }
        else if width >= 360 { columns = 3 }
        else { columns = 2 }
        let totalSpacing = interItem * (columns - 1)
        let w = floor((width - totalSpacing) / columns)
        return CGSize(width: w, height: 96) // tall enough for icon + 2 lines
    }
}

private final class GridCell: UICollectionViewCell {
    static let reuseID = "GridCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    // Light/dark greens for selection
    private static let selectionFill  = UIColor(red: 0.90, green: 0.98, blue: 0.92, alpha: 1.0) // light green
    private static let selectionStroke = UIColor(red: 0.12, green: 0.55, blue: 0.28, alpha: 1.0) // dark green

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        // Do NOT set tintColor; leave icons “as is”
        // Allow multicolor SF Symbols to render their palette if present
        iconView.preferredSymbolConfiguration = .preferringMulticolor()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Title across the bottom
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // 6pt gap above title
            iconView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -6),

            // Icon fills remaining space above, centered, width is a fraction of the cell
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        titleLabel.textColor = .label
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = Self.selectionFill
                contentView.layer.borderWidth = 2
                contentView.layer.borderColor = Self.selectionStroke.cgColor
            } else {
                contentView.backgroundColor = .secondarySystemBackground
                contentView.layer.borderWidth = 0
                contentView.layer.borderColor = nil
            }
            // Do NOT change iconView.tintColor; leave image as provided
            // Leave title color alone unless you want a selected style
        }
    }

    func configure(_ item: ListGridItem) {
        titleLabel.text = item.title.capitalized

        // Use the image “as is” (keep original colors), no template/tinting
        let baseImage = UIImage(systemName: item.icon) ?? UIImage(named: item.icon)
        iconView.image = baseImage?.withRenderingMode(.alwaysOriginal)
    }
}

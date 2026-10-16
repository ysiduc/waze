import UIKit

public protocol SearchDrawerDelegate: AnyObject {
    func searchDrawer(_ drawer: SearchDrawerViewController, didSelectDestination destination: WZDestination)
}

/// Reconstructed from waze_WazeSearchImplementation & waze_WazeSearchResultsUI bundles.
public final class SearchDrawerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    public weak var delegate: SearchDrawerDelegate?

    private let searchBar = UISearchBar()
    private let categorySegment = UISegmentedControl(items: ["All", "Gas", "Food", "Coffee", "Parking", "Saved"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var results: [WZDestination] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WazeTheme.canvasGrey
        setupUI()
        loadInitialDestinations()
    }

    private func setupUI() {
        searchBar.placeholder = "Where to?"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        categorySegment.selectedSegmentIndex = 0
        categorySegment.translatesAutoresizingMaskIntoConstraints = false
        categorySegment.addTarget(self, action: #selector(handleCategoryChange), for: .valueChanged)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DestCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(categorySegment)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            categorySegment.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            categorySegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categorySegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categorySegment.heightAnchor.constraint(equalToConstant: 32),

            tableView.topAnchor.constraint(equalTo: categorySegment.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private var selectedCategory: WZSearchCategory {
        switch categorySegment.selectedSegmentIndex {
        case 1: return .gas
        case 2: return .food
        case 3: return .coffee
        case 4: return .parking
        case 5: return .favorites
        default: return .all
        }
    }

    private var currentUserCoord: WZCoordinate? {
        if let telem = WZWazeLocationServiceBridge.shared.lastKnownTelemetry {
            return WZCoordinate(latitude: telem.latitude, longitude: telem.longitude)
        }
        return WZCoordinate(latitude: 37.7749, longitude: -122.4194)
    }

    private func loadInitialDestinations() {
        results = SearchEngine.shared.search(
            query: searchBar.text ?? "",
            category: selectedCategory,
            near: currentUserCoord
        )
        tableView.reloadData()
    }

    @objc private func handleCategoryChange() {
        loadInitialDestinations()
    }

    // MARK: - UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        results = SearchEngine.shared.search(
            query: searchText,
            category: selectedCategory,
            near: currentUserCoord
        )
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource & Delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DestCell", for: indexPath)
        let dest = results[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = dest.title
        content.secondaryText = dest.subtitle
        content.image = UIImage(systemName: dest.isFavorite ? "star.fill" : "mappin.circle.fill")
        content.imageProperties.tintColor = dest.isFavorite ? WazeTheme.warningYellow : WazeTheme.cyan

        cell.contentConfiguration = content
        cell.backgroundColor = .white
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = results[indexPath.row]
        SearchEngine.shared.addRecentSearch(selected)
        delegate?.searchDrawer(self, didSelectDestination: selected)
        dismiss(animated: true)
    }
}

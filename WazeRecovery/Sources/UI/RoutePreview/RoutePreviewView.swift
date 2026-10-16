import UIKit

public protocol RoutePreviewViewDelegate: AnyObject {
    func routePreviewViewDidTapStartNavigation(_ view: RoutePreviewView)
    func routePreviewViewDidTapClose(_ view: RoutePreviewView)
    func routePreviewViewDidSelectAlternative(_ view: RoutePreviewView, at index: Int)
}

/// Reconstructed from waze_WazeTripOverviewImplementation bundle.
/// Displays route summary, ETA time, distance, and "Go now" action button.
public final class RoutePreviewView: UIView {
    public weak var delegate: RoutePreviewViewDelegate?

    private let containerCard = UIView()
    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    private let etaLabel = UILabel()
    private let distanceLabel = UILabel()
    private let startButton = WazeButton(title: "Go now", style: .primaryCyan)
    private let closeButton = UIButton(type: .system)

    public private(set) var currentRoute: WZRoute?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        containerCard.backgroundColor = .white
        containerCard.layer.cornerRadius = 24.0
        containerCard.layer.shadowColor = UIColor.black.cgColor
        containerCard.layer.shadowOpacity = 0.12
        containerCard.layer.shadowOffset = CGSize(width: 0, height: -3)
        containerCard.layer.shadowRadius = 12.0
        containerCard.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = WazeTheme.headlineFont(size: 17)
        titleLabel.textColor = WazeTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        durationLabel.font = WazeTheme.titleFont(size: 28)
        durationLabel.textColor = WazeTheme.cyan
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        etaLabel.font = WazeTheme.headlineFont(size: 15)
        etaLabel.textColor = WazeTheme.textSecondary
        etaLabel.translatesAutoresizingMaskIntoConstraints = false

        distanceLabel.font = WazeTheme.bodyFont(size: 15)
        distanceLabel.textColor = WazeTheme.textSecondary
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = WazeTheme.textSecondary.withAlphaComponent(0.6)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        startButton.translatesAutoresizingMaskIntoConstraints = false

        let metricsStack = UIStackView(arrangedSubviews: [etaLabel, distanceLabel])
        metricsStack.axis = .horizontal
        metricsStack.spacing = 16
        metricsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerCard)
        containerCard.addSubview(closeButton)
        containerCard.addSubview(titleLabel)
        containerCard.addSubview(durationLabel)
        containerCard.addSubview(metricsStack)
        containerCard.addSubview(startButton)

        NSLayoutConstraint.activate([
            containerCard.topAnchor.constraint(equalTo: topAnchor),
            containerCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerCard.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),

            durationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            durationLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),

            metricsStack.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 4),
            metricsStack.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),

            startButton.topAnchor.constraint(equalTo: metricsStack.bottomAnchor, constant: 20),
            startButton.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -20),
            startButton.bottomAnchor.constraint(equalTo: containerCard.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        startButton.addTarget(self, action: #selector(handleStart), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }

    public func configure(with route: WZRoute) {
        self.currentRoute = route
        titleLabel.text = route.summary
        durationLabel.text = route.formattedDuration
        etaLabel.text = "ETA \(route.formattedArrivalTime)"
        distanceLabel.text = route.formattedDistanceKm
    }

    @objc private func handleStart() {
        delegate?.routePreviewViewDidTapStartNavigation(self)
    }

    @objc private func handleClose() {
        delegate?.routePreviewViewDidTapClose(self)
    }
}

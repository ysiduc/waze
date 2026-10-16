import UIKit

/// Reconstructed navigation turn-by-turn banner matching authentic Waze guidance banner layout.
public final class NavigationBannerView: UIView {
    private let iconImageView = UIImageView()
    private let distanceLabel = UILabel()
    private let instructionLabel = UILabel()
    private let streetLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WazeTheme.cyan
        layer.cornerRadius = 18.0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10.0

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        distanceLabel.font = WazeTheme.titleFont(size: 24)
        distanceLabel.textColor = .white
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        instructionLabel.font = WazeTheme.headlineFont(size: 16)
        instructionLabel.textColor = .white
        instructionLabel.numberOfLines = 1
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        streetLabel.font = WazeTheme.captionFont(size: 13)
        streetLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        streetLabel.numberOfLines = 1
        streetLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [instructionLabel, streetLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        addSubview(distanceLabel)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            distanceLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            distanceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            distanceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            textStack.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public func update(maneuver: WZManeuverType, distanceText: String, instruction: String, street: String) {
        iconImageView.image = UIImage(systemName: maneuver.iconSymbolName)
        distanceLabel.text = distanceText
        instructionLabel.text = instruction
        streetLabel.text = street
    }
}

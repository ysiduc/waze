import UIKit

/// Reconstructed from _speedometerVC and showSpeedometer properties in Swift reflection metadata.
public final class SpeedometerView: UIView {
    private let speedLabel = UILabel()
    private let unitLabel = UILabel()
    private let speedLimitBadge = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 30.0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6.0

        speedLabel.font = WazeTheme.titleFont(size: 20)
        speedLabel.textColor = WazeTheme.textPrimary
        speedLabel.textAlignment = .center
        speedLabel.text = "0"
        speedLabel.translatesAutoresizingMaskIntoConstraints = false

        unitLabel.font = WazeTheme.captionFont(size: 10)
        unitLabel.textColor = WazeTheme.textSecondary
        unitLabel.textAlignment = .center
        unitLabel.text = "km/h"
        unitLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [speedLabel, unitLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 60),
            heightAnchor.constraint(equalToConstant: 60),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public func updateSpeed(kmH: Double, isMetric: Bool = true) {
        let displaySpeed = isMetric ? kmH : (kmH * 0.621371)
        speedLabel.text = "\(Int(round(displaySpeed)))"
        unitLabel.text = isMetric ? "km/h" : "mph"
    }
}

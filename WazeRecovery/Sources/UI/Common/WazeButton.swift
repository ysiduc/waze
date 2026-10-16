import UIKit

/// Rounded pill button following authentic Waze UI styling.
public final class WazeButton: UIButton {
    public enum Style {
        case primaryCyan
        case secondaryWhite
        case outline
    }

    private let style: Style

    public init(title: String, style: Style = .primaryCyan) {
        self.style = style
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        self.style = .primaryCyan
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        titleLabel?.font = WazeTheme.headlineFont(size: 16)
        layer.cornerRadius = 25.0
        layer.masksToBounds = false
        heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        switch style {
        case .primaryCyan:
            backgroundColor = WazeTheme.cyan
            setTitleColor(.white, for: .normal)
            layer.shadowColor = WazeTheme.cyan.cgColor
            layer.shadowOpacity = 0.35
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 8.0

        case .secondaryWhite:
            backgroundColor = .white
            setTitleColor(WazeTheme.textPrimary, for: .normal)
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.08
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 6.0

        case .outline:
            backgroundColor = .clear
            setTitleColor(WazeTheme.textSecondary, for: .normal)
            layer.borderColor = WazeTheme.textSecondary.withAlphaComponent(0.3).cgColor
            layer.borderWidth = 1.5
        }
    }
}

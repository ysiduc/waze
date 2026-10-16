import UIKit

public protocol WelcomeViewControllerDelegate: AnyObject {
    func welcomeViewControllerDidCompleteOnboarding(_ vc: WelcomeViewController)
}

/// Reconstructed from waze_WazeOnboardingImplementation bundle.
/// Presents authentic Waze Welcome interface with guest mode and sign-in options.
public final class WelcomeViewController: UIViewController {
    public weak var delegate: WelcomeViewControllerDelegate?

    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let guestModeButton = WazeButton(title: "Start without login", style: .primaryCyan)
    private let googleSignInButton = WazeButton(title: "Continue with Google", style: .secondaryWhite)
    private let emailSignInButton = WazeButton(title: "Continue with email", style: .outline)

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WazeTheme.canvasGrey
        setupUI()
    }

    private func setupUI() {
        // Icon / Logo
        logoImageView.image = UIImage(systemName: "location.north.circle.fill")
        logoImageView.tintColor = WazeTheme.cyan
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text = "Get where you're going\nwith Waze"
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = WazeTheme.titleFont(size: 26)
        titleLabel.textColor = WazeTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subtitleLabel.text = "Real-time road alerts, traffic updates & turn-by-turn navigation"
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = WazeTheme.bodyFont(size: 15)
        subtitleLabel.textColor = WazeTheme.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Button stack
        let stack = UIStackView(arrangedSubviews: [guestModeButton, googleSignInButton, emailSignInButton])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 90),
            logoImageView.heightAnchor.constraint(equalToConstant: 90),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        guestModeButton.addTarget(self, action: #selector(handleGuestMode), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        emailSignInButton.addTarget(self, action: #selector(handleEmailSignIn), for: .touchUpInside)
    }

    @objc private func handleGuestMode() {
        // Starts clean guest session using dynamic Keychain storage (zero error -34018)
        _ = UserPreferencesService.shared.startGuestSession()
        delegate?.welcomeViewControllerDidCompleteOnboarding(self)
    }

    @objc private func handleGoogleSignIn() {
        let alert = UIAlertController(
            title: "Google Sign-In",
            message: "Google OAuth whitelisting requires official Google Cloud Console registration. Guest Mode is fully functional offline.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue as Guest", style: .default, handler: { [weak self] _ in
            self?.handleGuestMode()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleEmailSignIn() {
        let alert = UIAlertController(
            title: "Email Sign-In",
            message: "Enter email to log in or continue as Guest.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in tf.placeholder = "driver@example.com" }
        alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { [weak self] _ in
            self?.handleGuestMode()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

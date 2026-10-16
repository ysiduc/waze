import Foundation

/// Reconstructed from Google SRLRegistry (Service Registry Locator) found in Waze ARM64 executable.
/// Provides thread-safe, memoized dependency resolution across application subsystems.
public final class SRLRegistry {
    public static let shared = SRLRegistry()

    private var singletons = [String: Any]()
    private var factories = [String: () -> Any]()
    private let lock = NSLock()

    private init() {}

    /// Registers a singleton instance for a given protocol or type.
    public func register<T>(_ serviceType: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(reflecting: serviceType)
        singletons[key] = instance
    }

    /// Registers a factory closure for lazy instantiation.
    public func registerLazy<T>(_ serviceType: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(reflecting: serviceType)
        factories[key] = factory
    }

    /// Resolves an instance of the requested service.
    public func resolve<T>(_ serviceType: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        let key = String(reflecting: serviceType)

        if let existing = singletons[key] as? T {
            return existing
        }

        if let factory = factories[key], let newInstance = factory() as? T {
            singletons[key] = newInstance
            return newInstance
        }

        return nil
    }

    /// Clears registered instances (for testing).
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        singletons.removeAll()
        factories.removeAll()
    }
}

import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
public final class JournalAuthService: ObservableObject {
    public static let shared = JournalAuthService()

    @AppStorage("journalFaceIDLockEnabled") public var isLockEnabled: Bool = false
    @Published public var isUnlocked: Bool = false

    public init() {
        self.isUnlocked = !isLockEnabled
    }

    public var biometryType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    public var biometricName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }

    public func authenticate() async -> Bool {
        guard isLockEnabled else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock your reflection and prayer journal."
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                isUnlocked = success
                return success
            } catch {
                isUnlocked = false
                return false
            }
        } else {
            // No passcode or biometrics enrolled on device/simulator
            isUnlocked = true
            return true
        }
    }

    public func lock() {
        if isLockEnabled {
            isUnlocked = false
        }
    }

    public func toggleLock(enabled: Bool) async -> Bool {
        if enabled {
            // Require authentication before enabling lock
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                do {
                    let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to enable journal lock.")
                    if success {
                        isLockEnabled = true
                        isUnlocked = true
                        return true
                    }
                    return false
                } catch {
                    return false
                }
            } else {
                isLockEnabled = true
                isUnlocked = true
                return true
            }
        } else {
            // Require authentication before disabling lock
            let success = await authenticate()
            if success {
                isLockEnabled = false
                isUnlocked = true
                return true
            }
            return false
        }
    }
}

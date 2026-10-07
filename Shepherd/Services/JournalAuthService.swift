import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
public final class JournalAuthService: ObservableObject {
    public static let shared = JournalAuthService()

    @AppStorage("journalFaceIDLockEnabled") public var isLockEnabled: Bool = false
    @Published public var isUnlocked: Bool = false

    #if DEBUG
    /// UI tests only. `-uitestJournalAuth yes,no,yes` answers each owner check in turn instead of
    /// LocalAuthentication (a check past the end of the list fails), so a test can unlock, leave
    /// and come back to a locked journal without driving simulator Face ID.
    private var scriptedResults: [Bool]? = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-uitestJournalAuth"), idx + 1 < args.count else { return nil }
        return args[idx + 1].split(separator: ",").map { $0 == "yes" }
    }()
    #endif

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

    /// Asks the device owner to authenticate. `nil` means the device has no passcode or biometrics
    /// set up, so there is nothing to check against.
    private func evaluateOwner(reason: String) async -> Bool? {
        #if DEBUG
        if scriptedResults != nil {
            return scriptedResults!.isEmpty ? false : scriptedResults!.removeFirst()
        }
        #endif
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return nil }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }

    public func authenticate() async -> Bool {
        guard isLockEnabled else {
            isUnlocked = true
            return true
        }
        // No passcode or biometrics enrolled on the device: nothing to check against.
        let success = await evaluateOwner(reason: "Unlock your reflection and prayer journal.") ?? true
        isUnlocked = success
        return success
    }

    public func lock() {
        if isLockEnabled {
            isUnlocked = false
        }
    }

    /// The journal screen went away (popped, or its tab switched): the next visit asks again.
    public func journalDidDisappear() {
        lock()
    }

    /// Re-lock once the app is in the background. `.inactive` is ignored: the Face ID prompt
    /// itself makes the scene inactive.
    public func scenePhaseChanged(to phase: ScenePhase) {
        if phase == .background {
            lock()
        }
    }

    public func toggleLock(enabled: Bool) async -> Bool {
        if enabled {
            // Require authentication before enabling lock
            let success = await evaluateOwner(reason: "Authenticate to enable journal lock.") ?? true
            if success {
                isLockEnabled = true
                isUnlocked = true
            }
            return success
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

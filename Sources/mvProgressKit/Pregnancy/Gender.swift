import Foundation

/// Standalone gender enum — the package never imports Clingy's `Pregnancy`.
/// Clingy maps its own `Pregnancy.Gender` → this at the call site.
public enum Gender: String, CaseIterable, Sendable {
    case girl, boy, unknown
}

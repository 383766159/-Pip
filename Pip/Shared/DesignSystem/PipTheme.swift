import SwiftUI

public enum PipTheme {
    public static let mint = Color(red: 0.35, green: 0.83, blue: 0.70)
    public static let mintDeep = Color(red: 0.16, green: 0.58, blue: 0.50)
    public static let mintGlow = Color(red: 0.62, green: 0.92, blue: 0.82)
    public static let warmApricot = Color(red: 1.00, green: 0.67, blue: 0.43)
    public static let apricotSoft = Color(red: 1.00, green: 0.84, blue: 0.68)
    public static let ink = Color(red: 0.12, green: 0.16, blue: 0.17)
    public static let cornerRadius: CGFloat = 24
    public static let pillRadius: CGFloat = 28
    public static let chipRadius: CGFloat = 16

    public static func ink(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.92, green: 0.96, blue: 0.95)
            : ink
    }

    public static func mutedInk(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.72, green: 0.80, blue: 0.78)
            : Color(red: 0.38, green: 0.45, blue: 0.44)
    }

    public static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.10)
            : Color(red: 0.96, green: 0.98, blue: 0.96)
    }

    public static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.14, green: 0.18, blue: 0.18)
            : Color.white.opacity(0.78)
    }

    public static func ringTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : mint.opacity(0.22)
    }
}

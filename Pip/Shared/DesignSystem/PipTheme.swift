import SwiftUI

public enum PipTheme {
    public static let mint = Color(red: 0.35, green: 0.83, blue: 0.70)
    public static let warmApricot = Color(red: 1.00, green: 0.67, blue: 0.43)
    public static let ink = Color(red: 0.12, green: 0.16, blue: 0.17)
    public static let cornerRadius: CGFloat = 24

    public static func ink(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.92, green: 0.96, blue: 0.95)
            : ink
    }

    public static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.10)
            : Color(red: 0.96, green: 0.98, blue: 0.96)
    }
}

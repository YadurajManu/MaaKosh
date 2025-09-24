//
//  SharedComponents.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI

// Typography constants for consistent styling
struct AppFont {
    // Font methods with system fallbacks
    static func titleLarge() -> Font {
        return Font.system(size: 32, weight: .bold, design: .rounded)
    }
    
    static func titleMedium() -> Font {
        return Font.system(size: 24, weight: .bold, design: .rounded)
    }
    
    static func titleSmall() -> Font {
        return Font.system(size: 20, weight: .semibold, design: .rounded)
    }
    
    static func body() -> Font {
        return Font.system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func caption() -> Font {
        return Font.system(size: 14, weight: .regular, design: .rounded)
    }
    
    static func small() -> Font {
        return Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    static func buttonText() -> Font {
        return Font.system(size: 18, weight: .semibold, design: .rounded)
    }
}

// Tooltip View
struct TooltipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(AppFont.small())
            .foregroundColor(Color.maakoshDeepPink)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(
                Capsule()
                    .fill(Color.maakoshLightPink.opacity(0.95))
                    .shadow(color: Color.maakoshMediumPink.opacity(0.4), radius: 3, x: 0, y: 2)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
}

// Action Button Style
struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                }
            }
    }
}

//
//  OnboardingPageView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Main icon with floating smaller icons
            ZStack {
                // Main icon
                Image(systemName: page.mainIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(Color.maakoshMediumPink)
                    .opacity(isAnimating ? 1 : 0.7)
                    .scaleEffect(isAnimating ? 1 : 0.9)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                // Floating small icons
                ForEach(0..<page.smallIcons.count, id: \.self) { index in
                    let angle = Double(index) * (2 * .pi / Double(page.smallIcons.count))
                    let radius: CGFloat = 100
                    
                    Image(systemName: page.smallIcons[index])
                        .font(.system(size: 20))
                        .foregroundColor(Color.maakoshMediumPink.opacity(0.7))
                        .offset(
                            x: cos(angle) * radius * (isAnimating ? 1 : 0.9),
                            y: sin(angle) * radius * (isAnimating ? 1 : 0.9)
                        )
                        .animation(
                            Animation.easeInOut(duration: 2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
            }
            .frame(height: 250)
            .padding(.bottom, 40)
            // .onAppear for ZStack removed, handled by root VStack
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0).delay(0.2), value: isAnimating)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.maakoshDeepPink)
                .padding(.bottom, 10)
                .multilineTextAlignment(.center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0).delay(0.35), value: isAnimating)
            
            // Description
            Text(page.description)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0).delay(0.5), value: isAnimating)
            
            Spacer()
        }
        .onAppear {
            // Set initial states for animation
            isAnimating = false

            // Trigger animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true // This will trigger all animations tied to isAnimating
            }
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingData.pages[0])
} 
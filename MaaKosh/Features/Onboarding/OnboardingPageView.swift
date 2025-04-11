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
            .onAppear {
                isAnimating = true
            }
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.maakoshDeepPink)
                .padding(.bottom, 10)
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingData.pages[0])
} 
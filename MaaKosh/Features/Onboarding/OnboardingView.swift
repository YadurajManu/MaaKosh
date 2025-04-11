//
//  OnboardingView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isOnboardingComplete = false
    
    // Animation states
    @State private var isAnimating = false
    @State private var pageOffset: CGFloat = 0
    
    var body: some View {
        if isOnboardingComplete {
            AuthView()
        } else {
            ZStack {
                // Background gradient using our color palette
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Page indicator
                    HStack {
                        ForEach(0..<OnboardingData.pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.maakoshDeepPink : Color.maakoshMediumPink.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.5 : 1)
                                .animation(.spring(), value: currentPage)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.top, 30)
                    
                    // Skip button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                isOnboardingComplete = true
                            }
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.maakoshDeepPink)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 10)
                    
                    // Page content with TabView
                    TabView(selection: $currentPage) {
                        ForEach(0..<OnboardingData.pages.count, id: \.self) { index in
                            OnboardingPageView(page: OnboardingData.pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.maakoshDeepPink)
                            }
                        } else {
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if currentPage < OnboardingData.pages.count - 1 {
                            Button(action: {
                                withAnimation {
                                    currentPage += 1
                                }
                            }) {
                                HStack {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color.maakoshDeepPink)
                                .cornerRadius(25)
                                .shadow(color: Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        } else {
                            Button(action: {
                                withAnimation {
                                    isOnboardingComplete = true
                                }
                            }) {
                                HStack {
                                    Text("Get Started")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color.maakoshDeepPink)
                                .cornerRadius(25)
                                .shadow(color: Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 30)
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

#Preview {
    OnboardingView()
} 
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
    // @State private var pageOffset: CGFloat = 0 // pageOffset seems unused, removing. If needed later, can be re-added.
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false


    func offsetForPage(index: Int, geometry: GeometryProxy) -> CGFloat {
        let pageIndexDifference = CGFloat(index - currentPage)
        let basicOffset = pageIndexDifference * geometry.size.width

        if isDragging {
            // Current page moves with drag
            if index == currentPage {
                return dragOffset
            }
            // Next page (to the right, index > currentPage)
            else if index > currentPage {
                return basicOffset + dragOffset // Starts off-screen right, moves in with drag
            }
            // Previous page (to the left, index < currentPage)
            else { // index < currentPage
                return basicOffset + dragOffset // Starts off-screen left, moves in with drag
            }
        } else {
            // When not dragging, position based on currentPage
            return basicOffset
        }
    }

   func opacityForPage(index: Int, geometry: GeometryProxy) -> Double {
       let pageIndexDifference = abs(currentPage - index)
       let dragProgress = abs(dragOffset) / geometry.size.width

       if isDragging {
           if index == currentPage { // Current page fades out as it's dragged
               return Double(1 - dragProgress * 1.2) // Adjusted
           } else if (index == currentPage + 1 && dragOffset < 0) || (index == currentPage - 1 && dragOffset > 0) { // Incoming page
               return Double(dragProgress * 1.2) // Adjusted
           } else {
               return 0.0 // Other pages not immediately involved in transition are hidden
           }
       } else {
           // When not dragging, only current page is fully visible
           return pageIndexDifference == 0 ? 1.0 : 0.0
       }
   }

   func scaleForPage(index: Int, geometry: GeometryProxy) -> CGFloat {
       let pageIndexDifference = abs(currentPage - index)
       let dragProgress = abs(dragOffset) / geometry.size.width
       let minScale: CGFloat = 0.85

       if isDragging {
           if index == currentPage { // Current page scales down as it's dragged
               return max(minScale, 1.0 - (dragProgress * 0.15)) // Adjusted
           } else if (index == currentPage + 1 && dragOffset < 0) || (index == currentPage - 1 && dragOffset > 0) { // Incoming page
               return minScale + ( (1.0 - minScale) * dragProgress * 1.2 ) // Adjusted
           } else {
               return minScale // Other pages
           }
       } else {
           // When not dragging, current page is full size, others could be slightly smaller if visible
           return pageIndexDifference == 0 ? 1.0 : minScale
       }
   }
    
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
                    
                    // Page content with ZStack and Gestures
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(0..<OnboardingData.pages.count, id: \.self) { index in
                                OnboardingPageView(page: OnboardingData.pages[index])
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .opacity(opacityForPage(index: index, geometry: geometry))
                                    .scaleEffect(scaleForPage(index: index, geometry: geometry))
                                    .offset(x: offsetForPage(index: index, geometry: geometry))
                            }
                        }
                        .contentShape(Rectangle()) // Ensures gesture is recognized over the whole area
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging { // Only start drag if not already in a programmatic transition
                                        isDragging = true
                                    }
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    isDragging = false
                                    let swipeThreshold = geometry.size.width / 4
                                    if dragOffset < -swipeThreshold { // Swiped left
                                        if currentPage < OnboardingData.pages.count - 1 {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                currentPage += 1
                                            }
                                        }
                                    } else if dragOffset > swipeThreshold { // Swiped right
                                        if currentPage > 0 {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                currentPage -= 1
                                            }
                                        }
                                    }
                                    // Reset dragOffset with animation to snap back if threshold not met, or to complete transition
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                    }
                    .frame(maxHeight: .infinity) // Ensure GeometryReader takes available space
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
//
//  Dashboard.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Dashboard: View {
    @State private var fullName: String = ""
    @State private var userEmail: String = ""
    @State private var isLoading = true
    @State private var navigateToPrePregnancy = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Welcome header card
                welcomeHeader
                
                // Care Categories section
                categoriesSection
                
                // Additional Services section
                additionalServicesSection
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
        .onAppear {
            loadUserData()
        }
        .fullScreenCover(isPresented: $navigateToPrePregnancy) {
            NavigationView {
                PrePregnancyView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.maakoshMediumPink)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to MaaKosh")
                    .font(AppFont.titleMedium())
                    .foregroundColor(.white)
                
                Text(userEmail.isEmpty ? "user@example.com" : userEmail)
                    .font(AppFont.body())
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Your personalized maternal & neonatal care system")
                    .font(AppFont.caption())
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Care Categories")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
                .padding(.leading, 8)
            
            // Pre-Pregnancy Card
            categoryCard(
                icon: "heart",
                title: "Pre-Pregnancy",
                description: "Planning and preparation for conception",
                color: Color.pink.opacity(0.15),
                action: {
                    navigateToPrePregnancy = true
                }
            )
            
            // Pregnancy Card
            categoryCard(
                icon: "heart.fill",
                title: "Pregnancy",
                description: "Monitoring and care during pregnancy",
                color: Color.purple.opacity(0.15),
                action: {
                    // Will implement in the future
                }
            )
            
            // Newborn Care Card
            categoryCard(
                icon: "figure.child",
                title: "Newborn Care",
                description: "Essential information for baby's health",
                color: Color.cyan.opacity(0.15),
                action: {
                    // Will implement in the future
                }
            )
        }
    }
    
    private var additionalServicesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Additional Services")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
                .padding(.leading, 8)
                .padding(.top, 10)
            
            HStack(spacing: 15) {
                // Health Tracking
                smallServiceCard(
                    icon: "heart.fill",
                    title: "Health Tracking",
                    action: {
                        // Will implement in the future
                    }
                )
                
                // Doctor Consultation
                smallServiceCard(
                    icon: "info.circle.fill",
                    title: "Doctor Consultation",
                    action: {
                        // Will implement in the future
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func categoryCard(icon: String, title: String, description: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.pink)
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(AppFont.titleSmall())
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func smallServiceCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.pink)
                
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Methods
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        // Set email
        userEmail = user.email ?? ""
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                // Get user profile data
                if let fullName = document.data()?["fullName"] as? String {
                    self.fullName = fullName
                }
            }
            
            isLoading = false
        }
    }
    
    // Helper to extract first name
    private func firstNameOnly(_ fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? fullName
    }
}

#Preview {
    Dashboard()
} 

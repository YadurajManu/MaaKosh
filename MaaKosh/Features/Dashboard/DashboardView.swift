//
//  DashboardView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(Color.maakoshDeepPink)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

// Placeholder for Home Tab
struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Home")
                        .font(AppFont.titleLarge())
                        .foregroundColor(Color.maakoshDeepPink)
                        .padding(.horizontal)
                    
                    Text("Welcome to MaaKosh")
                        .font(AppFont.titleMedium())
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    Text("Your dashboard content will appear here")
                        .font(AppFont.body())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
} 
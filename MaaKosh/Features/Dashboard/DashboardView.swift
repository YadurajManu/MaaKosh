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
            // Home Tab - Using the new Dashboard component
            Dashboard()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Maatri AI Assistant Tab
            MaatriView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Maatri")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(Color.maakoshDeepPink)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    DashboardView()
} 
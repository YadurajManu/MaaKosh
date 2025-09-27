//
//  PartnerSharingView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PartnerSharingView: View {
    @State private var sharedData: [SharedUpdate] = []
    @State private var isLoading = false
    @State private var showAddUpdateSheet = false
    @State private var showInviteSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var userProfile = UserProfile()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header Card
                        headerCard
                        
                        // Quick Actions
                        quickActionsCard
                        
                        // Shared Updates
                        sharedUpdatesSection
                        
                        // Invited Partners
                        invitedPartnersSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Partner Sharing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(AppFont.body())
                        }
                        .foregroundColor(.pink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.pink)
                    }
                }
            }
            .sheet(isPresented: $showAddUpdateSheet) {
                AddUpdateSheet(sharedData: $sharedData)
            }
            .sheet(isPresented: $showInviteSheet) {
                InvitePartnerSheet()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadUserData()
                loadSharedUpdates()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerCard: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(.pink)
            
            Text("Share Your Journey")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Text("Keep your partner and family updated with your pregnancy journey")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            HStack(spacing: 15) {
                // Share Update Button
                Button(action: {
                    showAddUpdateSheet = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.pink)
                        
                        Text("Share Update")
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Invite Partner Button
                Button(action: {
                    showInviteSheet = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(.pink)
                        
                        Text("Invite Partner")
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    private var sharedUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Updates")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                if !sharedData.isEmpty {
                    Text("\(sharedData.count) shared")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                }
            }
            
            if sharedData.isEmpty {
                emptyUpdatesView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sharedData) { update in
                        UpdateCard(update: update)
                    }
                }
            }
        }
    }
    
    private var emptyUpdatesView: some View {
        VStack(spacing: 15) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No updates shared yet")
                .font(AppFont.body())
                .foregroundColor(.gray)
            
            Text("Share your first update to keep your partner informed")
                .font(AppFont.caption())
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showAddUpdateSheet = true
            }) {
                Text("Share First Update")
                    .font(AppFont.buttonText())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.pink)
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var invitedPartnersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Invited Partners")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            VStack(spacing: 10) {
                // Partner 1
                PartnerCard(
                    name: userProfile.partnerName.isEmpty ? "Partner" : userProfile.partnerName,
                    email: "partner@example.com",
                    status: "Active",
                    lastSeen: "2 hours ago"
                )
                
                // Add more partners placeholder
                Button(action: {
                    showInviteSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.pink)
                        
                        Text("Invite another partner")
                            .font(AppFont.body())
                            .foregroundColor(.pink)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Data Methods
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let fullName = data["fullName"] as? String {
                    userProfile.fullName = fullName
                }
                if let partnerName = data["partnerName"] as? String {
                    userProfile.partnerName = partnerName
                }
            }
        }
    }
    
    private func loadSharedUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("sharedUpdates")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Error loading updates: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                sharedData = snapshot?.documents.compactMap { document in
                    try? document.data(as: SharedUpdate.self)
                } ?? []
            }
    }
}

// MARK: - Supporting Views

struct UpdateCard: View {
    let update: SharedUpdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(update.title)
                        .font(AppFont.titleSmall())
                        .foregroundColor(.black)
                    
                    Text(formatDate(update.timestamp))
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: iconForType(update.type))
                    .font(.system(size: 20))
                    .foregroundColor(.pink)
            }
            
            Text(update.content)
                .font(AppFont.body())
                .foregroundColor(.black)
                .lineLimit(3)
            
            if !update.recipients.isEmpty {
                HStack {
                    Text("Shared with:")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(update.recipients.joined(separator: ", "))
                        .font(AppFont.caption())
                        .foregroundColor(.pink)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func iconForType(_ type: UpdateType) -> String {
        switch type {
        case .milestone: return "star.fill"
        case .symptom: return "heart.fill"
        case .appointment: return "calendar"
        case .photo: return "photo.fill"
        case .general: return "message.fill"
        }
    }
}

struct PartnerCard: View {
    let name: String
    let email: String
    let status: String
    let lastSeen: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(AppFont.titleSmall())
                        .foregroundColor(.pink)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppFont.body())
                    .foregroundColor(.black)
                
                Text(email)
                    .font(AppFont.caption())
                    .foregroundColor(.gray)
                
                HStack {
                    Circle()
                        .fill(status == "Active" ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text("\(status) • \(lastSeen)")
                        .font(AppFont.small())
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                // View partner's updates
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AddUpdateSheet: View {
    @Binding var sharedData: [SharedUpdate]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: UpdateType = .general
    @State private var selectedRecipients: Set<String> = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Update Type Selection
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Update Type")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.black)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                            ForEach(UpdateType.allCases, id: \.self) { type in
                                Button(action: {
                                    selectedType = type
                                }) {
                                    HStack {
                                        Image(systemName: iconForType(type))
                                            .foregroundColor(selectedType == type ? .white : .pink)
                                        
                                        Text(type.rawValue)
                                            .font(AppFont.caption())
                                            .foregroundColor(selectedType == type ? .white : .black)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedType == type ? Color.pink : Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Title")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.black)
                        
                        TextField("Enter update title", text: $title)
                            .font(AppFont.body())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Content Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Content")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.black)
                        
                        TextField("Share your update...", text: $content, axis: .vertical)
                            .font(AppFont.body())
                            .lineLimit(5...10)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Recipients Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Share With")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.black)
                        
                        VStack(spacing: 8) {
                            RecipientRow(name: "Partner", email: "partner@example.com", isSelected: Binding(
                                get: { selectedRecipients.contains("partner") },
                                set: { if $0 { selectedRecipients.insert("partner") } else { selectedRecipients.remove("partner") } }
                            ))
                            RecipientRow(name: "Family", email: "family@example.com", isSelected: Binding(
                                get: { selectedRecipients.contains("family") },
                                set: { if $0 { selectedRecipients.insert("family") } else { selectedRecipients.remove("family") } }
                            ))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6).opacity(0.5))
            .navigationTitle("Share Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareUpdate()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func iconForType(_ type: UpdateType) -> String {
        switch type {
        case .milestone: return "star.fill"
        case .symptom: return "heart.fill"
        case .appointment: return "calendar"
        case .photo: return "photo.fill"
        case .general: return "message.fill"
        }
    }
    
    private func shareUpdate() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let update = SharedUpdate(
            id: UUID().uuidString,
            title: title,
            content: content,
            type: selectedType,
            recipients: Array(selectedRecipients),
            timestamp: Date()
        )
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("sharedUpdates")
            .document(update.id)
            .setData([
                "id": update.id,
                "title": update.title,
                "content": update.content,
                "type": update.type.rawValue,
                "recipients": update.recipients,
                "timestamp": Timestamp(date: update.timestamp)
            ]) { error in
                isLoading = false
                
                if let error = error {
                    // Handle error
                    return
                }
                
                sharedData.insert(update, at: 0)
                presentationMode.wrappedValue.dismiss()
            }
    }
}

struct RecipientRow: View {
    let name: String
    let email: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            HStack {
                Circle()
                    .fill(isSelected ? Color.pink : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppFont.body())
                        .foregroundColor(.black)
                    
                    Text(email)
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.pink : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct InvitePartnerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var name = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                        
                        Text("Invite Your Partner")
                            .font(AppFont.titleMedium())
                            .foregroundColor(.black)
                        
                        Text("Share your pregnancy journey with your partner")
                            .font(AppFont.body())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Partner Name
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Partner's Name")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            TextField("Enter partner's name", text: $name)
                                .font(AppFont.body())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email Address")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            TextField("Enter email address", text: $email)
                                .font(AppFont.body())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Message
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personal Message")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            TextField("Add a personal message (optional)", text: $message, axis: .vertical)
                                .font(AppFont.body())
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6).opacity(0.5))
            .navigationTitle("Invite Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invite") {
                        sendInvite()
                    }
                    .disabled(name.isEmpty || email.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func sendInvite() {
        isLoading = true
        
        // Simulate sending invite
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Data Models

struct SharedUpdate: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let type: UpdateType
    let recipients: [String]
    let timestamp: Date
}

enum UpdateType: String, CaseIterable, Codable {
    case milestone = "Milestone"
    case symptom = "Symptom"
    case appointment = "Appointment"
    case photo = "Photo"
    case general = "General"
}

#Preview {
    PartnerSharingView()
}

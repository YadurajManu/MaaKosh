//
//  ProfileView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Medical Record Model
struct MedicalRecord: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var condition: String
    var diagnosisDate: Date
    var medication: String
    var notes: String
    var isActive: Bool
    var createdAt: Date = Date()
    
    // For Firestore conversion
    var dictionary: [String: Any] {
        return [
            "id": id,
            "condition": condition,
            "diagnosisDate": diagnosisDate,
            "medication": medication,
            "notes": notes,
            "isActive": isActive,
            "createdAt": createdAt
        ]
    }
    
    // Add Equatable implementation
    static func == (lhs: MedicalRecord, rhs: MedicalRecord) -> Bool {
        return lhs.id == rhs.id
    }
}

// Emergency Contact Model
struct EmergencyContact: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var relationship: String
    var phoneNumber: String
    var isEmergencyContact: Bool = true
    var createdAt: Date = Date()
    
    // For Firestore conversion
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "relationship": relationship,
            "phoneNumber": phoneNumber,
            "isEmergencyContact": isEmergencyContact,
            "createdAt": createdAt
        ]
    }
    
    // Add Equatable implementation
    static func == (lhs: EmergencyContact, rhs: EmergencyContact) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ProfileView: View {
    @State private var userProfile = UserProfile()
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEditMode = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    
    // Animation states
    @State private var profileOpacity = 0.0
    @State private var profileOffset: CGFloat = 30
    @State private var sectionsOpacity = 0.0
    @State private var heartbeat = false
    
    // Add state variables for re-authentication
    @State private var showReauthDialog = false
    @State private var password = ""
    
    // Add models and state for medical history
    @State private var medicalRecords: [MedicalRecord] = []
    @State private var showAddMedicalRecord = false
    @State private var isLoadingRecords = false
    
    // Add models and state for emergency contacts
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var showAddEmergencyContact = false
    @State private var isLoadingContacts = false
    @State private var selectedEmergencyContact: EmergencyContact?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background gradient
                backgroundGradient
                
                if isLoading && userProfile.age == 0 {
                    loadingView
                } else {
                    contentScrollView
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(AppFont.titleMedium())
                        .foregroundColor(Color.maakoshDeepPink)
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .confirmationDialog("Are you sure you want to sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Are you sure you want to delete your account? This action cannot be undone.", isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isEditMode) {
                ProfileEditView(userProfile: $userProfile)
            }
            // Add the re-authentication dialog to the view
            .alert("Re-enter Password", isPresented: $showReauthDialog) {
                SecureField("Password", text: $password)
                Button("Cancel", role: .cancel) {
                    password = ""
                    isLoading = false
                }
                Button("Confirm", action: reauthenticateAndDelete)
            } message: {
                Text("For security, please re-enter your password to delete your account.")
            }
            // Add sheet for medical record form
            .sheet(isPresented: $showAddMedicalRecord) {
                MedicalRecordFormView(
                    isPresented: $showAddMedicalRecord, 
                    onSave: addMedicalRecord,
                    onDelete: deleteMedicalRecord
                )
            }
            // Add sheet for emergency contact form
            .sheet(isPresented: $showAddEmergencyContact) {
                EmergencyContactFormView(
                    isPresented: $showAddEmergencyContact,
                    contact: selectedEmergencyContact,
                    onSave: addEmergencyContact,
                    onDelete: deleteEmergencyContact
                )
            }
        }
    }
    
    // MARK: - View Components
    
    // Background gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.white, Color.maakoshLightPink.opacity(0.3)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Loading animation view
    private var loadingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.maakoshDeepPink)
                .scaleEffect(heartbeat ? 1.2 : 1.0)
                .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: heartbeat)
                .onAppear {
                    heartbeat = true
                }
            
            Text("Loading your profile...")
                .font(AppFont.body())
                .foregroundColor(Color.black.opacity(0.6))
        }
    }
    
    // Main content scroll view
    private var contentScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                // Profile header with avatar
                profileHeaderView
                    .opacity(profileOpacity)
                    .offset(y: profileOffset)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            profileOpacity = 1.0
                            profileOffset = 0
                        }
                    }
                
                // Information sections
                informationSections
            }
            .padding(.bottom, 30)
        }
    }
    
    // Information sections container
    private var informationSections: some View {
        VStack(spacing: 20) {
            // Personal Information
            personalInfoSection
            
            // Health Information
            healthInfoSection
            
            // Pregnancy Information
            pregnancyInfoSection
            
            // Emergency Contacts Section
            emergencyContactsSection
            
            // Medical History
            medicalHistorySection
            
            // Account Actions
            accountActionsSection
        }
        .padding(.horizontal, 20)
        .opacity(sectionsOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                sectionsOpacity = 1.0
            }
            loadUserProfile()
            loadMedicalRecords()
            loadEmergencyContacts()
        }
    }
    
    // Personal information section
    private var personalInfoSection: some View {
        ProfileCard(icon: "person.fill", title: "Personal") {
            VStack(spacing: 0) {
                MinimalInfoRow(label: "Age", value: "\(userProfile.age) years")
                Divider().background(Color.gray.opacity(0.1))
                MinimalInfoRow(label: "Phone", value: userProfile.phoneNumber.isEmpty ? "Not set" : userProfile.phoneNumber)
                if !userProfile.partnerName.isEmpty {
                    Divider().background(Color.gray.opacity(0.1))
                    MinimalInfoRow(label: "Partner", value: userProfile.partnerName)
                }
            }
        }
    }
    
    // Health information section
    private var healthInfoSection: some View {
        ProfileCard(icon: "heart.fill", title: "Health") {
            VStack(spacing: 0) {
                MinimalInfoRow(label: "Last Period", value: formatDate(userProfile.lastPeriodDate))
                Divider().background(Color.gray.opacity(0.1))
                MinimalInfoRow(label: "Cycle Length", value: "\(userProfile.cycleLengthInDays) days")
            }
        }
    }
    
    // Pregnancy information section
    private var pregnancyInfoSection: some View {
        ProfileCard(icon: "clock.fill", title: "Pregnancy") {
            VStack(spacing: 15) {
                HStack {
                    Text("Due Date")
                        .font(AppFont.caption())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(userProfile.estimatedDueDate))
                        .font(AppFont.caption())
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                // Week progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(userProfile.currentPregnancyWeek) of 40")
                            .font(AppFont.body())
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int((Double(userProfile.currentPregnancyWeek) / 40.0) * 100))%")
                            .font(AppFont.body())
                            .foregroundColor(Color.maakoshDeepPink)
                            .fontWeight(.medium)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .frame(height: 8)
                                .foregroundColor(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: min(CGFloat(userProfile.currentPregnancyWeek) / 40.0 * geometry.size.width, geometry.size.width), height: 8)
                                .foregroundColor(Color.maakoshDeepPink)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    // Emergency contacts section
    private var emergencyContactsSection: some View {
        ProfileCard(icon: "phone.fill.badge.plus", title: "Emergency Contacts") {
            VStack(spacing: 0) {
                if emergencyContacts.isEmpty {
                    emptyEmergencyContactsView
                } else {
                    emergencyContactsList
                }
                
                // Add contact button
                addEmergencyContactButton
            }
        }
    }
    
    // Empty emergency contacts view
    private var emptyEmergencyContactsView: some View {
        HStack {
            Text("No emergency contacts added")
                .font(AppFont.body())
                .foregroundColor(.secondary)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // Emergency contacts list
    private var emergencyContactsList: some View {
        let sortedContacts = emergencyContacts.sorted(by: { $0.createdAt > $1.createdAt })
        return ForEach(sortedContacts) { contact in
            Group {
                if contact != sortedContacts.first {
                    Divider().background(Color.gray.opacity(0.1))
                }
                
                Button(action: {
                    // Show edit view for this contact
                    selectedEmergencyContact = contact
                    showAddEmergencyContact = true
                }) {
                    emergencyContactRow(contact)
                }
            }
        }
    }
    
    // Individual emergency contact row
    private func emergencyContactRow(_ contact: EmergencyContact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(contact.name)
                    .font(AppFont.body())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Relationship indicator
                Text(contact.relationship)
                    .font(AppFont.small())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.maakoshDeepPink)
                    .cornerRadius(10)
            }
            
            HStack {
                Text(contact.phoneNumber)
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    callEmergencyContact(contact.phoneNumber)
                }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.maakoshDeepPink)
                        .padding(6)
                        .background(Color.maakoshLightPink.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    
    // Add emergency contact button
    private var addEmergencyContactButton: some View {
        Button(action: {
            selectedEmergencyContact = nil
            showAddEmergencyContact = true
        }) {
            HStack {
                Spacer()
                
                Text("Add Emergency Contact")
                    .font(AppFont.body())
                    .foregroundColor(Color.maakoshDeepPink)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.maakoshLightPink.opacity(0.1))
        }
    }
    
    // Medical history section
    private var medicalHistorySection: some View {
        ProfileCard(icon: "cross.case.fill", title: "Medical History") {
            VStack(spacing: 0) {
                if medicalRecords.isEmpty {
                    emptyMedicalRecordsView
                } else {
                    medicalRecordsList
                }
                
                // Add record button
                addMedicalRecordButton
            }
        }
    }
    
    // Empty medical records view
    private var emptyMedicalRecordsView: some View {
        HStack {
            Text("No medical records added")
                .font(AppFont.body())
                .foregroundColor(.secondary)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // Medical records list
    private var medicalRecordsList: some View {
        let sortedRecords = medicalRecords.sorted(by: { $0.createdAt > $1.createdAt })
        return ForEach(sortedRecords) { record in
            Group {
                if record != sortedRecords.first {
                    Divider().background(Color.gray.opacity(0.1))
                }
                
                Button(action: {
                    // Show edit view for this record
                    editMedicalRecord(record)
                }) {
                    medicalRecordRow(record)
                }
            }
        }
    }
    
    // Individual medical record row
    private func medicalRecordRow(_ record: MedicalRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.condition)
                    .font(AppFont.body())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Status indicator
                if record.isActive {
                    Text("Active")
                        .font(AppFont.small())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.maakoshDeepPink)
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Text("Diagnosed: \(formatDateShort(record.diagnosisDate))")
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    
    // Add medical record button
    private var addMedicalRecordButton: some View {
        Button(action: {
            showAddMedicalRecord = true
        }) {
            HStack {
                Spacer()
                
                Text("Add Medical Record")
                    .font(AppFont.body())
                    .foregroundColor(Color.maakoshDeepPink)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.maakoshLightPink.opacity(0.1))
        }
    }
    
    // Account actions section
    private var accountActionsSection: some View {
        ProfileCard(icon: "gear", title: "Account") {
            VStack(spacing: 0) {
                Button(action: {
                    isEditMode = true
                }) {
                    MinimalActionRow(
                        label: "Edit Profile",
                        icon: "pencil",
                        color: .primary
                    )
                }
                
                Divider().background(Color.gray.opacity(0.1))
                
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    MinimalActionRow(
                        label: "Sign Out",
                        icon: "arrow.right.square",
                        color: .red
                    )
                }
                
                Divider().background(Color.gray.opacity(0.1))
                
                Button(action: {
                    showDeleteAccountConfirmation = true
                }) {
                    MinimalActionRow(
                        label: "Delete Account",
                        icon: "trash.fill",
                        color: .red
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserProfile() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error loading profile: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = document, document.exists else {
                alertMessage = "Profile not found."
                showAlert = true
                return
            }
            
            // Set fullName property on UserProfile
            if let fullName = document.data()?["fullName"] as? String {
                self.userProfile.fullName = fullName
            }
            
            if let age = document.data()?["age"] as? Int {
                self.userProfile.age = age
            }
            
            if let phoneNumber = document.data()?["phoneNumber"] as? String {
                self.userProfile.phoneNumber = phoneNumber
            }
            
            if let partnerName = document.data()?["partnerName"] as? String {
                self.userProfile.partnerName = partnerName
            }
            
            if let lastPeriodDateTimestamp = document.data()?["lastPeriodDate"] as? Timestamp {
                self.userProfile.lastPeriodDate = lastPeriodDateTimestamp.dateValue()
            }
            
            if let cycleLengthInDays = document.data()?["cycleLengthInDays"] as? Int {
                self.userProfile.cycleLengthInDays = cycleLengthInDays
            }
        }
    }
    
    private func getInitials() -> String {
        if userProfile.fullName.isEmpty {
            return "M"
        }
        
        let components = userProfile.fullName.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = components.first?.first {
            return "\(first)"
        }
        
        return "M"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate back to auth view
            NotificationCenter.default.post(name: Notification.Name("UserDidSignOut"), object: nil)
        } catch {
            alertMessage = "Error signing out: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Try deleting first - if it fails with credential error, then prompt for re-auth
        user.delete { [self] error in
            if let error = error as NSError? {
                isLoading = false
                
                // Check if error is due to requiring recent authentication
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // Need to re-authenticate first
                    showReauthDialog = true
                } else {
                    // Some other error
                    alertMessage = "Failed to delete account: \(error.localizedDescription)"
                    showAlert = true
                }
            } else {
                // Success case - user deleted but we still need to clean up Firestore
                deleteUserData(userId: user.uid)
            }
        }
    }
    
    // Add method to re-authenticate user
    private func reauthenticateAndDelete() {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            alertMessage = "Current user information not available."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create credential
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        // Re-authenticate
        user.reauthenticate(with: credential) { [self] _, error in
            if let error = error {
                isLoading = false
                alertMessage = "Re-authentication failed: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            // Re-authentication successful, now delete the user
            user.delete { [self] error in
                if let error = error {
                    isLoading = false
                    alertMessage = "Failed to delete account: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    // User deleted successfully, now delete user data
                    deleteUserData(userId: user.uid)
                }
            }
        }
    }
    
    // Separate method to delete user data
    private func deleteUserData(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).delete { [self] error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Account deleted but failed to remove data: \(error.localizedDescription)"
                showAlert = true
            }
            
            // Clear local data
            UserDefaults.standard.removeObject(forKey: "userFullName")
            UserDefaults.standard.removeObject(forKey: "userProfileImage")
            
            // Return to auth screen
            NotificationCenter.default.post(name: Notification.Name("UserDidSignOut"), object: nil)
        }
    }
    
    // Add helper methods for medical records
    private func loadMedicalRecords() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        isLoadingRecords = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("medicalRecords")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                isLoadingRecords = false
                
                if let error = error {
                    alertMessage = "Failed to load medical records: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                var records: [MedicalRecord] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let id = data["id"] as? String,
                          let condition = data["condition"] as? String,
                          let medication = data["medication"] as? String,
                          let notes = data["notes"] as? String,
                          let isActive = data["isActive"] as? Bool else {
                        continue
                    }
                    
                    let diagnosisDate = (data["diagnosisDate"] as? Timestamp)?.dateValue() ?? Date()
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let record = MedicalRecord(
                        id: id,
                        condition: condition,
                        diagnosisDate: diagnosisDate,
                        medication: medication,
                        notes: notes,
                        isActive: isActive,
                        createdAt: createdAt
                    )
                    
                    records.append(record)
                }
                
                self.medicalRecords = records
            }
    }
    
    private func addMedicalRecord(_ record: MedicalRecord) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("medicalRecords")
            .document(record.id)
            .setData(record.dictionary) { error in
                if let error = error {
                    alertMessage = "Failed to save medical record: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Add to local array
                if let index = medicalRecords.firstIndex(where: { $0.id == record.id }) {
                    medicalRecords[index] = record
                } else {
                    medicalRecords.append(record)
                }
            }
    }
    
    private func editMedicalRecord(_ record: MedicalRecord) {
        // In a real app, you'd use a binding or state to track the record being edited
        // For simplicity, we'll just show the form with the existing record
        let editingSheet = MedicalRecordFormView(
            isPresented: $showAddMedicalRecord,
            record: record,
            onSave: addMedicalRecord,
            onDelete: deleteMedicalRecord
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let hostingController = UIHostingController(rootView: editingSheet)
            rootViewController.present(hostingController, animated: true)
        }
    }
    
    private func deleteMedicalRecord(_ record: MedicalRecord) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("medicalRecords")
            .document(record.id)
            .delete { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Failed to delete medical record: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Remove from local array and show success message
                if let index = medicalRecords.firstIndex(where: { $0.id == record.id }) {
                    medicalRecords.remove(at: index)
                    alertMessage = "Medical record deleted successfully"
                    showAlert = true
                }
            }
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Profile header view
    private var profileHeaderView: some View {
        VStack(spacing: 20) {
            // Avatar circle with shadow and border
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Initials or profile image
                if let imageData = UserDefaults.standard.data(forKey: "userProfileImage"),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 94, height: 94)
                        .clipShape(Circle())
                } else {
                    Text(getInitials())
                        .font(.system(size: 38, weight: .medium, design: .rounded))
                        .foregroundColor(Color.maakoshDeepPink)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            
            // User info
            VStack(spacing: 5) {
                Text(userProfile.fullName.isEmpty ? "Your Name" : userProfile.fullName)
                    .font(AppFont.titleMedium())
                    .foregroundColor(.primary)
                
                Text(Auth.auth().currentUser?.email ?? "")
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 10)
    }
    
    private func loadEmergencyContacts() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        isLoadingContacts = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("emergencyContacts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                isLoadingContacts = false
                
                if let error = error {
                    alertMessage = "Failed to load emergency contacts: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                var contacts: [EmergencyContact] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let relationship = data["relationship"] as? String,
                          let phoneNumber = data["phoneNumber"] as? String,
                          let isEmergencyContact = data["isEmergencyContact"] as? Bool else {
                        continue
                    }
                    
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let contact = EmergencyContact(
                        id: id,
                        name: name,
                        relationship: relationship,
                        phoneNumber: phoneNumber,
                        isEmergencyContact: isEmergencyContact,
                        createdAt: createdAt
                    )
                    
                    contacts.append(contact)
                }
                
                self.emergencyContacts = contacts
            }
    }
    
    private func addEmergencyContact(_ contact: EmergencyContact) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("emergencyContacts")
            .document(contact.id)
            .setData(contact.dictionary) { error in
                if let error = error {
                    alertMessage = "Failed to save emergency contact: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Add to local array
                if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                    emergencyContacts[index] = contact
                } else {
                    emergencyContacts.append(contact)
                }
            }
    }
    
    private func deleteEmergencyContact(_ contact: EmergencyContact) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("emergencyContacts")
            .document(contact.id)
            .delete { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Failed to delete emergency contact: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Remove from local array and show success message
                if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
                    emergencyContacts.remove(at: index)
                    alertMessage = "Emergency contact deleted successfully"
                    showAlert = true
                }
            }
    }
    
    private func callEmergencyContact(_ phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") else {
            alertMessage = "Unable to make call"
            showAlert = true
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            alertMessage = "Unable to make call"
            showAlert = true
        }
    }
}

// MARK: - Supporting Views

// Minimal Profile Card
struct ProfileCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text(title)
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.maakoshDeepPink)
            }
            .padding(.horizontal, 5)
            
            // Card content
            content
                .background(Color.white)
                .cornerRadius(12)
        }
        .animation(.easeInOut, value: title)
    }
}

// Minimal Info Row
struct MinimalInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.body())
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(AppFont.body())
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// Minimal Action Row
struct MinimalActionRow: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(AppFont.body())
                .foregroundColor(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(color.opacity(0.5))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// Profile Edit View with minimalist design
struct ProfileEditView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedProfile = UserProfile()
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Avatar with edit button
                        ZStack {
                            Circle()
                                .fill(Color.maakoshLightPink.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Text(getInitials())
                                .font(.system(size: 38, weight: .medium))
                                .foregroundColor(Color.maakoshDeepPink)
                            
                            // Edit button overlay
                            Circle()
                                .fill(Color.maakoshDeepPink)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 35, y: 35)
                                .opacity(0.9)
                        }
                        .padding(.top, 20)
                        
                        // Edit form
                        VStack(spacing: 20) {
                            // Personal Information
                            EditSection(title: "Personal Information") {
                                // Full Name
                                EditTextField(
                                    icon: "person.fill",
                                    label: "Full Name",
                                    text: $editedProfile.fullName,
                                    placeholder: "Your name"
                                )
                                
                                // Age
                                EditTextField(
                                    icon: "number",
                                    label: "Age",
                                    text: Binding(
                                        get: { editedProfile.age > 0 ? "\(editedProfile.age)" : "" },
                                        set: { 
                                            if let value = Int($0) {
                                                editedProfile.age = value
                                            }
                                        }
                                    ),
                                    placeholder: "Your age",
                                    keyboardType: .numberPad
                                )
                                
                                // Phone Number
                                EditTextField(
                                    icon: "phone.fill",
                                    label: "Phone Number",
                                    text: $editedProfile.phoneNumber,
                                    placeholder: "Your phone number",
                                    keyboardType: .phonePad
                                )
                                
                                // Partner Name
                                EditTextField(
                                    icon: "person.2.fill",
                                    label: "Partner's Name (Optional)",
                                    text: $editedProfile.partnerName,
                                    placeholder: "Partner's name"
                                )
                            }
                            
                            // Health Information
                            EditSection(title: "Health Information") {
                                // Last Period Date
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Menstrual Period")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        withAnimation {
                                            showDatePicker.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "calendar")
                                                .foregroundColor(Color.maakoshDeepPink)
                                            
                                            Text(formatDate(editedProfile.lastPeriodDate))
                                                .font(AppFont.body())
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.secondary)
                                                .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                                        }
                                        .padding()
                                        .background(Color.maakoshLightPink.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                    
                                    if showDatePicker {
                                        DatePicker(
                                            "Select date",
                                            selection: $editedProfile.lastPeriodDate,
                                            in: ...Date(),
                                            displayedComponents: .date
                                        )
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                        .padding(.vertical, 10)
                                        .transition(.opacity)
                                    }
                                }
                                
                                // Cycle Length
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Cycle Length")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Picker("Cycle Length", selection: $editedProfile.cycleLengthInDays) {
                                            ForEach(21...35, id: \.self) { days in
                                                Text("\(days) days").tag(days)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(maxHeight: 120)
                                        .clipped()
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: {
                            saveProfile()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text("Save Changes")
                                    .font(AppFont.buttonText())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.maakoshDeepPink)
                            .cornerRadius(12)
                            .shadow(color: Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        .disabled(isLoading)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Profile")
                        .font(AppFont.titleMedium())
                        .foregroundColor(Color.maakoshDeepPink)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.maakoshDeepPink)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                editedProfile = userProfile
            }
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        editedProfile.saveToFirestore(userId: user.uid) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                userProfile = editedProfile
                dismiss()
            }
        }
    }
    
    private func getInitials() -> String {
        if editedProfile.fullName.isEmpty {
            return "M"
        }
        
        let components = editedProfile.fullName.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = components.first?.first {
            return "\(first)"
        }
        
        return "M"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Edit Section Container
struct EditSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(AppFont.titleSmall())
                .foregroundColor(Color.maakoshDeepPink)
                .padding(.leading, 5)
            
            VStack(spacing: 15) {
                content
            }
            .padding(.vertical, 5)
        }
    }
}

// Edit Text Field
struct EditTextField: View {
    let icon: String
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color.maakoshDeepPink)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(AppFont.body())
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(Color.maakoshLightPink.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// Extension to add fullName property to UserProfile
extension UserProfile {
    var fullName: String {
        get {
            UserDefaults.standard.string(forKey: "userFullName") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userFullName")
        }
    }
}

// Add MedicalRecordFormView at the end of the file
struct MedicalRecordFormView: View {
    @Binding var isPresented: Bool
    @State private var record: MedicalRecord
    let onSave: (MedicalRecord) -> Void
    let onDelete: (MedicalRecord) -> Void
    
    // Individual state variables for each field to prevent resetting
    @State private var condition: String = ""
    @State private var medication: String = ""
    @State private var notes: String = ""
    @State private var diagnosisDate: Date = Date()
    @State private var isActive: Bool = true
    
    @State private var showDatePicker = false
    @State private var isLoading = false
    
    init(isPresented: Binding<Bool>, record: MedicalRecord? = nil, onSave: @escaping (MedicalRecord) -> Void, onDelete: @escaping (MedicalRecord) -> Void = { _ in }) {
        self._isPresented = isPresented
        self.onSave = onSave
        self.onDelete = onDelete
        
        if let record = record {
            self._record = State(initialValue: record)
            self._condition = State(initialValue: record.condition)
            self._medication = State(initialValue: record.medication)
            self._notes = State(initialValue: record.notes)
            self._diagnosisDate = State(initialValue: record.diagnosisDate)
            self._isActive = State(initialValue: record.isActive)
        } else {
            let emptyRecord = MedicalRecord(
                condition: "",
                diagnosisDate: Date(),
                medication: "",
                notes: "",
                isActive: true
            )
            self._record = State(initialValue: emptyRecord)
            self._condition = State(initialValue: "")
            self._medication = State(initialValue: "")
            self._notes = State(initialValue: "")
            self._diagnosisDate = State(initialValue: Date())
            self._isActive = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form fields
                        EditSection(title: "Medical Condition") {
                            // Condition Name
                            EditTextField(
                                icon: "staroflife",
                                label: "Condition Name",
                                text: $condition,
                                placeholder: "Enter medical condition"
                            )
                            
                            // Diagnosis Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Diagnosis Date")
                                    .font(AppFont.caption())
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    withAnimation {
                                        showDatePicker.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(Color.maakoshDeepPink)
                                        
                                        Text(formatDate(diagnosisDate))
                                            .font(AppFont.body())
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                                    }
                                    .padding()
                                    .background(Color.maakoshLightPink.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                
                                if showDatePicker {
                                    DatePicker(
                                        "Select date",
                                        selection: $diagnosisDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .padding(.vertical, 10)
                                    .transition(.opacity)
                                }
                            }
                            
                            // Medication
                            EditTextField(
                                icon: "pill.fill",
                                label: "Medication",
                                text: $medication,
                                placeholder: "Enter current medication"
                            )
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(AppFont.caption())
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $notes)
                                    .font(AppFont.body())
                                    .padding(10)
                                    .frame(minHeight: 100)
                                    .background(Color.maakoshLightPink.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            // Status Toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .font(AppFont.caption())
                                    .foregroundColor(.secondary)
                                
                                Toggle(isOn: $isActive) {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(isActive ? .green : .gray)
                                        
                                        Text(isActive ? "Active Condition" : "Past Condition")
                                            .font(AppFont.body())
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.maakoshDeepPink))
                                .padding()
                                .background(Color.maakoshLightPink.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Save Button
                        Button(action: {
                            // Create a new record with the current field values
                            let updatedRecord = MedicalRecord(
                                id: record.id,
                                condition: condition,
                                diagnosisDate: diagnosisDate,
                                medication: medication,
                                notes: notes,
                                isActive: isActive,
                                createdAt: record.createdAt
                            )
                            
                            isLoading = true
                            onSave(updatedRecord)
                            isPresented = false
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text("Save Medical Record")
                                    .font(AppFont.buttonText())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(condition.isEmpty ? Color.gray : Color.maakoshDeepPink)
                            .cornerRadius(12)
                            .shadow(color: condition.isEmpty ? Color.clear : Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(condition.isEmpty || isLoading)
                        
                        // Delete Button (for editing only)
                        if !record.id.isEmpty {
                            Button(action: {
                                // Show confirmation dialog
                                showDeleteConfirmation()
                            }) {
                                Text("Delete Record")
                                    .font(AppFont.body())
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(record.id.isEmpty ? "Add Medical Record" : "Edit Medical Record")
                        .font(AppFont.titleMedium())
                        .foregroundColor(Color.maakoshDeepPink)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.maakoshDeepPink)
                    }
                }
            }
            .onAppear {
                // Initialize state variables with record values
                if condition.isEmpty {
                    condition = record.condition
                    medication = record.medication
                    notes = record.notes
                    diagnosisDate = record.diagnosisDate
                    isActive = record.isActive
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func showDeleteConfirmation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let confirmationAlert = UIAlertController(
            title: "Delete Medical Record",
            message: "Are you sure you want to delete this medical record? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        confirmationAlert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))
        
        confirmationAlert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                // Pass the record to delete to the onDelete handler
                onDelete(record)
                isPresented = false
            }
        ))
        
        rootViewController.present(confirmationAlert, animated: true)
    }
}

// EmergencyContactFormView for adding/editing emergency contacts
struct EmergencyContactFormView: View {
    @Binding var isPresented: Bool
    var contact: EmergencyContact?
    var onSave: (EmergencyContact) -> Void
    var onDelete: ((EmergencyContact) -> Void)?
    
    @State private var name: String = ""
    @State private var relationship: String = ""
    @State private var phoneNumber: String = ""
    @State private var isEmergencyContact: Bool = true
    
    @State private var showingDeleteAlert = false
    @FocusState private var focusedField: Field?
    
    // For keyboard focus management
    enum Field: Hashable {
        case name, relationship, phone
    }
    
    // Relationship options
    let relationshipOptions = ["Spouse", "Partner", "Parent", "Sibling", "Friend", "Doctor", "Other"]
    
    // Check if the form is in edit mode
    private var isEditMode: Bool {
        return contact != nil
    }
    
    // Validation
    private var isFormValid: Bool {
        return !name.isEmpty && !relationship.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form fields
                        VStack(spacing: 20) {
                            // Name field
                            FormField(
                                icon: "person.fill",
                                title: "Name",
                                placeholder: "Contact name",
                                text: $name,
                                keyboardType: .default
                            )
                            .focused($focusedField, equals: .name)
                            
                            // Relationship field with picker
                            Menu {
                                ForEach(relationshipOptions, id: \.self) { option in
                                    Button(action: {
                                        relationship = option
                                    }) {
                                        HStack {
                                            Text(option)
                                            if relationship == option {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                FormFieldLabel(
                                    icon: "person.2.fill",
                                    title: "Relationship",
                                    value: relationship.isEmpty ? "Select relationship" : relationship,
                                    placeholder: relationship.isEmpty
                                )
                            }
                            
                            // Phone number field
                            FormField(
                                icon: "phone.fill",
                                title: "Phone Number",
                                placeholder: "Contact phone number",
                                text: $phoneNumber,
                                keyboardType: .phonePad
                            )
                            .focused($focusedField, equals: .phone)
                            
                            // Priority toggle
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.maakoshDeepPink.opacity(0.7))
                                    
                                    Text("Emergency Contact")
                                        .font(AppFont.body())
                                        .foregroundColor(Color.primary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $isEmergencyContact)
                                        .toggleStyle(SwitchToggleStyle(tint: Color.maakoshDeepPink))
                                }
                                
                                if isEmergencyContact {
                                    Text("This contact will be shown prominently in case of emergency")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 26)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Call now button for edit mode
                        if isEditMode {
                            Button(action: {
                                guard let contact = contact else { return }
                                callEmergencyContact(contact.phoneNumber)
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.white)
                                    
                                    Text("Call Now")
                                        .foregroundColor(.white)
                                        .font(AppFont.body())
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Delete button for edit mode
                        if isEditMode, let onDelete = onDelete {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.white)
                                    
                                    Text("Delete Contact")
                                        .foregroundColor(.white)
                                        .font(AppFont.body())
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .alert(isPresented: $showingDeleteAlert) {
                                Alert(
                                    title: Text("Delete Contact"),
                                    message: Text("Are you sure you want to delete this emergency contact? This action cannot be undone."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        if let contact = contact {
                                            onDelete(contact)
                                            isPresented = false
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationBarTitle(isEditMode ? "Edit Emergency Contact" : "New Emergency Contact", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveContact()
                        }
                        .disabled(!isFormValid)
                    }
                    
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focusedField = nil
                            }
                        }
                    }
                }
                .onAppear {
                    loadContactData()
                }
            }
        }
    }
    
    // Load existing contact data if in edit mode
    private func loadContactData() {
        if let contact = contact {
            name = contact.name
            relationship = contact.relationship
            phoneNumber = contact.phoneNumber
            isEmergencyContact = contact.isEmergencyContact
            
            // Set initial focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusedField = .name
            }
        } else {
            // Set initial focus for new contact
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusedField = .name
            }
        }
    }
    
    // Save the contact
    private func saveContact() {
        let savedContact = EmergencyContact(
            id: contact?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: relationship,
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            isEmergencyContact: isEmergencyContact,
            createdAt: contact?.createdAt ?? Date()
        )
        
        onSave(savedContact)
        isPresented = false
    }
    
    // Call emergency contact
    private func callEmergencyContact(_ phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// Form field with label and icon
struct FormField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.maakoshDeepPink.opacity(0.7))
                
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(Color.primary)
            }
            
            TextField(placeholder, text: $text)
                .font(AppFont.body())
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                .keyboardType(keyboardType)
        }
    }
}

// Form field label for menus
struct FormFieldLabel: View {
    let icon: String
    let title: String
    let value: String
    let placeholder: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.maakoshDeepPink.opacity(0.7))
                
                Text(title)
                    .font(AppFont.body())
                    .foregroundColor(Color.primary)
            }
            
            HStack {
                Text(value)
                    .font(AppFont.body())
                    .foregroundColor(placeholder ? .gray : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

// Dashboard Emergency Contacts component for quick access
struct DashboardEmergencyContacts: View {
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Emergency Contacts")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "phone.fill.badge.plus")
                    .foregroundColor(Color.maakoshDeepPink)
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if emergencyContacts.isEmpty {
                emptyContactsView
            } else {
                contactsScrollView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .onAppear {
            loadEmergencyContacts()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // Empty state view
    private var emptyContactsView: some View {
        VStack(spacing: 10) {
            Text("No emergency contacts")
                .foregroundColor(.secondary)
                .font(AppFont.body())
            
            Text("Add contacts in your profile")
                .foregroundColor(.secondary)
                .font(AppFont.caption())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }
    
    // Horizontal scrolling contacts
    private var contactsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(emergencyContacts.filter { $0.isEmergencyContact }) { contact in
                    contactCard(contact)
                }
            }
        }
    }
    
    // Individual contact card
    private func contactCard(_ contact: EmergencyContact) -> some View {
        Button(action: {
            callEmergencyContact(contact.phoneNumber)
        }) {
            VStack(alignment: .center, spacing: 8) {
                // Contact avatar or initials
                ZStack {
                    Circle()
                        .fill(Color.maakoshLightPink.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Text(getInitials(from: contact.name))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.maakoshDeepPink)
                }
                
                Text(contact.name)
                    .font(AppFont.body())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(contact.relationship)
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Call button
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text("Call")
                        .font(AppFont.small())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.maakoshDeepPink)
                .cornerRadius(14)
            }
            .frame(width: 100)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Get initials from name
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = components.first?.first {
            return "\(first)"
        }
        return "?"
    }
    
    // Load emergency contacts from Firestore
    private func loadEmergencyContacts() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("emergencyContacts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Failed to load contacts: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var contacts: [EmergencyContact] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let relationship = data["relationship"] as? String,
                          let phoneNumber = data["phoneNumber"] as? String,
                          let isEmergencyContact = data["isEmergencyContact"] as? Bool else {
                        continue
                    }
                    
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let contact = EmergencyContact(
                        id: id,
                        name: name,
                        relationship: relationship,
                        phoneNumber: phoneNumber,
                        isEmergencyContact: isEmergencyContact,
                        createdAt: createdAt
                    )
                    
                    contacts.append(contact)
                }
                
                self.emergencyContacts = contacts
            }
    }
    
    // Call emergency contact
    private func callEmergencyContact(_ phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ProfileView()
} 

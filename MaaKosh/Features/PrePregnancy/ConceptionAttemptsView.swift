import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ConceptionAttemptsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddSheet = false
    @State private var attemptEntries: [ConceptionAttemptEntry] = []
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: ConceptionAttemptEntry?
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isLoading {
                    // Loading view
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.2)
                    Spacer()
                } else if attemptEntries.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Entries list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(attemptEntries) { entry in
                                attemptEntryCard(entry: entry)
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            entryToDelete = entry
                                            showingDeleteAlert = true
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                }
            }
            .onAppear {
                loadAttemptEntries()
            }
            .sheet(isPresented: $showAddSheet) {
                AddConceptionAttemptView(onSave: { entry in
                    addAttemptEntry(entry)
                })
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteAttemptEntry(entry)
                    }
                }
            }, message: {
                Text("Are you sure you want to delete this entry? This action cannot be undone.")
            })
            
            // Add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.leading, 4)
            }
            
            Spacer()
            
            Text("Conception Attempts")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // Filter options
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.trailing, 4)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 70))
                .foregroundColor(.pink.opacity(0.7))
                .padding()
            
            Text("No Entries Yet")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Text("Track your conception attempts to optimize your journey")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showAddSheet = true
            }) {
                Text("Add Your First Entry")
                    .font(AppFont.body().bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 25)
                    .background(Color.pink)
                    .cornerRadius(25)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private func attemptEntryCard(entry: ConceptionAttemptEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date and method
            HStack {
                Text(formatDate(entry.date))
                    .font(AppFont.body().bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                // Method badge
                Text(entry.method)
                    .font(AppFont.small().bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(20)
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Fertility indicators
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Fertility Window")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(entry.inFertileWindow ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                        
                        Text(entry.inFertileWindow ? "In Window" : "Outside Window")
                            .font(AppFont.body())
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, entry.notes.isEmpty ? 14 : 5)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Ovulation")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(entry.ovulationDay ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                        
                        Text(entry.ovulationDay ? "Ovulation Day" : "Not Ovulation")
                            .font(AppFont.body())
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, entry.notes.isEmpty ? 14 : 5)
            }
            .padding(.horizontal, 16)
            
            // Notes if available
            if !entry.notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Notes")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(entry.notes)
                        .font(AppFont.body())
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    private var addButton: some View {
        Button(action: {
            showAddSheet = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadAttemptEntries() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("conceptionAttempts")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error loading conception attempts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                self.attemptEntries = documents.compactMap { document -> ConceptionAttemptEntry? in
                    let data = document.data()
                    let id = document.documentID
                    let method = data["method"] as? String ?? ""
                    let inFertileWindow = data["inFertileWindow"] as? Bool ?? false
                    let ovulationDay = data["ovulationDay"] as? Bool ?? false
                    let notes = data["notes"] as? String ?? ""
                    
                    if let timestamp = data["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        return ConceptionAttemptEntry(
                            id: id,
                            date: date,
                            method: method,
                            inFertileWindow: inFertileWindow,
                            ovulationDay: ovulationDay,
                            notes: notes
                        )
                    }
                    
                    return nil
                }
            }
    }
    
    private func addAttemptEntry(_ entry: ConceptionAttemptEntry) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var updatedEntries = attemptEntries
        updatedEntries.insert(entry, at: 0)
        self.attemptEntries = updatedEntries
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("conceptionAttempts")
            .document(entry.id)
            .setData([
                "date": Timestamp(date: entry.date),
                "method": entry.method,
                "inFertileWindow": entry.inFertileWindow,
                "ovulationDay": entry.ovulationDay,
                "notes": entry.notes
            ])
    }
    
    private func deleteAttemptEntry(_ entry: ConceptionAttemptEntry) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove from local array
        attemptEntries.removeAll { $0.id == entry.id }
        
        // Remove from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("conceptionAttempts")
            .document(entry.id)
            .delete() { error in
                if let error = error {
                    print("Error deleting conception attempt: \(error.localizedDescription)")
                }
            }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Add Conception Attempt View

struct AddConceptionAttemptView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var attemptDate = Date()
    @State private var method = "Intercourse"
    @State private var inFertileWindow = false
    @State private var ovulationDay = false
    @State private var notes = ""
    
    var methodOptions = ["Intercourse", "Artificial Insemination", "IVF", "Other"]
    var onSave: (ConceptionAttemptEntry) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Date")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            DatePicker("", selection: $attemptDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        // Method picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Method")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            Picker("Method", selection: $method) {
                                ForEach(methodOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 5)
                        }
                        
                        // Fertility window toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fertility Tracking")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                Toggle("In Fertile Window", isOn: $inFertileWindow)
                                    .font(AppFont.body())
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .toggleStyle(SwitchToggleStyle(tint: .pink))
                                
                                Toggle("Ovulation Day", isOn: $ovulationDay)
                                    .font(AppFont.body())
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .toggleStyle(SwitchToggleStyle(tint: .pink))
                            }
                        }
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            TextEditor(text: $notes)
                                .font(AppFont.body())
                                .padding()
                                .frame(minHeight: 100)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        
                        // Save button
                        Button(action: {
                            saveEntry()
                        }) {
                            Text("Save Entry")
                                .font(AppFont.body().bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .cornerRadius(15)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add Conception Attempt")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let entry = ConceptionAttemptEntry(
            id: UUID().uuidString,
            date: attemptDate,
            method: method,
            inFertileWindow: inFertileWindow,
            ovulationDay: ovulationDay,
            notes: notes
        )
        
        onSave(entry)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Model

struct ConceptionAttemptEntry: Identifiable {
    let id: String
    let date: Date
    let method: String
    let inFertileWindow: Bool
    let ovulationDay: Bool
    let notes: String
} 
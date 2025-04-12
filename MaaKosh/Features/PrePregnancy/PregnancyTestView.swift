import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PregnancyTestView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddSheet = false
    @State private var testEntries: [PregnancyTestEntry] = []
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: PregnancyTestEntry?
    
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
                } else if testEntries.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Test entries list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(testEntries) { entry in
                                testEntryCard(entry: entry)
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
                loadTestEntries()
            }
            .sheet(isPresented: $showAddSheet) {
                AddPregnancyTestView(onSave: { entry in
                    addTestEntry(entry)
                })
            }
            .alert("Delete Test Entry", isPresented: $showingDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteTestEntry(entry)
                    }
                }
            }, message: {
                Text("Are you sure you want to delete this test entry? This action cannot be undone.")
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
            
            Text("Pregnancy Test Entries")
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
            
            Image(systemName: "note.text")
                .font(.system(size: 70))
                .foregroundColor(.pink.opacity(0.7))
                .padding()
            
            Text("No Test Entries Yet")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Text("Track your pregnancy tests to monitor your journey")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showAddSheet = true
            }) {
                Text("Add Your First Test")
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
    
    private func testEntryCard(entry: PregnancyTestEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date and result
            HStack {
                Text(formatDate(entry.date))
                    .font(AppFont.body().bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                // Result badge
                Text(entry.result ? "Positive" : "Negative")
                    .font(AppFont.small().bold())
                    .foregroundColor(entry.result ? .white : .black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(entry.result ? Color.green : Color.gray.opacity(0.2))
                    .cornerRadius(20)
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Brand & type
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Brand")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(entry.brand.isEmpty ? "Not specified" : entry.brand)
                        .font(AppFont.body())
                        .foregroundColor(.black)
                }
                .padding(.top, 10)
                .padding(.bottom, entry.notes.isEmpty ? 14 : 5)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Test Type")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(entry.testType.isEmpty ? "Not specified" : entry.testType)
                        .font(AppFont.body())
                        .foregroundColor(.black)
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
    
    private func loadTestEntries() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("pregnancyTests")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error loading test entries: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                self.testEntries = documents.compactMap { document -> PregnancyTestEntry? in
                    let data = document.data()
                    let id = document.documentID
                    let result = data["result"] as? Bool ?? false
                    let brand = data["brand"] as? String ?? ""
                    let testType = data["testType"] as? String ?? ""
                    let notes = data["notes"] as? String ?? ""
                    
                    if let timestamp = data["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        return PregnancyTestEntry(id: id, date: date, result: result, brand: brand, testType: testType, notes: notes)
                    }
                    
                    return nil
                }
            }
    }
    
    private func addTestEntry(_ entry: PregnancyTestEntry) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var updatedEntries = testEntries
        updatedEntries.insert(entry, at: 0)
        self.testEntries = updatedEntries
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("pregnancyTests")
            .document(entry.id)
            .setData([
                "date": Timestamp(date: entry.date),
                "result": entry.result,
                "brand": entry.brand,
                "testType": entry.testType,
                "notes": entry.notes
            ])
    }
    
    private func deleteTestEntry(_ entry: PregnancyTestEntry) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove from local array
        testEntries.removeAll { $0.id == entry.id }
        
        // Remove from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("pregnancyTests")
            .document(entry.id)
            .delete() { error in
                if let error = error {
                    print("Error deleting test entry: \(error.localizedDescription)")
                }
            }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Add Pregnancy Test View

struct AddPregnancyTestView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var testDate = Date()
    @State private var result = false
    @State private var brand = ""
    @State private var testType = "Urine"
    @State private var notes = ""
    
    var testTypes = ["Urine", "Blood", "Digital", "Other"]
    var onSave: (PregnancyTestEntry) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Test Date")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            DatePicker("", selection: $testDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        // Result toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Result")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    result = false
                                }) {
                                    Text("Negative")
                                        .font(AppFont.body())
                                        .foregroundColor(result ? .gray : .white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 25)
                                        .background(!result ? Color.blue : Color.gray.opacity(0.2))
                                        .cornerRadius(25)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    result = true
                                }) {
                                    Text("Positive")
                                        .font(AppFont.body())
                                        .foregroundColor(result ? .white : .gray)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 25)
                                        .background(result ? Color.green : Color.gray.opacity(0.2))
                                        .cornerRadius(25)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        
                        // Brand input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Brand")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            TextField("e.g. Clearblue, First Response", text: $brand)
                                .font(AppFont.body())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        
                        // Test type picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Test Type")
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                            
                            Picker("Test Type", selection: $testType) {
                                ForEach(testTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 5)
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
            .navigationTitle("Add Test Entry")
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
        let entry = PregnancyTestEntry(
            id: UUID().uuidString,
            date: testDate,
            result: result,
            brand: brand,
            testType: testType,
            notes: notes
        )
        
        onSave(entry)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Model

struct PregnancyTestEntry: Identifiable {
    let id: String
    let date: Date
    let result: Bool
    let brand: String
    let testType: String
    let notes: String
} 
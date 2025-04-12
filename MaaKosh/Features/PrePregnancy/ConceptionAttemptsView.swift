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
    @State private var refreshing = false
    @State private var animate = false
    
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
                        .transition(.opacity)
                } else {
                    // Statistics dashboard
                    AttemptStatsDashboardView(entries: attemptEntries)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    
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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.9).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                                        removal: .scale(scale: 0.7).combined(with: .opacity).animation(.easeOut(duration: 0.2))
                                    ))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                        .refreshable {
                            withAnimation {
                                refreshing = true
                            }
                            await refreshData()
                            withAnimation {
                                refreshing = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        animate = true
                    }
                }
                loadAttemptEntries()
            }
            .onDisappear {
                animate = false
            }
            .sheet(isPresented: $showAddSheet) {
                AddConceptionAttemptView(onSave: { entry in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        addAttemptEntry(entry)
                    }
                })
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        withAnimation {
                            deleteAttemptEntry(entry)
                        }
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
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .opacity(animate ? 1.0 : 0.0)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    animate = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    presentationMode.wrappedValue.dismiss()
                }
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
                .rotationEffect(.degrees(animate ? 0 : -10))
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(Animation.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)
            
            Text("No Entries Yet")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.2), value: animate)
            
            Text("Track your conception attempts to optimize your journey")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.3), value: animate)
            
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
            .scaleEffect(animate ? 1.0 : 0.9)
            .opacity(animate ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3).delay(0.4), value: animate)
            
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
            hapticFeedback(style: .medium)
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
                withAnimation {
                    isLoading = false
                }
                
                if let error = error {
                    print("Error loading conception attempts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                withAnimation {
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
    
    private func refreshData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadAttemptEntries()
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Statistics Dashboard

struct AttemptStatsDashboardView: View {
    let entries: [ConceptionAttemptEntry]
    
    private var fertileWindowAttempts: Int {
        entries.filter { $0.inFertileWindow }.count
    }
    
    private var ovulationDayAttempts: Int {
        entries.filter { $0.ovulationDay }.count
    }
    
    private var methodsUsed: [String: Int] {
        var methods: [String: Int] = [:]
        for entry in entries {
            methods[entry.method, default: 0] += 1
        }
        return methods
    }
    
    private var mostUsedMethod: String {
        methodsUsed.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Conception Summary")
                    .font(AppFont.body().bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
            }
            .padding(.bottom, 2)
            
            HStack(spacing: 12) {
                StatBox(
                    title: "Total",
                    value: "\(entries.count)",
                    icon: "list.bullet.clipboard",
                    color: .purple
                )
                
                StatBox(
                    title: "Fertile Window",
                    value: "\(fertileWindowAttempts)",
                    icon: "calendar.badge.clock",
                    color: .green
                )
                
                StatBox(
                    title: "Ovulation Day",
                    value: "\(ovulationDayAttempts)",
                    icon: "star.fill",
                    color: .orange
                )
            }
            
            HStack {
                Text("Most Used Method:")
                    .font(AppFont.caption())
                    .foregroundColor(.gray)
                
                Text(mostUsedMethod)
                    .font(AppFont.caption().bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                
                Spacer()
                
                Text("\(calculateSuccessPercentage())% in Fertile Window")
                    .font(AppFont.caption().bold())
                    .foregroundColor(.green)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    private func calculateSuccessPercentage() -> Int {
        guard entries.count > 0 else { return 0 }
        return Int((Double(fertileWindowAttempts) / Double(entries.count)) * 100)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(AppFont.caption())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
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
    @State private var showingConfirmation = false
    
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
                                HStack {
                                    Text("In Fertile Window")
                                        .font(AppFont.body())
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $inFertileWindow)
                                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                                        .onChange(of: inFertileWindow) { newValue in
                                            // Provide haptic feedback when toggle changes
                                            hapticFeedback(style: .light)
                                            
                                            // If turning on ovulation, also turn on fertile window
                                            if !newValue {
                                                ovulationDay = false
                                            }
                                        }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(inFertileWindow ? Color.green.opacity(0.1) : Color.white)
                                .cornerRadius(8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: inFertileWindow)
                                
                                HStack {
                                    Text("Ovulation Day")
                                        .font(AppFont.body())
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $ovulationDay)
                                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                                        .onChange(of: ovulationDay) { newValue in
                                            // Provide haptic feedback when toggle changes
                                            hapticFeedback(style: .light)
                                            
                                            // If turning on ovulation, also turn on fertile window
                                            if newValue {
                                                inFertileWindow = true
                                            }
                                        }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(ovulationDay ? Color.orange.opacity(0.1) : Color.white)
                                .cornerRadius(8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: ovulationDay)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
                            hapticFeedback(style: .medium)
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
        .overlay(
            ZStack {
                if showingConfirmation {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Entry Added")
                            .font(AppFont.body().bold())
                            .padding(.top, 10)
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: showingConfirmation)
        )
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
        
        // Show confirmation
        withAnimation {
            showingConfirmation = true
        }
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showingConfirmation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSave(entry)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
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
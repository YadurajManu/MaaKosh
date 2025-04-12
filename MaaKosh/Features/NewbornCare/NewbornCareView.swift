//
//  NewbornCareView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// Baby Profile Model
struct BabyProfile: Codable {
    var name: String = ""
    var birthDate: Date = Date()
    var weight: Double = 0.0  // kg
    var height: Double = 0.0  // cm
    var headCircumference: Double = 0.0  // cm
    
    // Computed properties
    var ageInMonths: Int {
        let now = Date()
        let components = Calendar.current.dateComponents([.month], from: birthDate, to: now)
        return components.month ?? 0
    }
    
    var ageDescription: String {
        if ageInMonths == 0 {
            // Calculate age in weeks
            let components = Calendar.current.dateComponents([.day], from: birthDate, to: Date())
            let days = components.day ?? 0
            let weeks = days / 7
            return weeks == 1 ? "1 week old" : "\(weeks) weeks old"
        } else {
            return ageInMonths == 1 ? "1 month old" : "\(ageInMonths) months old"
        }
    }
}

// Feeding Record Model
struct FeedingRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    var type: FeedingType = .breastMilk
    var amount: Double? = nil  // ml (for formula or expressed milk)
    var duration: Int? = nil  // minutes (for breastfeeding)
    var notes: String = ""
    var foodType: String = ""  // for solid food
    
    enum FeedingType: String, Codable, CaseIterable {
        case breastMilk = "Breast Milk"
        case formula = "Formula"
        case expressedMilk = "Expressed Milk"
        case solidFood = "Solid Food"
        
        var icon: String {
            switch self {
            case .breastMilk: return "figure.wave"
            case .formula: return "drop.fill"
            case .expressedMilk: return "bolt.fill"
            case .solidFood: return "fork.knife"
            }
        }
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

// Vaccination Record Model
struct VaccinationRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var scheduledDate: Date
    var status: VaccinationStatus = .scheduled
    var notes: String = ""
    var location: String = ""
    
    enum VaccinationStatus: String, Codable, CaseIterable {
        case scheduled = "Scheduled"
        case completed = "Completed"
        case missed = "Missed"
        
        var color: Color {
            switch self {
            case .scheduled: return .yellow
            case .completed: return .pink
            case .missed: return .red
            }
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDate)
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: scheduledDate)
    }
}

// Growth Measurement Record
struct GrowthRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var weight: Double? = nil  // kg
    var height: Double? = nil  // cm
    var headCircumference: Double? = nil  // cm
    var notes: String = ""
}

struct NewbornCareView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var isLoading = true
    @State private var showProfileSetup = false
    @State private var babyProfile = BabyProfile()
    @State private var feedingRecords: [FeedingRecord] = []
    @State private var vaccinationRecords: [VaccinationRecord] = []
    @State private var growthRecords: [GrowthRecord] = []
    
    // Modal presentation state
    @State private var showAddVaccination = false
    @State private var showAddFeeding = false
    @State private var showAddGrowth = false
    @State private var showAllVaccinations = false
    @State private var editingVaccination: VaccinationRecord? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Gemini AI Baby Care state
    @State private var showGeminiAICare = false
    
    // Feeding counter for today
    private var todayFeedingCount: Int {
        let calendar = Calendar.current
        return feedingRecords.filter { calendar.isDateInToday($0.timestamp) }.count
    }
    
    // Sleep calculation (just a placeholder for now)
    private var todaySleepHours: Int {
        // Placeholder - would actually calculate based on sleep records
        return 3
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.cyan.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            if isLoading {
                loadingView
            } else if showProfileSetup {
                BabyProfileSetupView(
                    babyProfile: $babyProfile,
                    onComplete: {
                        saveBabyProfile()
                        showProfileSetup = false
                    }
                )
            } else {
                mainContent
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("MaaKosh"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Main Views
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading baby profile...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 12)
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Baby profile card
                babyProfileCard
                
                // Main feature cards
                neonatalPatchCard
                
                vaccinationTrackerCard
                
                babyCareGuideCard
                
                feedingTrackerCard
                
                growthMeasurementsCard
                
                developmentMilestonesCard
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.primary)
                    .padding()
                    .background(Circle().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            }
            
            Spacer()
            
            Text("Newborn Care")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Balancing space for centering title
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.top, 10)
    }
    
    private var babyProfileCard: some View {
        VStack(spacing: 24) {
            // Baby avatar
            ZStack {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Baby info
            Text(babyProfile.name.isEmpty ? "Baby's Name" : babyProfile.name)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.gray)
            
            Text(babyProfile.ageDescription)
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .padding(.top, -8)
            
            // Measurements
            HStack(spacing: 30) {
                VStack(spacing: 5) {
                    Text("\(String(format: "%.1f", babyProfile.weight)) kg")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Weight")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                VStack(spacing: 5) {
                    Text("\(String(format: "%.0f", babyProfile.height)) cm")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Height")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                VStack(spacing: 5) {
                    Text("\(String(format: "%.0f", babyProfile.headCircumference)) cm")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Head")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            // Today's summary
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Summary")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    HStack(spacing: 5) {
                        Text("•")
                            .foregroundColor(.white)
                        
                        Text("\(todayFeedingCount) feedings")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 5) {
                        Text("•")
                            .foregroundColor(.white)
                        
                        Text("\(todaySleepHours) hours of sleep")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.1)))
    }
    
    private var neonatalPatchCard: some View {
        Button(action: {
            // Action for neonatal patch
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pink.opacity(0.8))
                
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Neonatal Patch Vitals")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Monitor real-time baby vitals")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var vaccinationTrackerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "syringe")
                    .font(.system(size: 20))
                    .foregroundColor(.pink)
                
                Text("Vaccination Tracker")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showAddVaccination = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // If there are vaccinations, show them
            if !vaccinationRecords.isEmpty {
                VStack(spacing: 8) {
                    LazyVStack(spacing: 8) {
                        ForEach(vaccinationRecords.prefix(2)) { record in
                            vaccinationItem(record: record)
                                .onTapGesture {
                                    editingVaccination = record
                                    showAddVaccination = true
                                }
                        }
                    }
                }
                
                // View all button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showAllVaccinations = true
                    }) {
                        Text("View All (\(vaccinationRecords.count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.pink)
                    }
                }
            } else {
                // Empty state
                Button(action: {
                    showAddVaccination = true
                }) {
                    Text("Add your baby's first vaccination")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showAddVaccination) {
            // Reset editing vaccination when sheet is dismissed
            if editingVaccination != nil {
                editingVaccination = nil
            }
        } content: {
            AddVaccinationView(
                babyName: babyProfile.name,
                existingRecord: editingVaccination,
                onSave: { newRecord in
                    if let editing = editingVaccination {
                        // Update existing record
                        updateVaccinationRecord(editing, with: newRecord)
                    } else {
                        // Add new record
                        addVaccinationRecord(newRecord)
                    }
                },
                onDelete: editingVaccination != nil ? { record in
                    deleteVaccinationRecord(record)
                } : nil
            )
        }
        .sheet(isPresented: $showAllVaccinations) {
            AllVaccinationsView(
                records: vaccinationRecords,
                babyName: babyProfile.name,
                onEdit: { record in
                    editingVaccination = record
                    showAllVaccinations = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAddVaccination = true
                    }
                }
            )
        }
    }
    
    private func vaccinationItem(record: VaccinationRecord) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pink.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pink)
                
                HStack {
                    Text("Date: \(record.dateString)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(record.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(record.status.color)
                        .cornerRadius(10)
                }
                
                if !record.dayString.isEmpty {
                    Text(record.dayString)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
    }
    
    private var babyCareGuideCard: some View {
        Button(action: {
            // Navigate to baby care guide
            showGeminiAICare = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.7))
                
                HStack {
                    Image(systemName: "brain")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Baby Care Guide")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Smart recommendations for your baby's needs")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showGeminiAICare) {
            GeminiAICareView(babyProfile: babyProfile, growthRecords: growthRecords, feedingRecords: feedingRecords, vaccinationRecords: vaccinationRecords)
        }
    }
    
    private var feedingTrackerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.pink)
                
                Text("Feeding Tracker")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showAddFeeding = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // If there are feeding records, show them
            if !feedingRecords.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(feedingRecords.prefix(3)) { record in
                        feedingItem(record: record)
                            .onTapGesture {
                                showAddFeeding = true
                            }
                        if record.id != feedingRecords.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                // Empty state
                Button(action: {
                    showAddFeeding = true
                }) {
                    Text("Record your baby's first feeding")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showAddFeeding) {
            AddFeedingView(
                babyName: babyProfile.name,
                onSave: { newRecord in
                    addFeedingRecord(newRecord)
                }
            )
        }
    }
    
    private func feedingItem(record: FeedingRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: record.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.pink)
                
                Text(record.timeString)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(timeSince(record.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Text(record.type.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            if !record.foodType.isEmpty {
                Text(record.foodType)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            HStack {
                if let amount = record.amount {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        
                        Text("\(String(format: "%.1f", amount)) ml")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                if let duration = record.duration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        
                        Text("\(duration) min")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeSince(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: date, to: now)
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
    
    private var growthMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Growth Measurements")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showAddGrowth = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // If there are growth records, show them
            if !growthRecords.isEmpty {
                // Show the most recent growth record
                LazyVStack {
                    if let latestRecord = growthRecords.first {
                        growthSummaryView(record: latestRecord)
                            .onTapGesture {
                                // Open growth history view
                                showAddGrowth = true
                            }
                    }
                }
            } else {
                // Empty state
                Text("No growth measurements logged yet. Tap + to add your first measurement.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showAddGrowth) {
            AddGrowthView(
                babyName: babyProfile.name,
                previousRecords: growthRecords,
                onSave: { newRecord in
                    addGrowthRecord(newRecord)
                }
            )
        }
    }
    
    private func growthSummaryView(record: GrowthRecord) -> some View {
        Text("Latest measurements from \(formatDate(record.date))")
            .font(.headline)
            .padding(.bottom, 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var developmentMilestonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Development Milestones")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray)
            
            Divider()
            
            Text("Track your baby's development milestones. Coming soon!")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.vertical, 10)
            
            Button(action: {
                // Will be implemented later
            }) {
                Text("Coming Soon")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Data Methods
    
    private func loadData() {
        // Check if the user is authenticated
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            showProfileSetup = true
            return
        }
        
        let db = Firestore.firestore()
        
        // Load baby profile
        db.collection("users").document(user.uid).collection("babyProfiles").document("primary").getDocument { document, error in
            if let document = document, document.exists, let data = try? document.data(as: BabyProfile.self) {
                self.babyProfile = data
                
                // Now load other records
                self.loadFeedingRecords()
                self.loadVaccinationRecords()
                self.loadGrowthRecords()
            } else {
                // No baby profile found, show setup
                self.isLoading = false
                self.showProfileSetup = true
            }
        }
    }
    
    private func loadFeedingRecords() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("feedingRecords")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    var records: [FeedingRecord] = []
                    
                    for document in snapshot.documents {
                        if let record = try? document.data(as: FeedingRecord.self) {
                            records.append(record)
                        }
                    }
                    
                    self.feedingRecords = records
                }
                
                // Continue loading
                self.isLoading = false
            }
    }
    
    private func loadVaccinationRecords() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("vaccinationRecords")
            .order(by: "scheduledDate", descending: false)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    var records: [VaccinationRecord] = []
                    
                    for document in snapshot.documents {
                        if let record = try? document.data(as: VaccinationRecord.self) {
                            records.append(record)
                        }
                    }
                    
                    self.vaccinationRecords = records
                }
            }
    }
    
    private func loadGrowthRecords() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("growthRecords")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    var records: [GrowthRecord] = []
                    
                    for document in snapshot.documents {
                        if let record = try? document.data(as: GrowthRecord.self) {
                            records.append(record)
                        }
                    }
                    
                    self.growthRecords = records
                }
            }
    }
    
    private func saveBabyProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.uid).collection("babyProfiles").document("primary").setData(from: babyProfile)
        } catch {
            print("Error saving baby profile: \(error)")
        }
    }
    
    // MARK: - Vaccination Methods
    
    private func addVaccinationRecord(_ record: VaccinationRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.uid).collection("vaccinationRecords").document(record.id).setData(from: record)
            
            // Update local array
            vaccinationRecords.append(record)
            vaccinationRecords.sort { $0.scheduledDate < $1.scheduledDate }
            
            showAlert = true
            alertMessage = "Vaccination record added successfully"
        } catch {
            showAlert = true
            alertMessage = "Error saving record: \(error.localizedDescription)"
        }
    }
    
    private func updateVaccinationRecord(_ oldRecord: VaccinationRecord, with newRecord: VaccinationRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        // Create a new record with the same ID as the old one
        var updatedRecord = newRecord
        updatedRecord.id = oldRecord.id
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.uid).collection("vaccinationRecords").document(oldRecord.id).setData(from: updatedRecord)
            
            // Update local array
            if let index = vaccinationRecords.firstIndex(where: { $0.id == oldRecord.id }) {
                vaccinationRecords[index] = updatedRecord
            }
            vaccinationRecords.sort { $0.scheduledDate < $1.scheduledDate }
            
            showAlert = true
            alertMessage = "Vaccination record updated successfully"
        } catch {
            showAlert = true
            alertMessage = "Error updating record: \(error.localizedDescription)"
        }
    }
    
    private func deleteVaccinationRecord(_ record: VaccinationRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("vaccinationRecords").document(record.id).delete { error in
            if let error = error {
                showAlert = true
                alertMessage = "Error deleting record: \(error.localizedDescription)"
            } else {
                // Update local array
                vaccinationRecords.removeAll { $0.id == record.id }
                
                showAlert = true
                alertMessage = "Vaccination record deleted successfully"
                
                // Close the sheet
                showAddVaccination = false
            }
        }
    }
    
    // MARK: - Growth Methods
    
    private func addGrowthRecord(_ record: GrowthRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.uid).collection("growthRecords").document(record.id).setData(from: record)
            
            // Update local array
            growthRecords.append(record)
            growthRecords.sort { $0.date > $1.date }
            
            showAlert = true
            alertMessage = "Growth record added successfully"
        } catch {
            showAlert = true
            alertMessage = "Error saving record: \(error.localizedDescription)"
        }
    }
    
    private func deleteGrowthRecord(_ record: GrowthRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("growthRecords").document(record.id).delete { error in
            if let error = error {
                showAlert = true
                alertMessage = "Error deleting record: \(error.localizedDescription)"
            } else {
                // Update local array
                growthRecords.removeAll { $0.id == record.id }
                
                showAlert = true
                alertMessage = "Growth record deleted successfully"
            }
        }
    }
    
    // MARK: - Feeding Methods
    
    private func addFeedingRecord(_ record: FeedingRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.uid).collection("feedingRecords").document(record.id).setData(from: record)
            
            // Update local array
            feedingRecords.append(record)
            feedingRecords.sort { $0.timestamp > $1.timestamp }
            
            showAlert = true
            alertMessage = "Feeding record added successfully"
        } catch {
            showAlert = true
            alertMessage = "Error saving record: \(error.localizedDescription)"
        }
    }
    
    private func deleteFeedingRecord(_ record: FeedingRecord) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("feedingRecords").document(record.id).delete { error in
            if let error = error {
                showAlert = true
                alertMessage = "Error deleting record: \(error.localizedDescription)"
            } else {
                // Update local array
                feedingRecords.removeAll { $0.id == record.id }
                
                showAlert = true
                alertMessage = "Feeding record deleted successfully"
            }
        }
    }
}

// Baby Profile Setup View
struct BabyProfileSetupView: View {
    @Binding var babyProfile: BabyProfile
    var onComplete: () -> Void
    
    @State private var birthDate = Date()
    @State private var name = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var headCircumference = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Newborn Care")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.pink)
            
            Text("Let's set up your baby's profile")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)
            }
            
            // Form
            VStack(spacing: 20) {
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Baby's Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    TextField("Enter baby's name", text: $name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                
                // Birth Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Date")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxHeight: 120)
                }
                
                // Measurements
                HStack(spacing: 15) {
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    
                    // Height
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("0", text: $height)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    
                    // Head circumference
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Head (cm)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("0", text: $headCircumference)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Save button
            Button(action: {
                saveAndComplete()
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(name.isEmpty)
        }
        .padding()
    }
    
    private func saveAndComplete() {
        // Update baby profile
        babyProfile.name = name
        babyProfile.birthDate = birthDate
        babyProfile.weight = Double(weight) ?? 0.0
        babyProfile.height = Double(height) ?? 0.0
        babyProfile.headCircumference = Double(headCircumference) ?? 0.0
        
        // Complete setup
        onComplete()
    }
}

// Add Vaccination View
struct AddVaccinationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let babyName: String
    let existingRecord: VaccinationRecord?
    let onSave: (VaccinationRecord) -> Void
    let onDelete: ((VaccinationRecord) -> Void)?
    
    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var status: VaccinationRecord.VaccinationStatus = .scheduled
    @State private var showDeleteConfirmation = false
    
    init(babyName: String, existingRecord: VaccinationRecord? = nil, onSave: @escaping (VaccinationRecord) -> Void, onDelete: ((VaccinationRecord) -> Void)? = nil) {
        self.babyName = babyName
        self.existingRecord = existingRecord
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state from existing record if provided
        if let record = existingRecord {
            _name = State(initialValue: record.name)
            _date = State(initialValue: record.scheduledDate)
            _notes = State(initialValue: record.notes)
            _location = State(initialValue: record.location)
            _status = State(initialValue: record.status)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vaccination Details")) {
                    TextField("Vaccine Name", text: $name)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Picker("Status", selection: $status) {
                        ForEach(VaccinationRecord.VaccinationStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    TextField("Location (e.g., Hospital, Clinic)", text: $location)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                if onDelete != nil {
                    Section {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Delete Record")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingRecord != nil ? "Edit Vaccination" : "Add Vaccination")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveRecord()
                }
                .disabled(name.isEmpty)
            )
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Vaccination Record"),
                    message: Text("Are you sure you want to delete this record? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let record = existingRecord, let onDelete = onDelete {
                            onDelete(record)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func saveRecord() {
        let record = VaccinationRecord(
            id: existingRecord?.id ?? UUID().uuidString,
            name: name,
            scheduledDate: date,
            status: status,
            notes: notes,
            location: location
        )
        
        onSave(record)
        presentationMode.wrappedValue.dismiss()
    }
}

// All Vaccinations View
struct AllVaccinationsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let records: [VaccinationRecord]
    let babyName: String
    let onEdit: (VaccinationRecord) -> Void
    
    @State private var selectedFilter: VaccinationRecord.VaccinationStatus? = nil
    
    var filteredRecords: [VaccinationRecord] {
        if let filter = selectedFilter {
            return records.filter { $0.status == filter }
        } else {
            return records
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        
                        ForEach(VaccinationRecord.VaccinationStatus.allCases, id: \.self) { status in
                            FilterPill(
                                title: status.rawValue,
                                isSelected: selectedFilter == status,
                                color: status.color
                            ) {
                                selectedFilter = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                // Records list
                List {
                    if filteredRecords.isEmpty {
                        Text("No vaccination records match the selected filter")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(filteredRecords) { record in
                            VaccinationRecordRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onEdit(record)
                                }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("\(babyName)'s Vaccinations")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct VaccinationRecordRow: View {
    let record: VaccinationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.name)
                    .font(.headline)
                
                Spacer()
                
                Text(record.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(record.status.color.opacity(0.2))
                    .foregroundColor(record.status.color)
                    .cornerRadius(8)
            }
            
            Text("Date: \(record.dateString)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !record.location.isEmpty {
                Text("Location: \(record.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = .pink
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? color : .gray)
        }
    }
}

// Add Growth View
struct AddGrowthView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let babyName: String
    let previousRecords: [GrowthRecord]
    let onSave: (GrowthRecord) -> Void
    
    @State private var date = Date()
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var headCircumference: String = ""
    @State private var notes: String = ""
    @State private var showChart = true
    @State private var chartMetric: GrowthChartMetric = .weight
    
    enum GrowthChartMetric: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case headCircumference = "Head"
        
        var color: Color {
            switch self {
            case .weight: return .blue
            case .height: return .green
            case .headCircumference: return .orange
            }
        }
        
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .height, .headCircumference: return "cm"
            }
        }
        
        var icon: String {
            switch self {
            case .weight: return "scalemass.fill"
            case .height: return "ruler.fill"
            case .headCircumference: return "person.fill"
            }
        }
    }
    
    var formIsValid: Bool {
        !weight.isEmpty || !height.isEmpty || !headCircumference.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showChart && !previousRecords.isEmpty {
                    // Growth chart section
                    growthChartSection
                        .padding(.horizontal)
                        .padding(.top)
                        .background(Color.white)
                }
                
                // Measurement form
                Form {
                    Section(header: Text("Measurements")) {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        
                        TextField("Weight (kg)", text: $weight)
                            .keyboardType(.decimalPad)
                        
                        TextField("Height (cm)", text: $height)
                            .keyboardType(.decimalPad)
                        
                        TextField("Head Circumference (cm)", text: $headCircumference)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                    
                    if !previousRecords.isEmpty {
                        Section {
                            Toggle("Show Growth Chart", isOn: $showChart)
                        }
                        
                        if !previousRecords.isEmpty {
                            Section(header: Text("History")) {
                                ForEach(previousRecords) { record in
                                    historyRow(for: record)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Growth Measurements")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveRecord()
                }
                .disabled(!formIsValid)
            )
        }
    }
    
    private var growthChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Growth Chart")
                .font(.headline)
            
            // Metric selector
            HStack {
                ForEach(GrowthChartMetric.allCases, id: \.self) { metric in
                    Button(action: {
                        chartMetric = metric
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: metric.icon)
                                .foregroundColor(chartMetric == metric ? metric.color : .gray)
                            
                            Text(metric.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(chartMetric == metric ? metric.color : .gray)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(chartMetric == metric ? metric.color.opacity(0.1) : Color.clear)
                        )
                    }
                    
                    if metric != GrowthChartMetric.allCases.last {
                        Spacer()
                    }
                }
            }
            
            // Chart view
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 200)
                
                // Simple placeholder chart visualization
                // In a real app, use SwiftUI Charts here
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Chart axes
                        VStack {
                            Spacer()
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        
                        HStack(alignment: .bottom, spacing: 0) {
                            // Y-axis
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(.gray.opacity(0.5))
                            
                            // Chart data
                            HStack(alignment: .bottom, spacing: (geometry.size.width - 20) / CGFloat(chartData.count + 1)) {
                                ForEach(0..<chartData.count, id: \.self) { index in
                                    VStack {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(chartMetric.color)
                                            .frame(width: 8, height: chartData[index] * 170)
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 10)
                }
                .padding(10)
            }
            .frame(height: 220)
        }
    }
    
    // Create dummy chart data
    private var chartData: [CGFloat] {
        let records = previousRecords.sorted { $0.date < $1.date }
        let maxRecords = 5
        let lastRecords = Array(records.suffix(maxRecords))
        
        var values: [CGFloat] = []
        
        for record in lastRecords {
            switch chartMetric {
            case .weight:
                if let weight = record.weight {
                    values.append(CGFloat(weight) / 20.0) // Normalize by dividing by max expected value
                }
            case .height:
                if let height = record.height {
                    values.append(CGFloat(height) / 100.0) // Normalize by dividing by max expected value
                }
            case .headCircumference:
                if let headCircumference = record.headCircumference {
                    values.append(CGFloat(headCircumference) / 60.0) // Normalize by dividing by max expected value
                }
            }
        }
        
        // Ensure values are in range 0.1...1.0
        return values.map { max(min($0, 1.0), 0.1) }
    }
    
    private func historyRow(for record: GrowthRecord) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(formatter.string(from: record.date))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                if let weight = record.weight {
                    Text("🔵 \(String(format: "%.2f", weight)) kg")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let height = record.height {
                    Text("🟢 \(String(format: "%.1f", height)) cm")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let headCircumference = record.headCircumference {
                    Text("🟠 \(String(format: "%.1f", headCircumference)) cm")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func saveRecord() {
        // Create new record
        let record = GrowthRecord(
            id: UUID().uuidString,
            date: date,
            weight: Double(weight.replacingOccurrences(of: ",", with: ".")),
            height: Double(height.replacingOccurrences(of: ",", with: ".")),
            headCircumference: Double(headCircumference.replacingOccurrences(of: ",", with: ".")),
            notes: notes
        )
        
        onSave(record)
        presentationMode.wrappedValue.dismiss()
    }
}

// Add Feeding View
struct AddFeedingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let babyName: String
    let onSave: (FeedingRecord) -> Void
    
    @State private var feedingType: FeedingRecord.FeedingType = .breastMilk
    @State private var amount: String = ""
    @State private var duration: String = ""
    @State private var foodType: String = ""
    @State private var notes: String = ""
    @State private var date = Date()
    
    var formIsValid: Bool {
        switch feedingType {
        case .breastMilk:
            return !duration.isEmpty
        case .formula, .expressedMilk:
            return !amount.isEmpty
        case .solidFood:
            return !foodType.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feeding Details")) {
                    DatePicker("Time", selection: $date)
                    
                    Picker("Type", selection: $feedingType) {
                        ForEach(FeedingRecord.FeedingType.allCases, id: \.self) { type in
                            Label {
                                Text(type.rawValue)
                            } icon: {
                                Image(systemName: type.icon)
                                    .foregroundColor(.pink)
                            }
                            .tag(type)
                        }
                    }
                }
                
                // Amount section (for formula and expressed milk)
                if feedingType == .formula || feedingType == .expressedMilk {
                    Section(header: Text("Amount")) {
                        HStack {
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                            
                            Text("ml")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Duration section (for breastfeeding)
                if feedingType == .breastMilk {
                    Section(header: Text("Duration")) {
                        HStack {
                            TextField("Duration", text: $duration)
                                .keyboardType(.numberPad)
                            
                            Text("minutes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Food type section (for solid food)
                if feedingType == .solidFood {
                    Section(header: Text("Food Type")) {
                        TextField("e.g., Pureed apple, Yogurt", text: $foodType)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Save Feeding Record") {
                        saveRecord()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.pink)
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("Record Feeding")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveRecord() {
        // Create new record
        var record = FeedingRecord(
            id: UUID().uuidString,
            timestamp: date,
            type: feedingType,
            notes: notes,
            foodType: feedingType == .solidFood ? foodType : ""
        )
        
        // Set amount or duration based on feeding type
        if feedingType == .formula || feedingType == .expressedMilk {
            record.amount = Double(amount.replacingOccurrences(of: ",", with: "."))
        } else if feedingType == .breastMilk {
            record.duration = Int(duration)
        }
        
        onSave(record)
        presentationMode.wrappedValue.dismiss()
    }
}

// Gemini AI Baby Care View
struct GeminiAICareView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let babyProfile: BabyProfile
    let growthRecords: [GrowthRecord]
    let feedingRecords: [FeedingRecord]
    let vaccinationRecords: [VaccinationRecord]
    
    private let geminiAPIKey = "AIzaSyCueBkZoml0YMVXHxtMZeE7Xn-0iqDRpGU"
    
    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var isLoading: Bool = false
    @State private var showWelcomePrompt: Bool = true
    @State private var errorMessage: String = ""
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp = Date()
        
        static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
            lhs.id == rhs.id && 
            lhs.content == rhs.content && 
            lhs.isUser == rhs.isUser
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat header with baby info
                VStack(spacing: 4) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pink)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(babyProfile.name.isEmpty ? "Baby" : babyProfile.name)
                                .font(.system(size: 18, weight: .medium))
                            
                            Text(babyProfile.ageDescription)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // Last stats summary
                    if let latestGrowth = growthRecords.first {
                        HStack(spacing: 12) {
                            if let weight = latestGrowth.weight {
                                statsItem(value: String(format: "%.1f kg", weight), title: "Weight", icon: "scalemass", color: .blue)
                            }
                            
                            if let height = latestGrowth.height {
                                statsItem(value: String(format: "%.0f cm", height), title: "Height", icon: "ruler", color: .green)
                            }
                            
                            statsItem(value: "\(feedingRecords.prefix(10).count)", title: "Feedings", icon: "drop.fill", color: .pink)
                            
                            statsItem(value: "\(vaccinationRecords.count)", title: "Vaccines", icon: "syringe", color: .purple)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            if showWelcomePrompt {
                                // Welcome prompt
                                welcomePrompt
                            }
                            
                            ForEach(messages) { message in
                                chatMessageView(message: message)
                            }
                            
                            if isLoading {
                                loadingIndicator
                            }
                            
                            // Spacer message to help with scrolling
                            Text("")
                                .id("bottomMessage")
                                .padding(.top, 10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .onChange(of: messages) { _ in
                        // Scroll to bottom when messages change
                        withAnimation {
                            scrollView.scrollTo("bottomMessage", anchor: .bottom)
                        }
                    }
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                }
                
                // Input field
                HStack {
                    TextField("Ask about baby care...", text: $userInput)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.pink)
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("AI Baby Care Guide")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                generateInitialRecommendation()
            }
        }
    }
    
    private var welcomePrompt: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("👋 Welcome to AI Baby Care")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.purple)
            
            Text("I'm your personal baby care assistant. Here are some things you can ask me:")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                suggestionButton("What developmental milestones should I expect?")
                suggestionButton("How can I help with teething pain?")
                suggestionButton("What should I feed my \(babyProfile.ageDescription) baby?")
                suggestionButton("How much sleep does my baby need?")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.purple.opacity(0.1)))
    }
    
    private func suggestionButton(_ text: String) -> some View {
        Button(action: {
            userInput = text
            sendMessage()
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.purple.opacity(0.7))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.08))
            )
        }
    }
    
    private func statsItem(value: String, title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func chatMessageView(message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.pink.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.purple)
                            .clipShape(Circle())
                        
                        Text(message.content)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(18)
                            .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                    }
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.leading, 40)
                }
                
                Spacer()
            }
        }
    }
    
    private var loadingIndicator: some View {
        HStack {
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .scaleEffect(1.0)
                    .opacity(0.5)
                
                Circle()
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: 10, height: 10)
                    .scaleEffect(1.0)
                    .opacity(0.7)
                
                Circle()
                    .fill(Color.purple)
                    .frame(width: 10, height: 10)
                    .scaleEffect(1.0)
                    .opacity(1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color(.systemGray6))
            .cornerRadius(18)
            
            Spacer()
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: userInput, isUser: true)
        messages.append(userMessage)
        
        // Clear input and hide welcome prompt
        let sentMessage = userInput
        userInput = ""
        showWelcomePrompt = false
        
        // Show loading
        isLoading = true
        
        // Generate AI response
        generateResponse(for: sentMessage)
    }
    
    private func generateInitialRecommendation() {
        isLoading = true
        
        // Create context about the baby
        let ageInfo = babyProfile.ageDescription
        let name = babyProfile.name.isEmpty ? "the baby" : babyProfile.name
        
        // Format growth info
        var growthInfo = ""
        if let latestGrowth = growthRecords.first, 
           let weight = latestGrowth.weight,
           let height = latestGrowth.height {
            growthInfo = "\(name) currently weighs \(String(format: "%.2f", weight)) kg and is \(String(format: "%.1f", height)) cm tall. "
        }
        
        // Format feeding info
        var feedingInfo = ""
        if !feedingRecords.isEmpty {
            let recentFeedings = feedingRecords.prefix(3)
            let feedingTypes = recentFeedings.map { $0.type.rawValue }
            let uniqueTypes = Array(Set(feedingTypes))
            feedingInfo = "\(name) has been fed with \(uniqueTypes.joined(separator: ", ")). "
        }
        
        // Check if any vaccines are coming up
        var vaccinationInfo = ""
        let upcomingVaccinations = vaccinationRecords.filter { 
            $0.status == .scheduled && 
            $0.scheduledDate > Date() && 
            $0.scheduledDate < Calendar.current.date(byAdding: .month, value: 1, to: Date())! 
        }
        if !upcomingVaccinations.isEmpty {
            vaccinationInfo = "There are \(upcomingVaccinations.count) vaccinations scheduled in the next month. "
        }
        
        // Create prompt
        let prompt = """
        You are a helpful assistant for new parents. Give personalized baby care advice for a \(ageInfo) infant named \(name).
        \(growthInfo)
        \(feedingInfo)
        \(vaccinationInfo)
        
        Provide 3-4 key care recommendations specifically tailored to a \(ageInfo) baby. Include tips on:
        1. Developmental activities appropriate for this age
        2. Nutrition and feeding guidance
        3. Sleep recommendations
        4. Health and safety considerations
        
        Keep your response friendly, reassuring, and concise (around 250 words). Format with bullet points and emojis for readability.
        """
        
        // Call Gemini API with this context
        getGeminiResponse(prompt: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                case .failure(let error):
                    errorMessage = "Sorry, there was an error: \(error.localizedDescription). Please try again."
                }
            }
        }
    }
    
    private func generateResponse(for userMessage: String) {
        // Create context with previous conversation and baby info
        let ageInfo = babyProfile.ageDescription
        let name = babyProfile.name.isEmpty ? "the baby" : babyProfile.name
        
        // Include previous messages for context
        var conversationHistory = ""
        for message in messages.prefix(6) { // Limit to prevent token overflow
            let role = message.isUser ? "User" : "Assistant"
            conversationHistory += "\(role): \(message.content)\n\n"
        }
        
        // Create prompt
        let prompt = """
        You are a helpful assistant for new parents. The baby is \(ageInfo) and named \(name).
        
        Recent conversation:
        \(conversationHistory)
        
        User's latest question: \(userMessage)
        
        Provide a helpful, personalized response about baby care. Keep your answer concise and friendly.
        Format with bullet points where appropriate and include emojis for readability.
        """
        
        // Call Gemini API
        getGeminiResponse(prompt: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                case .failure(let error):
                    errorMessage = "Sorry, there was an error: \(error.localizedDescription). Please try again."
                }
            }
        }
    }
    
    private func getGeminiResponse(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Gemini API endpoint for Gemini 1.5 Pro
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=\(geminiAPIKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GeminiAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create payload
        let payload: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ]
        ]
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GeminiAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    completion(.success(text))
                } else {
                    // Try to get error message
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        completion(.failure(NSError(domain: "GeminiAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        completion(.failure(NSError(domain: "GeminiAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse response"])))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NewbornCareView()
} 
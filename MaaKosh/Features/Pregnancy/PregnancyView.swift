import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

struct PregnancyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMetric = 0
    @State private var isLoading = true
    @State private var userProfile = UserProfile()
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Health data
    @State private var contractionData: [DataPoint] = []
    @State private var temperatureData: [DataPoint] = []
    @State private var heartRateData: [DataPoint] = []
    @State private var spo2Data: [DataPoint] = []
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isLoading {
                    Spacer()
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .scaleEffect(1.2)
                        
                        Text("Loading your data...")
                            .font(AppFont.body())
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary card
                            pregnancySummaryCard
                            
                            // Health Monitoring
                            VStack(alignment: .leading) {
                                Text("Health Monitoring")
                                    .font(AppFont.titleSmall())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                if hasNoHealthData() {
                                    emptyDataView
                                } else {
                                    // Metrics selector
                                    metricsSelector
                                        .padding(.top, 5)
                                    
                                    // Chart card
                                    chartCard
                                }
                            }
                            
                            // Additional metrics cards
                            if !hasNoHealthData() {
                                metricsGridView
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadUserData()
                loadHealthData()
            }
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
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
            
            Text("Pregnancy Tracking")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // Settings
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.trailing, 4)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private var pregnancySummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Pregnancy")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("Week \(userProfile.currentPregnancyWeek)")
                    .font(AppFont.body().bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.pink)
                    .cornerRadius(15)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Trimester")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(trimesterText)
                        .font(AppFont.body().bold())
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Due Date")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(formatDate(userProfile.estimatedDueDate))
                        .font(AppFont.body().bold())
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(progressPercentage)%")
                        .font(AppFont.caption().bold())
                        .foregroundColor(.pink)
                }
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 8)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .frame(width: progressWidth, height: 8)
                        .foregroundColor(Color.pink)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var emptyDataView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 50))
                .foregroundColor(.pink.opacity(0.5))
                .padding()
            
            Text("No Health Data Available")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            Text("Connect a health device or manually log your vitals to see your health metrics here.")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Action to add health data
            }) {
                Text("Add Health Data")
                    .font(AppFont.body().bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 25)
                    .background(Color.pink)
                    .cornerRadius(25)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var metricsSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    withAnimation {
                        selectedMetric = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: metricIcon(for: index))
                            .foregroundColor(selectedMetric == index ? .white : .gray)
                            .padding(10)
                            .background(selectedMetric == index ? metricColor(for: index) : Color.clear)
                            .clipShape(Circle())
                        
                        Text(metricName(for: index))
                            .font(AppFont.caption())
                            .foregroundColor(selectedMetric == index ? metricColor(for: index) : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(metricName(for: selectedMetric))
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(currentMetricValue())
                    .font(AppFont.body().bold())
                    .foregroundColor(metricColor(for: selectedMetric))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(metricColor(for: selectedMetric).opacity(0.1))
                    .cornerRadius(10)
            }
            
            // Chart
            if !dataForSelectedMetric().isEmpty {
                Chart {
                    ForEach(dataForSelectedMetric(), id: \.time) { item in
                        LineMark(
                            x: .value("Time", item.time),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(metricColor(for: selectedMetric))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", item.time),
                            y: .value("Value", item.value)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    metricColor(for: selectedMetric).opacity(0.3),
                                    metricColor(for: selectedMetric).opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: yAxisRange())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("No data available")
                            .font(AppFont.body())
                            .foregroundColor(.gray)
                    )
            }
            
            HStack {
                Text("Last 24 hours")
                    .font(AppFont.caption())
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    // View detailed history
                }) {
                    Text("View History")
                        .font(AppFont.caption().bold())
                        .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var metricsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            // Small metrics cards
            ForEach(0..<4) { index in
                if index != selectedMetric {
                    Button(action: {
                        withAnimation {
                            selectedMetric = index
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: metricIcon(for: index))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(metricColor(for: index))
                                    .clipShape(Circle())
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Text(metricName(for: index))
                                .font(AppFont.caption())
                                .foregroundColor(.gray)
                            
                            Text(summaryValueForMetric(index))
                                .font(AppFont.body().bold())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var trimesterText: String {
        if userProfile.currentPregnancyWeek <= 13 {
            return "First"
        } else if userProfile.currentPregnancyWeek <= 26 {
            return "Second"
        } else {
            return "Third"
        }
    }
    
    private var progressPercentage: Int {
        return Int(min((Double(userProfile.currentPregnancyWeek) / 40.0) * 100, 100))
    }
    
    private var progressWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = screenWidth - 40 // Accounting for padding
        let percentage = CGFloat(progressPercentage) / 100.0
        return cardWidth * percentage
    }
    
    // MARK: - Helper Functions
    
    private func hasNoHealthData() -> Bool {
        return contractionData.isEmpty && temperatureData.isEmpty && 
               heartRateData.isEmpty && spo2Data.isEmpty
    }
    
    private func metricName(for index: Int) -> String {
        switch index {
        case 0: return "Contractions"
        case 1: return "Temperature"
        case 2: return "Heart Rate"
        case 3: return "SpO2"
        default: return ""
        }
    }
    
    private func metricIcon(for index: Int) -> String {
        switch index {
        case 0: return "waveform.path"
        case 1: return "thermometer"
        case 2: return "heart.fill"
        case 3: return "lungs.fill"
        default: return ""
        }
    }
    
    private func metricColor(for index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .orange
        case 2: return .pink
        case 3: return .blue
        default: return .gray
        }
    }
    
    private func dataForSelectedMetric() -> [DataPoint] {
        switch selectedMetric {
        case 0: return contractionData
        case 1: return temperatureData
        case 2: return heartRateData
        case 3: return spo2Data
        default: return []
        }
    }
    
    private func yAxisRange() -> ClosedRange<Double> {
        switch selectedMetric {
        case 0: return 0...15
        case 1: return 36.5...38.0
        case 2: return 60...100
        case 3: return 90...100
        default: return 0...100
        }
    }
    
    private func currentMetricValue() -> String {
        switch selectedMetric {
        case 0:
            return contractionData.last.map { "\(Int($0.value)) intensity" } ?? "No data"
        case 1:
            return temperatureData.last.map { "\(String(format: "%.1f", $0.value))°C" } ?? "No data"
        case 2:
            return heartRateData.last.map { "\(Int($0.value)) bpm" } ?? "No data"
        case 3:
            return spo2Data.last.map { "\(Int($0.value))%" } ?? "No data"
        default:
            return "No data"
        }
    }
    
    private func summaryValueForMetric(_ index: Int) -> String {
        switch index {
        case 0:
            return contractionData.last.map { "\(Int($0.value)) intensity" } ?? "No data"
        case 1:
            return temperatureData.last.map { "\(String(format: "%.1f", $0.value))°C" } ?? "No data"
        case 2:
            return heartRateData.last.map { "\(Int($0.value)) bpm" } ?? "No data"
        case 3:
            return spo2Data.last.map { "\(Int($0.value))%" } ?? "No data"
        default:
            return "No data"
        }
    }
    
    // MARK: - Data Methods
    
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                errorMessage = "Could not load user profile: \(error.localizedDescription)"
                showingErrorAlert = true
                isLoading = false
                return
            }
            
            if let document = document, document.exists {
                // Use default values if data is missing
                let estimatedDueDate = (document.data()?["estimatedDueDate"] as? Timestamp)?.dateValue()
                let lastPeriodDate = (document.data()?["lastPeriodDate"] as? Timestamp)?.dateValue()
                let currentWeek = document.data()?["currentPregnancyWeek"] as? Int
                
                if let lastPeriodDate = lastPeriodDate {
                    self.userProfile.lastPeriodDate = lastPeriodDate
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
                
                if let cycleLengthInDays = document.data()?["cycleLengthInDays"] as? Int {
                    self.userProfile.cycleLengthInDays = cycleLengthInDays
                }
                
                if let isProfileComplete = document.data()?["isProfileComplete"] as? Bool {
                    self.userProfile.isProfileComplete = isProfileComplete
                }
            }
            
            isLoading = false
        }
    }
    
    private func loadHealthData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // For demo purposes, load sample data even if user isn't authenticated
            loadSampleHealthData()
            return
        }
        
        let db = Firestore.firestore()
        
        // In a real app, we would load actual health data from Firestore
        // For now, we'll load sample data for demonstration
        loadSampleHealthData()
        
        // This would fetch actual data:
        // db.collection("users").document(userId).collection("healthData")
        //     .order(by: "timestamp", descending: true)
        //     .limit(to: 24)
        //     .getDocuments { ... }
    }
    
    private func loadSampleHealthData() {
        // Generate sample data points for demonstration
        
        // Contraction data (pattern with peaks)
        contractionData = generateContractionSampleData()
        
        // Temperature data (around normal body temperature)
        temperatureData = generateTemperatureSampleData()
        
        // Heart rate data
        heartRateData = generateHeartRateSampleData()
        
        // SpO2 data
        spo2Data = generateSpO2SampleData()
    }
    
    private func generateContractionSampleData() -> [DataPoint] {
        var data: [DataPoint] = []
        
        for i in 0..<24 {
            let hour = String(format: "%02d:00", i % 24)
            
            if i % 6 == 0 {
                // Create a contraction peak every 6 hours
                let value = Double.random(in: 10...15)
                data.append(DataPoint(time: hour, value: value))
            } else if i % 6 == 1 {
                // Falling after peak
                let value = Double.random(in: 5...7)
                data.append(DataPoint(time: hour, value: value))
            } else {
                // Baseline activity
                let value = Double.random(in: 0...3)
                data.append(DataPoint(time: hour, value: value))
            }
        }
        
        return data
    }
    
    private func generateTemperatureSampleData() -> [DataPoint] {
        var data: [DataPoint] = []
        let baseTemp = 37.2 // Normal body temperature
        
        for i in 0..<24 {
            let hour = String(format: "%02d:00", i % 24)
            
            // Slight diurnal variation - lower in morning, higher in evening
            let timeVariation = sin(Double(i) * .pi / 12) * 0.2
            
            // Random small fluctuations
            let randomVariation = Double.random(in: -0.2...0.2)
            
            let value = baseTemp + timeVariation + randomVariation
            data.append(DataPoint(time: hour, value: value))
        }
        
        return data
    }
    
    private func generateHeartRateSampleData() -> [DataPoint] {
        var data: [DataPoint] = []
        let baseRate = 80.0 // Average heart rate
        
        for i in 0..<24 {
            let hour = String(format: "%02d:00", i % 24)
            
            // Activity pattern - higher during day, lower at night
            let activityVariation = i >= 8 && i <= 20 ? Double.random(in: 0...10) : Double.random(in: -10...0)
            
            // Random fluctuations
            let randomVariation = Double.random(in: -5...5)
            
            let value = baseRate + activityVariation + randomVariation
            data.append(DataPoint(time: hour, value: value))
        }
        
        return data
    }
    
    private func generateSpO2SampleData() -> [DataPoint] {
        var data: [DataPoint] = []
        
        for i in 0..<24 {
            let hour = String(format: "%02d:00", i % 24)
            
            // Most readings between 95-99%
            let value = Double.random(in: 95...99)
            data.append(DataPoint(time: hour, value: value))
        }
        
        return data
    }
    
    private func calculateWeeks(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        let days = components.day ?? 0
        return max(1, days / 7)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Data Structures

struct DataPoint {
    let time: String
    let value: Double
}

struct PregnancyView_Previews: PreviewProvider {
    static var previews: some View {
        PregnancyView()
    }
} 
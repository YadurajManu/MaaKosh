import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleGenerativeAI

struct PrePregnancyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var cycleData: [Date: CycleDayType] = [:]
    @State private var isLoading = true
    
    // AI Recommendation States
    @State private var recommendations: [AIRecommendation] = []
    @State private var isLoadingRecommendations = false
    @State private var showFullRecommendation = false
    @State private var selectedRecommendation: AIRecommendation?
    
    // Settings states
    @State private var showSettingsSheet = false
    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var showFertileWindow = true
    
    @State private var showInfoPopover = false
    
    // Dialog states
    @State private var showDateActionDialog = false
    @State private var selectedDate: Date? = nil
    @State private var selectedDay: Int = 0
    @State private var cycleEvents: [CycleEvent] = []
    
    @State private var navigateToPregnancyTests = false
    @State private var navigateToConceptionAttempts = false
    
    // Calendar constants
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    // AI model for generating recommendations
    private let apiKey = "AIzaSyCueBkZoml0YMVXHxtMZeE7Xn-0iqDRpGU"
    private var model: GenerativeModel {
        let config = GenerationConfig(maxOutputTokens: 500)
        return GenerativeModel(name: "gemini-1.5-pro", apiKey: apiKey, generationConfig: config)
    }
    
    // New state variables
    @State private var cycleSummary: CycleSummary = CycleSummary()
    @State private var showInsightsSummary = true
    @State private var insightCategories: [String: Int] = [:]
    
    // Add state variable for AI Guide
    @State private var showAIGuide = false
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // Title bar
                    titleBar
                    
                    // AI Personalized Insights
                    aiRecommendationsCard
                    
                    // Menstrual Cycle Tracker
                    cycleTrackerCard
                    
                    // Cycle logs
                    cycleLogs
                    
                    // Pregnancy Test Entries
                    sectionButton(title: "Pregnancy Test Entries", action: {
                        navigateToPregnancyTests = true
                    })
                    
                    // Conception Attempts
                    sectionButton(title: "Conception Attempts", action: {
                        navigateToConceptionAttempts = true
                    })
                    
                    // AI Fertility Guide
                    Button(action: {
                        showAIGuide = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.7))
                            
                            HStack {
                                Image(systemName: "brain")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding(.trailing, 10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Fertility Guide")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("Personalized advice for conception")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showAIGuide) {
                        GeminiAIFertilityGuideView(cycleData: cycleData, cycleLength: cycleLength, periodLength: periodLength, cycleEvents: cycleEvents)
                    }
                    
                    // Wellness Tips & Advice
                    wellnessTipsCard
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                loadCycleData()
                loadCycleEvents()
                loadCycleSettings()
                generateRecommendations()
            }
            // FAB for adding data
            .overlay(
                addButton,
                alignment: .bottomTrailing
            )
            
            // Date action dialog
            if showDateActionDialog, let selectedDate = selectedDate {
                dateActionDialog(date: selectedDate, day: selectedDay)
            }
            
            // Full recommendation sheet
            if showFullRecommendation, let recommendation = selectedRecommendation {
                fullRecommendationView(recommendation: recommendation)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            cycleSettingsSheet
        }
        .background(
            NavigationLink(
                destination: PregnancyTestView(),
                isActive: $navigateToPregnancyTests
            ) {
                EmptyView()
            }
        )
        .background(
            NavigationLink(
                destination: ConceptionAttemptsView(),
                isActive: $navigateToConceptionAttempts
            ) {
                EmptyView()
            }
        )
    }
    
    // MARK: - AI Recommendations
    
    private var aiRecommendationsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with title and refresh button
            HStack {
                Text("AI-Powered Fertility Insights")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    // Refresh recommendations
                    generateRecommendations()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.pink)
                        .padding(8)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Insights summary section
            if showInsightsSummary && !isLoadingRecommendations && !cycleSummary.isEmpty {
                insightsSummaryView
                    .padding(.vertical, 5)
            }
            
            if isLoadingRecommendations {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        
                        Text("Analyzing your cycle patterns...")
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else if recommendations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundColor(.pink.opacity(0.5))
                        
                        Text("No insights available")
                            .font(AppFont.body())
                            .foregroundColor(.gray)
                        
                        Text("Track your cycle data to receive personalized recommendations")
                            .font(AppFont.caption())
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // Category tabs
                if !insightCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(insightCategories.keys.sorted()), id: \.self) { category in
                                Text(category)
                                    .font(AppFont.caption().bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorFor(category: category))
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.vertical, 5)
                }
                
                // Enhanced recommendations carousel with better visual presentation
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(recommendations) { recommendation in
                            enhancedRecommendationCard(recommendation)
                                .onTapGesture {
                                    selectedRecommendation = recommendation
                                    withAnimation {
                                        showFullRecommendation = true
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func enhancedRecommendationCard(_ recommendation: AIRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Top section with icon and category
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [recommendation.color, recommendation.color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: recommendation.color.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: recommendation.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text(recommendation.category)
                    .font(AppFont.body().bold())
                    .foregroundColor(recommendation.color)
                
                Spacer()
                
                // Personalization indicator
                if recommendation.isPersonalized {
                    Text("Personalized")
                        .font(AppFont.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink)
                        .cornerRadius(10)
                }
            }
            
            // Title with prominent display
            Text(recommendation.title)
                .font(AppFont.body().bold())
                .foregroundColor(.black)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Preview of content with styling
            Text(recommendation.content)
                .font(AppFont.caption())
                .foregroundColor(.gray)
                .lineLimit(3)
                .padding(.bottom, 5)
            
            // Read more button
            Button(action: {
                selectedRecommendation = recommendation
                withAnimation {
                    showFullRecommendation = true
                }
            }) {
                Text("Read More")
                    .font(AppFont.caption().bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(recommendation.color)
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 280, height: 220)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(recommendation.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
    
    private func fullRecommendationView(recommendation: AIRecommendation) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showFullRecommendation = false
                    }
                }
            
            // Modal content
            VStack(alignment: .leading, spacing: 20) {
                // Header with category and close button
                HStack {
                    // Category with icon
                    HStack {
                        Image(systemName: recommendation.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(recommendation.color)
                            .clipShape(Circle())
                        
                        Text(recommendation.category)
                            .font(AppFont.body().bold())
                            .foregroundColor(recommendation.color)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showFullRecommendation = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                // Title
                Text(recommendation.title)
                    .font(AppFont.titleMedium())
                    .foregroundColor(.black)
                
                // Content
                ScrollView {
                    Text(recommendation.content)
                        .font(AppFont.body())
                        .foregroundColor(.black.opacity(0.8))
                        .lineSpacing(5)
                }
                
                // Source information
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.pink)
                    
                    Text("Based on your cycle data")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("MaaKosh AI")
                        .font(AppFont.caption().bold())
                        .foregroundColor(.pink)
                }
                .padding(.top, 5)
            }
            .padding(25)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            .transition(.scale)
        }
    }
    
    // Generate AI recommendations based on user's cycle data
    private func generateRecommendations() {
        guard !cycleEvents.isEmpty else {
            // If no cycle data, provide generic recommendations
            generateGenericRecommendations()
            return
        }
        
        isLoadingRecommendations = true
        
        // Create context from cycle data
        let context = createUserContext()
        
        // Generate cycle summary
        cycleSummary = generateCycleSummary()
        
        Task {
            do {
                let prompt = """
                You are an expert in women's reproductive health, fertility, and conception.
                
                Based on the following user data, generate 3 personalized recommendations or insights.
                Format each recommendation with: 
                1. A category (Fertility, Cycle Patterns, Nutrition, Lifestyle, or Wellness)
                2. A concise title (max 8 words)
                3. Detailed but concise content (150-200 words)
                4. A boolean flag indicating if this is highly personalized based on their data
                
                Analyze the data to create truly personalized insights. Look for patterns in:
                - Cycle length variations
                - Phase of cycle the user is currently in
                - Timing of fertility window
                - Regularity/irregularity patterns
                - Any notes or symptoms recorded
                
                User data:
                \(context)
                
                Respond only with 3 recommendations in this exact JSON format:
                ```json
                [
                  {
                    "category": "Category name",
                    "title": "Clear concise title",
                    "content": "Detailed explanation with personalized advice",
                    "isPersonalized": true/false
                  },
                  {
                    "category": "Category name",
                    "title": "Clear concise title",
                    "content": "Detailed explanation with personalized advice",
                    "isPersonalized": true/false
                  },
                  {
                    "category": "Category name",
                    "title": "Clear concise title",
                    "content": "Detailed explanation with personalized advice",
                    "isPersonalized": true/false
                  }
                ]
                ```
                
                Make sure your recommendations are evidence-based, actionable, and reference the user's specific data where possible.
                """
                
                let response = try await model.generateContent(prompt)
                
                if let responseText = response.text {
                    // Parse JSON response
                    let jsonString = extractJSON(from: responseText)
                    parseRecommendations(from: jsonString)
                } else {
                    generateGenericRecommendations()
                }
                
                DispatchQueue.main.async {
                    isLoadingRecommendations = false
                }
            } catch {
                print("Error generating recommendations: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    generateGenericRecommendations()
                    isLoadingRecommendations = false
                }
            }
        }
    }
    
    // Create a context string from user's cycle data
    private func createUserContext() -> String {
        var context = "Cycle length: \(cycleLength) days\n"
        context += "Period length: \(periodLength) days\n"
        
        // Add period days
        let periodDays = cycleEvents.filter { $0.type == .period }
        if !periodDays.isEmpty {
            context += "\nPeriod records:\n"
            for event in periodDays.sorted(by: { $0.date < $1.date }).prefix(5) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                context += "- \(dateFormatter.string(from: event.date))\n"
            }
        }
        
        // Add ovulation days
        let ovulationDays = cycleEvents.filter { $0.type == .ovulation }
        if !ovulationDays.isEmpty {
            context += "\nOvulation records:\n"
            for event in ovulationDays.sorted(by: { $0.date < $1.date }).prefix(3) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                context += "- \(dateFormatter.string(from: event.date))\n"
            }
        }
        
        // Add current cycle phase
        context += "\nCurrent cycle phase: \(currentCyclePhase())\n"
        
        // Add cycle regularity information
        context += "Cycle regularity: \(determineCycleRegularity())\n"
        
        // Add next predicted period
        context += "Next predicted period: \(nextPeriodPrediction())\n"
        
        return context
    }
    
    // Determine the current phase of the menstrual cycle
    private func currentCyclePhase() -> String {
        // Find most recent period start
        let periodEvents = cycleEvents.filter { $0.type == .period }
        let sortedPeriodEvents = periodEvents.sorted(by: { $0.date > $1.date })
        
        guard let lastPeriod = sortedPeriodEvents.first?.date else {
            return "Unknown"
        }
        
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod, to: Date()).day ?? 0
        
        if daysSinceLastPeriod < periodLength {
            return "Menstrual Phase"
        } else if daysSinceLastPeriod < 14 {
            return "Follicular Phase"
        } else if daysSinceLastPeriod < 17 {
            return "Ovulatory Phase"
        } else {
            return "Luteal Phase"
        }
    }
    
    // Determine if cycle is regular, irregular, or unknown
    private func determineCycleRegularity() -> String {
        let periodEvents = cycleEvents.filter { $0.type == .period }
        let sortedPeriodEvents = periodEvents.sorted(by: { $0.date < $1.date })
        
        if sortedPeriodEvents.count < 3 {
            return "Not enough data"
        }
        
        var cycleLengths: [Int] = []
        for i in 0..<(sortedPeriodEvents.count - 1) {
            let days = Calendar.current.dateComponents([.day], from: sortedPeriodEvents[i].date, to: sortedPeriodEvents[i+1].date).day ?? 0
            cycleLengths.append(days)
        }
        
        // Calculate standard deviation
        let mean = cycleLengths.reduce(0, +) / cycleLengths.count
        let variance = cycleLengths.map { pow(Double($0 - mean), 2) }.reduce(0, +) / Double(cycleLengths.count)
        let standardDeviation = sqrt(variance)
        
        if standardDeviation < 2.0 {
            return "Very Regular"
        } else if standardDeviation < 4.0 {
            return "Regular"
        } else {
            return "Irregular"
        }
    }
    
    // Extract JSON from AI response
    private func extractJSON(from text: String) -> String {
        if let startIndex = text.range(of: "```json")?.upperBound,
           let endIndex = text.range(of: "```", range: startIndex..<text.endIndex)?.lowerBound {
            return String(text[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
    
    // Parse recommendations from JSON string
    private func parseRecommendations(from jsonString: String) {
        do {
            let decoder = JSONDecoder()
            let data = jsonString.data(using: .utf8)!
            
            struct RawRecommendation: Codable {
                let category: String
                let title: String
                let content: String
                let isPersonalized: Bool?
            }
            
            let rawRecommendations = try decoder.decode([RawRecommendation].self, from: data)
            
            // Reset category counts
            insightCategories = [:]
            
            DispatchQueue.main.async {
                self.recommendations = rawRecommendations.map { raw in
                    // Count categories
                    if let count = self.insightCategories[raw.category] {
                        self.insightCategories[raw.category] = count + 1
                    } else {
                        self.insightCategories[raw.category] = 1
                    }
                    
                    return AIRecommendation(
                        id: UUID().uuidString,
                        category: raw.category,
                        title: raw.title,
                        content: raw.content,
                        iconName: self.iconFor(category: raw.category),
                        color: self.colorFor(category: raw.category),
                        isPersonalized: raw.isPersonalized ?? false
                    )
                }
            }
        } catch {
            print("Error parsing recommendations: \(error.localizedDescription)")
            generateGenericRecommendations()
        }
    }
    
    // Generate generic recommendations if AI generation fails or no data available
    private func generateGenericRecommendations() {
        DispatchQueue.main.async {
            self.recommendations = [
                AIRecommendation(
                    id: "1",
                    category: "Fertility",
                    title: "Understanding Your Fertile Window",
                    content: "The fertile window typically occurs 12-16 days before your next period. For a 28-day cycle, this is usually around days 12-17. Having intercourse every 1-2 days during this window maximizes your chances of conception. Track your basal body temperature and cervical mucus changes to better identify your personal fertile window. Remember that sperm can survive up to 5 days in the female reproductive tract, so starting intercourse a few days before ovulation can increase success rates.",
                    iconName: "star.fill",
                    color: .green,
                    isPersonalized: false
                ),
                AIRecommendation(
                    id: "2",
                    category: "Nutrition",
                    title: "Optimizing Diet for Conception",
                    content: "A balanced diet rich in antioxidants, healthy fats, and key nutrients supports reproductive health. Include folate-rich foods like leafy greens, legumes, and fortified grains to prevent neural tube defects. Omega-3 fatty acids from fish, walnuts, and flaxseeds help regulate hormones and increase blood flow to reproductive organs. Limit caffeine to 200mg daily and avoid alcohol when trying to conceive. Stay well-hydrated and maintain a healthy weight, as both underweight and overweight conditions can affect fertility.",
                    iconName: "leaf.fill",
                    color: .blue,
                    isPersonalized: false
                ),
                AIRecommendation(
                    id: "3",
                    category: "Wellness",
                    title: "Stress Management for Fertility",
                    content: "Chronic stress can disrupt hormone balance and affect ovulation. Incorporate stress-reduction practices like meditation, yoga, or deep breathing exercises into your daily routine. Regular moderate exercise improves blood flow and hormone balance but avoid excessive high-intensity workouts which can interfere with ovulation. Prioritize sleep quality, aiming for 7-9 hours nightly. Consider joining a support group or working with a therapist if you're experiencing anxiety about conception. Remember that stress management benefits both physical and emotional health during your fertility journey.",
                    iconName: "heart.fill",
                    color: .pink,
                    isPersonalized: false
                )
            ]
        }
    }
    
    // Get icon for recommendation category
    private func iconFor(category: String) -> String {
        switch category {
        case "Fertility":
            return "star.fill"
        case "Cycle Patterns":
            return "waveform.path"
        case "Nutrition":
            return "leaf.fill"
        case "Lifestyle":
            return "figure.walk"
        case "Wellness":
            return "heart.fill"
        default:
            return "doc.text.fill"
        }
    }
    
    // Get color for recommendation category
    private func colorFor(category: String) -> Color {
        switch category {
        case "Fertility":
            return .green
        case "Cycle Patterns":
            return .purple
        case "Nutrition":
            return .blue
        case "Lifestyle":
            return .orange
        case "Wellness":
            return .pink
        default:
            return .gray
        }
    }
    
    // MARK: - View Components
    
    private var titleBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Pre-Pregnancy Tracking")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // Settings or more options
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(.top, 10)
    }
    
    private var cycleTrackerCard: some View {
        VStack(spacing: 15) {
            // Header with title and settings
            HStack {
                Text("Menstrual Cycle Tracker")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showSettingsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 5)
            
            // Month navigation with animation
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navigateMonth(forward: false)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("\(monthNames[selectedMonth-1]) \(String(selectedYear))")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .id("\(selectedMonth)-\(selectedYear)") // For transition animation
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navigateMonth(forward: true)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 15)
            
            // Weekday headers with refined styling
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppFont.small())
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.top, 5)
            
            // Calendar grid
            calendarGrid
                .padding(.vertical, 5)
            
            // Legend with improved visualization
            HStack(spacing: 30) {
                legendItem(color: .pink, text: "Period", icon: "drop.fill")
                legendItem(color: .green, text: "Ovulation", icon: "sparkles")
                if showFertileWindow {
                    legendItem(color: .yellow, text: "Fertile", icon: "star.fill")
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            
            // Improved instructions
            Text("Tap a date to log period or ovulation")
                .font(AppFont.caption())
                .foregroundColor(.gray)
                .padding(.top, 5)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Cycle settings sheet
    private var cycleSettingsSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") {
                            showSettingsSheet = false
                        }
                        .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Text("Cycle Settings")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveCycleSettings()
                            updateFertileDays()
                            showSettingsSheet = false
                        }
                        .foregroundColor(.pink)
                        .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.white)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Cycle Length Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cycle Settings")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Average Cycle Length
                                    HStack {
                                        Text("Average Cycle Length")
                                            .font(AppFont.body())
                                        
                                        Spacer()
                                        
                                        Picker("\(cycleLength) days", selection: $cycleLength) {
                                            ForEach(21...35, id: \.self) { days in
                                                Text("\(days) days").tag(days)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.pink)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    
                                    Divider()
                                        .padding(.leading)
                                    
                                    // Average Period Length
                                    HStack {
                                        Text("Average Period Length")
                                            .font(AppFont.body())
                                        
                                        Spacer()
                                        
                                        Picker("\(periodLength) days", selection: $periodLength) {
                                            ForEach(2...10, id: \.self) { days in
                                                Text("\(days) days").tag(days)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.pink)
                                    }
                                    .padding()
                                    .background(Color.white)
                                }
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                            .padding(.top)
                            
                            // Display Options
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Display Options")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack {
                                    Toggle("Show Fertile Window", isOn: $showFertileWindow)
                                        .padding()
                                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                            
                            // Information Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Information")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("How Cycle Predictions Work")
                                        .font(AppFont.body().bold())
                                    
                                    Text("Your cycle begins on the first day of your period. The fertile window is calculated based on your average cycle length and typically occurs 12-16 days before your next period is expected to start.")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Cycle logs section
    private var cycleLogs: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cycle Logs")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                // Filter menu
                Menu {
                    Button(action: { filterCycleEvents(type: nil) }) {
                        Label("All Events", systemImage: "list.bullet")
                    }
                    Button(action: { filterCycleEvents(type: .period) }) {
                        Label("Period Only", systemImage: "drop.fill")
                    }
                    Button(action: { filterCycleEvents(type: .ovulation) }) {
                        Label("Ovulation Only", systemImage: "sparkles")
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(AppFont.caption())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            // Cycle statistics card
            cycleStatisticsCard
                .padding(.top, 5)
            
            // Logs list
            VStack(spacing: 10) {
                if cycleEvents.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 30))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No events recorded for this month")
                                .font(AppFont.caption())
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap on calendar dates to start tracking")
                                .font(AppFont.caption())
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 30)
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                } else {
                    ForEach(cycleEvents.sorted(by: { $0.date > $1.date }), id: \.id) { event in
                        cycleEventRow(event: event)
                            .contextMenu {
                                Button(action: {
                                    addNote(to: event)
                                }) {
                                    Label("Add Note", systemImage: "square.and.pencil")
                                }
                                Button(role: .destructive, action: {
                                    deleteEvent(event)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // Cycle statistics card showing insights about the cycle
    private var cycleStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Cycle Insights")
                .font(AppFont.body().bold())
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.top, 10)
            
            HStack(spacing: 20) {
                // Average cycle length
                statisticItem(
                    icon: "clock",
                    value: "\(calculateAverageCycleLength()) days",
                    label: "Avg. Cycle"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Fertile window info
                statisticItem(
                    icon: "star.fill",
                    value: "\(calculateFertileWindowDays()) days",
                    label: "Fertile Window"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Next period prediction
                statisticItem(
                    icon: "calendar",
                    value: nextPeriodPrediction(),
                    label: "Next Period"
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
    
    private func statisticItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.pink)
            
            Text(value)
                .font(AppFont.body().bold())
                .foregroundColor(.black)
            
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func cycleEventRow(event: CycleEvent) -> some View {
        HStack {
            // Icon based on event type
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [colorFor(cycleDayType: event.type), colorFor(cycleDayType: event.type).opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: colorFor(cycleDayType: event.type).opacity(0.3), radius: 2, x: 0, y: 1)
                
                Image(systemName: iconFor(cycleDayType: event.type))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titleFor(cycleDayType: event.type))
                    .font(AppFont.body().bold())
                    .foregroundColor(.primary)
                
                Text(formattedDate(event.date))
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                // Show notes if available
                if !event.notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Text(event.notes)
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeAgo(from: event.timestamp))
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                // Add indicators for pattern matching
                if isCycleStart(date: event.date) && event.type == .period {
                    Text("Cycle Start")
                        .font(AppFont.caption().italic())
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
    
    private var calendarGrid: some View {
        let days = daysInMonth(month: selectedMonth, year: selectedYear)
        let firstWeekday = firstDayOfMonth(month: selectedMonth, year: selectedYear)
        
        return VStack(spacing: 8) {
            ForEach(0..<6) { row in
                HStack(spacing: 8) {
                    ForEach(0..<7) { column in
                        let day = (row * 7 + column) - firstWeekday + 1
                        if day > 0 && day <= days {
                            calendarDay(day: day)
                                .id("day-\(selectedMonth)-\(selectedYear)-\(day)")
                        } else {
                            Color.clear.frame(width: 38, height: 38)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }
    
    private func calendarDay(day: Int) -> some View {
        let date = dateFor(day: day, month: selectedMonth, year: selectedYear)
        let cycleDayType = cycleData[date] ?? .none
        let isToday = Calendar.current.isDateInToday(date)
        
        return ZStack {
            // Background circle with gradient for marked days
            if cycleDayType != .none {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorFor(cycleDayType: cycleDayType),
                                colorFor(cycleDayType: cycleDayType).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: colorFor(cycleDayType: cycleDayType).opacity(0.3), radius: 2, x: 0, y: 1)
            } else {
                Circle()
                    .fill(isToday ? Color.blue.opacity(0.1) : Color.white)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.blue : Color.gray.opacity(0.3), lineWidth: isToday ? 1.5 : 1)
                    )
            }
            
            // Day number
            Text("\(day)")
                .font(isToday ? AppFont.body().weight(.semibold) : AppFont.body())
                .foregroundColor(cycleDayType != .none ? .white : (isToday ? .blue : .primary))
                .fontWeight(isToday ? .semibold : .regular)
            
            // Small indicator icons for each type
            if cycleDayType == .period {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            } else if cycleDayType == .ovulation {
                Image(systemName: "sparkles")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            } else if cycleDayType == .fertile {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            }
        }
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .scaleEffect(cycleDayType != .none ? 1.05 : 1.0)
        // Tap gesture with haptic feedback - now shows dialog
        .onTapGesture {
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            
            self.selectedDate = date
            self.selectedDay = day
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDateActionDialog = true
            }
        }
    }
    
    // Custom dialog for date action
    private func dateActionDialog(date: Date, day: Int) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDateActionDialog = false
                    }
                }
            
            // Dialog content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Mark Day \(day)")
                        .font(AppFont.titleMedium())
                        .foregroundColor(.primary)
                    
                    Text("\(monthNames[selectedMonth-1]) \(day), \(selectedYear)")
                        .font(AppFont.body())
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Options
                VStack(spacing: 15) {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation {
                            markDate(date: date, as: .period)
                            addCycleEvent(date: date, type: .period)
                            showDateActionDialog = false
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.pink)
                                .frame(width: 35)
                            
                            Text("Period")
                                .font(AppFont.body())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if cycleData[date] == .period {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation {
                            markDate(date: date, as: .ovulation)
                            addCycleEvent(date: date, type: .ovulation)
                            showDateActionDialog = false
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                                .frame(width: 35)
                            
                            Text("Ovulation")
                                .font(AppFont.body())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if cycleData[date] == .ovulation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if cycleData[date] != .none {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            withAnimation {
                                cycleData[date] = .none
                                removeCycleEvent(date: date)
                                updateFertileDays()
                                saveCycleData()
                                showDateActionDialog = false
                            }
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22))
                                    .foregroundColor(.red)
                                    .frame(width: 35)
                                
                                Text("Clear Day")
                                    .font(AppFont.body())
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDateActionDialog = false
                    }
                }) {
                    Text("Cancel")
                        .font(AppFont.body().weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 30)
            .transition(.scale)
        }
    }
    
    private func legendItem(color: Color, text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(AppFont.caption())
                .foregroundColor(.gray)
        }
    }
    
    private func sectionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var wellnessTipsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Wellness Tips & Advice")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            HStack(spacing: 15) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pink)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Take Folic Acid")
                        .font(AppFont.body())
                        .foregroundColor(.black)
                    
                    Text("Start taking a prenatal vitamin with folic acid at least 3 months before conception to help prevent neural tube defects")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(Color.pink.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var addButton: some View {
        Button(action: {
            // Show add options for period, test, etc.
        }) {
            ZStack {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func navigateMonth(forward: Bool) {
        if forward {
            if selectedMonth == 12 {
                selectedMonth = 1
                selectedYear += 1
            } else {
                selectedMonth += 1
            }
        } else {
            if selectedMonth == 1 {
                selectedMonth = 12
                selectedYear -= 1
            } else {
                selectedMonth -= 1
            }
        }
        
        loadCycleData()
        loadCycleEvents()
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func firstDayOfMonth(month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        return calendar.component(.weekday, from: date) - 1 // 0 = Sunday
    }
    
    private func dateFor(day: Int, month: Int, year: Int) -> Date {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: dateComponents)!
    }
    
    private func colorFor(cycleDayType: CycleDayType) -> Color {
        switch cycleDayType {
        case .period:
            return .pink
        case .ovulation:
            return .green
        case .fertile:
            return .yellow
        case .none:
            return .white
        }
    }
    
    private func iconFor(cycleDayType: CycleDayType) -> String {
        switch cycleDayType {
        case .period:
            return "drop.fill"
        case .ovulation:
            return "sparkles"
        case .fertile:
            return "star.fill"
        case .none:
            return "circle"
        }
    }
    
    private func titleFor(cycleDayType: CycleDayType) -> String {
        switch cycleDayType {
        case .period:
            return "Period Day"
        case .ovulation:
            return "Ovulation Day"
        case .fertile:
            return "Fertile Day"
        case .none:
            return "Normal Day"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func markDate(date: Date, as type: CycleDayType) {
        // If already marked as this type, clear it
        if cycleData[date] == type {
            cycleData[date] = .none
        } else {
            cycleData[date] = type
        }
        
        // Save to Firestore
        saveCycleData()
        
        // Update fertile days based on period and ovulation
        withAnimation(.easeInOut(duration: 0.3)) {
            updateFertileDays()
        }
    }
    
    private func addCycleEvent(date: Date, type: CycleDayType) {
        // Add to local events list
        let newEvent = CycleEvent(
            id: UUID().uuidString,
            date: date,
            type: type,
            timestamp: Date(),
            notes: ""
        )
        
        // Check if we already have this event (to avoid duplicates)
        if !cycleEvents.contains(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.type == type 
        }) {
            cycleEvents.append(newEvent)
            saveCycleEvent(event: newEvent)
        }
    }
    
    private func removeCycleEvent(date: Date) {
        // Remove from local events list
        cycleEvents.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        
        // Remove from Firestore
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        if let year = components.year, let month = components.month, let day = components.day {
            db.collection("users").document(user.uid)
                .collection("cycleEvents")
                .whereField("year", isEqualTo: year)
                .whereField("month", isEqualTo: month)
                .whereField("day", isEqualTo: day)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        for doc in documents {
                            doc.reference.delete()
                        }
                    }
                }
        }
    }
    
    private func updateFertileDays() {
        // Logic to calculate fertile window based on period and ovulation dates
        
        // Clear existing fertile days
        for (date, type) in cycleData {
            if type == .fertile {
                cycleData[date] = .none
            }
        }
        
        if !showFertileWindow {
            saveCycleData()
            return
        }
        
        // Find period days
        let periodDays = cycleData.filter { $0.value == .period }.map { $0.key }
        
        // If no period days, we can't calculate
        guard let mostRecentPeriod = periodDays.max() else { return }
        
        // Calculate ovulation day (typically cycle length - 14)
        let ovulationDay = cycleLength - 14
        
        // Mark fertile window (typically 5 days before ovulation and 1-2 days after)
        let calendar = Calendar.current
        for i in (ovulationDay-5)...(ovulationDay+1) {
            if let fertileDay = calendar.date(byAdding: .day, value: i, to: mostRecentPeriod) {
                // Don't override existing markings
                if cycleData[fertileDay] == .none {
                    cycleData[fertileDay] = .fertile
                }
            }
        }
        
        saveCycleData()
    }
    
    // Filter cycle events by type
    private func filterCycleEvents(type: CycleDayType?) {
        loadCycleEvents(filterType: type)
    }
    
    // Check if a date is the start of a menstrual cycle
    private func isCycleStart(date: Date) -> Bool {
        // Get all period days
        let periodDays = cycleEvents.filter { $0.type == .period }.map { $0.date }
        
        // Sort them chronologically
        let sortedDays = periodDays.sorted()
        
        // If this is the first period day after a gap, it's a cycle start
        if let index = sortedDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
            if index == 0 {
                return true
            }
            
            // Check if there's more than 2 days gap with previous period day
            let previousDate = sortedDays[index - 1]
            let days = Calendar.current.dateComponents([.day], from: previousDate, to: date).day ?? 0
            
            return days > 2
        }
        
        return false
    }
    
    // Calculate average cycle length based on recorded data or use user settings
    private func calculateAverageCycleLength() -> Int {
        return cycleLength // Use the user's set value
    }
    
    // Calculate fertile window days
    private func calculateFertileWindowDays() -> Int {
        if !showFertileWindow {
            return 0
        }
        
        return 7 // 5 days before ovulation + ovulation day + 1 day after
    }
    
    // Predict next period date
    private func nextPeriodPrediction() -> String {
        // Get the most recent period start
        let periodEvents = cycleEvents.filter { $0.type == .period }
        let sortedPeriodEvents = periodEvents.sorted(by: { $0.date < $1.date })
        
        if let lastPeriod = sortedPeriodEvents.last?.date {
            // Add average cycle length to predict next period
            let averageCycle = calculateAverageCycleLength()
            if let nextPeriodDate = Calendar.current.date(byAdding: .day, value: averageCycle, to: lastPeriod) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: nextPeriodDate)
            }
        }
        
        return "Not enough data"
    }
    
    // Add or edit a note for an event
    private func addNote(to event: CycleEvent) {
        // In a real app, you would show a dialog to edit the note
        // For now we'll just demonstrate updating with a preset note
        
        let updatedEvent = CycleEvent(
            id: event.id,
            date: event.date,
            type: event.type,
            timestamp: event.timestamp,
            notes: "Feeling good today!"
        )
        
        // Update in local array
        if let index = cycleEvents.firstIndex(where: { $0.id == event.id }) {
            cycleEvents[index] = updatedEvent
        }
        
        // Save to Firestore
        saveCycleEvent(event: updatedEvent)
    }
    
    // Delete an event
    private func deleteEvent(_ event: CycleEvent) {
        removeCycleEvent(date: event.date)
        
        // Also clear the calendar marking if needed
        if cycleData[event.date] != nil {
            cycleData[event.date] = .none
            saveCycleData()
        }
    }
    
    // MARK: - Firebase Methods
    
    private func loadCycleData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        isLoading = true
        cycleData.removeAll()
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .collection("cycleData")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading cycle data: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let day = document.data()["day"] as? Int,
                           let typeRaw = document.data()["type"] as? String,
                           let type = CycleDayType(rawValue: typeRaw) {
                            let date = self.dateFor(day: day, month: self.selectedMonth, year: self.selectedYear)
                            self.cycleData[date] = type
                        }
                    }
                    
                    // Apply animation when data is loaded
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                }
            }
    }
    
    private func loadCycleEvents(filterType: CycleDayType? = nil) {
        guard let user = Auth.auth().currentUser else { return }
        
        cycleEvents.removeAll()
        
        let db = Firestore.firestore()
        var query: Query = db.collection("users").document(user.uid)
            .collection("cycleEvents")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
        
        // Add type filter if specified
        if let filterType = filterType {
            query = query.whereField("type", isEqualTo: filterType.rawValue)
        }
        
        query.order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading cycle events: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let year = document.data()["year"] as? Int,
                           let month = document.data()["month"] as? Int,
                           let day = document.data()["day"] as? Int,
                           let typeRaw = document.data()["type"] as? String,
                           let type = CycleDayType(rawValue: typeRaw),
                           let timestamp = document.data()["timestamp"] as? Timestamp,
                           let notes = document.data()["notes"] as? String {
                            
                            let date = self.dateFor(day: day, month: month, year: year)
                            let event = CycleEvent(
                                id: document.documentID,
                                date: date,
                                type: type,
                                timestamp: timestamp.dateValue(),
                                notes: notes
                            )
                            
                            cycleEvents.append(event)
                        }
                    }
                }
            }
    }
    
    private func saveCycleData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete existing data for this month
        db.collection("users").document(user.uid)
            .collection("cycleData")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents to delete: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    // Delete all existing documents for this month
                    for document in snapshot.documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Add new documents for each marked day
                    for (date, type) in self.cycleData {
                        if type != .none {
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.year, .month, .day], from: date)
                            
                            if components.year == self.selectedYear && components.month == self.selectedMonth {
                                let docRef = db.collection("users").document(user.uid)
                                    .collection("cycleData")
                                    .document()
                                
                                let data: [String: Any] = [
                                    "year": self.selectedYear,
                                    "month": self.selectedMonth,
                                    "day": components.day!,
                                    "type": type.rawValue,
                                    "date": date
                                ]
                                
                                batch.setData(data, forDocument: docRef)
                            }
                        }
                    }
                    
                    // Commit the batch
                    batch.commit { error in
                        if let error = error {
                            print("Error saving cycle data: \(error.localizedDescription)")
                        }
                    }
                }
            }
    }
    
    private func saveCycleEvent(event: CycleEvent) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: event.date)
        
        if let year = components.year, let month = components.month, let day = components.day {
            let data: [String: Any] = [
                "year": year,
                "month": month,
                "day": day,
                "type": event.type.rawValue,
                "timestamp": Timestamp(date: event.timestamp),
                "notes": event.notes
            ]
            
            db.collection("users").document(user.uid)
                .collection("cycleEvents")
                .document(event.id)
                .setData(data) { error in
                    if let error = error {
                        print("Error saving cycle event: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    // Load cycle settings from Firestore
    private func loadCycleSettings() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        // First check the user profile for cycle length
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                if let cycleLengthInDays = document.data()?["cycleLengthInDays"] as? Int {
                    // Use the cycle length from user profile
                    self.cycleLength = cycleLengthInDays
                }
                
                // Now load other settings from settings document
                self.loadSettingsDocument()
            } else {
                // If profile document doesn't exist or has error, fall back to settings document
                self.loadSettingsDocument()
            }
        }
    }
    
    // Helper method to load settings from the settings document
    private func loadSettingsDocument() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .collection("settings")
            .document("cycleSettings")
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data() {
                        // Only update cycle length if it wasn't already set from profile
                        if data["cycleLength"] as? Int != nil {
                            // Don't override the profile value if we already have it
                            if self.cycleLength == 28 {
                                self.cycleLength = data["cycleLength"] as? Int ?? 28
                            }
                        }
                        
                        self.periodLength = data["periodLength"] as? Int ?? 5
                        self.showFertileWindow = data["showFertileWindow"] as? Bool ?? true
                    }
                }
            }
    }
    
    // Save cycle settings to Firestore
    private func saveCycleSettings() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        // 1. Update settings document
        let settingsData: [String: Any] = [
            "cycleLength": cycleLength,
            "periodLength": periodLength,
            "showFertileWindow": showFertileWindow,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(user.uid)
            .collection("settings")
            .document("cycleSettings")
            .setData(settingsData) { error in
                if let error = error {
                    print("Error saving cycle settings: \(error.localizedDescription)")
                }
            }
        
        // 2. Update user profile document with the cycle length
        db.collection("users").document(user.uid).updateData([
            "cycleLengthInDays": cycleLength,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating user profile cycle length: \(error.localizedDescription)")
            }
        }
    }
    
    // Add this new method to generate the cycle summary
    private func generateCycleSummary() -> CycleSummary {
        var summary = CycleSummary()
        
        // Set cycle length from settings
        summary.avgCycleLength = cycleLength
        
        // Determine cycle regularity
        summary.cycleRegularity = determineCycleRegularity()
        
        // Get current phase and day of cycle
        summary.currentPhase = currentCyclePhase()
        
        // Find most recent period start to calculate day of cycle
        let periodEvents = cycleEvents.filter { $0.type == .period }
        let sortedPeriodEvents = periodEvents.sorted(by: { $0.date > $1.date })
        
        if let lastPeriod = sortedPeriodEvents.first?.date {
            let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod, to: Date()).day ?? 0
            summary.dayOfCycle = daysSinceLastPeriod + 1 // Add 1 because day 1 is the first day of period
            
            // Calculate next period date
            if let nextPeriodDate = Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                summary.nextPeriod = formatter.string(from: nextPeriodDate)
                
                let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriodDate).day ?? 0
                summary.daysUntilNextPeriod = daysUntil
            }
            
            // Determine fertility status
            let ovulationDay = cycleLength - 14
            if summary.dayOfCycle >= (ovulationDay - 5) && summary.dayOfCycle <= (ovulationDay + 1) {
                summary.fertilityStatus = "Fertile Window"
                if summary.dayOfCycle == ovulationDay {
                    summary.fertilityDetail = "Peak fertility today"
                } else if summary.dayOfCycle > ovulationDay {
                    summary.fertilityDetail = "Late fertile window"
                } else {
                    summary.fertilityDetail = "Early fertile window"
                }
            } else if summary.dayOfCycle < (ovulationDay - 5) {
                summary.fertilityStatus = "Low Fertility"
                summary.fertilityDetail = "Fertile in \(ovulationDay - 5 - summary.dayOfCycle) days"
            } else {
                summary.fertilityStatus = "Non-Fertile"
                summary.fertilityDetail = "Luteal phase"
            }
        }
        
        return summary
    }
    
    // Add this new insights summary view
    private var insightsSummaryView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Cycle Summary")
                        .font(AppFont.body().bold())
                        .foregroundColor(.black)
                    
                    Text("Based on your tracked data")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showInsightsSummary.toggle()
                    }
                }) {
                    Image(systemName: showInsightsSummary ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider()
            
            // Summary grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                summaryCard(
                    icon: "calendar",
                    title: "Cycle Length",
                    value: "\(cycleSummary.avgCycleLength) days",
                    color: .purple,
                    detail: cycleSummary.cycleRegularity
                )
                
                summaryCard(
                    icon: "waveform.path",
                    title: "Current Phase",
                    value: cycleSummary.currentPhase,
                    color: .blue,
                    detail: "Day \(cycleSummary.dayOfCycle) of cycle"
                )
                
                summaryCard(
                    icon: "drop.fill",
                    title: "Next Period",
                    value: cycleSummary.nextPeriod,
                    color: .pink,
                    detail: "\(cycleSummary.daysUntilNextPeriod) days away"
                )
                
                summaryCard(
                    icon: "star.fill",
                    title: "Fertility",
                    value: cycleSummary.fertilityStatus,
                    color: .green,
                    detail: cycleSummary.fertilityDetail
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
    
    // Add this summary card component
    private func summaryCard(icon: String, title: String, value: String, color: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(AppFont.caption())
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(AppFont.body().bold())
                .foregroundColor(.black)
            
            Text(detail)
                .font(AppFont.caption())
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Supporting Types

enum CycleDayType: String {
    case period = "period"
    case ovulation = "ovulation"
    case fertile = "fertile"
    case none = "none"
}

struct CycleEvent: Identifiable {
    let id: String
    let date: Date
    let type: CycleDayType
    let timestamp: Date
    let notes: String
}

struct AIRecommendation: Identifiable {
    let id: String
    let category: String
    let title: String
    let content: String
    let iconName: String
    let color: Color
    let isPersonalized: Bool
}

struct CycleSummary {
    var avgCycleLength: Int = 0
    var cycleRegularity: String = "Unknown"
    var currentPhase: String = "Unknown"
    var dayOfCycle: Int = 0
    var nextPeriod: String = "Unknown"
    var daysUntilNextPeriod: Int = 0
    var fertilityStatus: String = "Unknown"
    var fertilityDetail: String = ""
    
    var isEmpty: Bool {
        return avgCycleLength == 0 && currentPhase == "Unknown"
    }
}

// Add the GeminiAIFertilityGuideView at the end of the file
// AI Fertility Guide View
struct GeminiAIFertilityGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let cycleData: [Date: CycleDayType]
    let cycleLength: Int
    let periodLength: Int
    let cycleEvents: [CycleEvent]
    
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
                // Custom header
                VStack(spacing: 12) {
                    // Header info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fertility Assistant")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Personalized conception guidance")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Cycle stats summary
                    HStack(spacing: 12) {
                        statsItem(value: "\(cycleLength)", title: "Cycle Length", icon: "calendar", color: .purple)
                        
                        statsItem(value: "\(periodLength)", title: "Period Days", icon: "drop.fill", color: .red)
                        
                        if let lastPeriod = findLastPeriodDate() {
                            let daysSince = Calendar.current.dateComponents([.day], from: lastPeriod, to: Date()).day ?? 0
                            statsItem(value: "\(daysSince)", title: "Days Since Period", icon: "clock", color: .blue)
                        }
                        
                        statsItem(value: "\(cycleEvents.count)", title: "Tracked Events", icon: "chart.bar.fill", color: .green)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
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
                    TextField("Ask about fertility or conception...", text: $userInput)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.purple)
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("AI Fertility Guide")
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
            Text("👋 Welcome to Your Fertility Guide")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.purple)
            
            Text("I'm your personal fertility assistant. Here are some things you can ask me:")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                suggestionButton("When is my fertile window?")
                suggestionButton("How can I improve my chances of conception?")
                suggestionButton("What lifestyle changes should I make?")
                suggestionButton("What fertility signs should I track?")
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
                    .background(Color.purple.opacity(0.8))
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
        
        // Create context about the cycle data
        var cycleContext = "Cycle length: \(cycleLength) days, Period length: \(periodLength) days."
        
        // Find last period date
        if let lastPeriod = findLastPeriodDate() {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPeriod, to: Date()).day ?? 0
            cycleContext += " Last period started \(daysSince) days ago."
            
            // Calculate fertile window
            let fertileStart = Calendar.current.date(byAdding: .day, value: cycleLength - 19, to: lastPeriod) ?? Date()
            let fertileEnd = Calendar.current.date(byAdding: .day, value: cycleLength - 10, to: lastPeriod) ?? Date()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let fertileStartStr = formatter.string(from: fertileStart)
            let fertileEndStr = formatter.string(from: fertileEnd)
            
            let now = Date()
            if fertileStart <= now && now <= fertileEnd {
                cycleContext += " Currently in fertile window (\(fertileStartStr) to \(fertileEndStr))."
            } else if now < fertileStart {
                cycleContext += " Next fertile window from \(fertileStartStr) to \(fertileEndStr)."
            } else {
                // Calculate next period and fertile window
                let nextPeriod = Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod) ?? Date()
                let nextFertileStart = Calendar.current.date(byAdding: .day, value: cycleLength - 19, to: nextPeriod) ?? Date()
                let nextFertileEnd = Calendar.current.date(byAdding: .day, value: cycleLength - 10, to: nextPeriod) ?? Date()
                
                let nextPeriodStr = formatter.string(from: nextPeriod)
                let nextFertileStartStr = formatter.string(from: nextFertileStart)
                let nextFertileEndStr = formatter.string(from: nextFertileEnd)
                
                cycleContext += " Next period expected around \(nextPeriodStr). Next fertile window from \(nextFertileStartStr) to \(nextFertileEndStr)."
            }
        } else {
            cycleContext += " No recent period data available."
        }
        
        // Add conception attempts info - fix the filter method
        let intercourseEvents = cycleEvents.filter { event in 
            // Update this when there are proper types for intercourse and insemination
            return event.notes.lowercased().contains("intercourse") || 
                   event.notes.lowercased().contains("insemination")
        }
        
        if !intercourseEvents.isEmpty {
            cycleContext += " Has recorded \(intercourseEvents.count) conception attempts in the last 3 months."
        }
        
        // Create prompt with instructions for brevity
        let prompt = """
        You are a helpful fertility assistant for someone trying to conceive. Here's their cycle information:
        \(cycleContext)
        
        Provide 2-3 concise recommendations to help them optimize their chances of conception. Be extremely brief and direct.
        
        IMPORTANT: Keep each point to 1-2 sentences maximum. Total response should be under 100 words.
        Use bullet points and be straightforward. Avoid explanations, greetings, or unnecessary text.
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
        // Create context with previous conversation and cycle info
        var cycleContext = "Cycle length: \(cycleLength) days, Period length: \(periodLength) days."
        
        if let lastPeriod = findLastPeriodDate() {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPeriod, to: Date()).day ?? 0
            cycleContext += " Last period started \(daysSince) days ago."
        }
        
        // Include previous messages for context
        var conversationHistory = ""
        for message in messages.prefix(6) { // Limit to prevent token overflow
            let role = message.isUser ? "User" : "Assistant"
            conversationHistory += "\(role): \(message.content)\n\n"
        }
        
        // Create prompt with instructions for brevity
        let prompt = """
        You are a helpful fertility assistant. Their cycle information:
        \(cycleContext)
        
        Recent conversation:
        \(conversationHistory)
        
        User's latest question: \(userMessage)
        
        IMPORTANT INSTRUCTIONS:
        - Answer in 3 sentences or less (absolute maximum)
        - Be extremely concise and direct
        - Focus only on answering the specific question
        - No greetings, no explanations, just the answer
        - Total response should be under 50 words
        - Use bullet points if appropriate
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
    
    private func findLastPeriodDate() -> Date? {
        // Find the most recent date marked as period
        let periodDates = cycleData.filter { $0.value == .period }.keys.sorted(by: >)
        return periodDates.first
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

#Preview {
    PrePregnancyView()
} 
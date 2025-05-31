import SwiftUI
import GoogleGenerativeAI
import FirebaseAuth
import FirebaseFirestore

// Message with feedback support
struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let date = Date()
    var feedback: MessageFeedback = .none
}

// Feedback options for AI responses
enum MessageFeedback: String, CaseIterable {
    case none = "None"
    case helpful = "Helpful"
    case notHelpful = "Not Helpful"
    case tooGeneral = "Too General"
    case needsMoreInfo = "Needs More Info"
    case inaccurate = "Inaccurate"
}

// User context to provide to the AI
struct UserHealthContext {
    var currentPregnancyWeek: Int = 0
    var trimester: String = ""
    var dueDate: Date = Date()
    var lastPeriodDate: Date = Date()
    var recentHealthMetrics: [String: String] = [:]
    var age: Int = 0
    var hasRisks: Bool = false
    var riskFactors: [String] = []
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
    
    var formattedLastPeriodDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: lastPeriodDate)
    }
    
    // Create a structured text representation for the AI
    func toPromptText() -> String {
        var contextText = """
        --- User Health Context ---
        Pregnancy Week: \(currentPregnancyWeek > 0 ? String(currentPregnancyWeek) : "Not pregnant")
        Trimester: \(trimester)
        Due Date: \(formattedDueDate)
        Last Period: \(formattedLastPeriodDate)
        Age: \(age)
        """
        
        if !recentHealthMetrics.isEmpty {
            contextText += "\n\nRecent Health Metrics:"
            for (key, value) in recentHealthMetrics {
                contextText += "\n- \(key): \(value)"
            }
        }
        
        if hasRisks && !riskFactors.isEmpty {
            contextText += "\n\nRisk Factors:"
            for factor in riskFactors {
                contextText += "\n- \(factor)"
            }
        }
        
        return contextText
    }
}

struct MaatriView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var userContext = UserHealthContext()
    @State private var isContextLoaded = false
    @State private var showSuggestions = true
    @State private var animateGradient = false
    @State private var showFeedbackSheet = false
    @State private var currentFeedbackMessage: Message? = nil
    @State private var conversationTopics: [String] = []
    @State private var contextualSuggestions: [String] = []
    @State private var conversationSummary: String = ""
    
    // Initialize Gemini model with API key
    private let apiKey = APIKeys.geminiAPIKey
    private var model: GenerativeModel {
        let config = GenerationConfig(maxOutputTokens: 800)
        return GenerativeModel(name: "gemini-1.5-pro", apiKey: apiKey, generationConfig: config)
    }
    
    // Suggested questions based on pregnancy stage
    private var suggestedQuestions: [String] {
        var questions: [String] = []

        // Stage-based questions (add 1-2 generic ones)
        if userContext.currentPregnancyWeek < 1 { // Trying to conceive
            questions.append("Tips for getting pregnant?")
            questions.append("Understanding my fertile window.")
        } else if userContext.currentPregnancyWeek < 14 { // First trimester
            questions.append("Managing first trimester symptoms?")
            questions.append("Safe foods during early pregnancy?")
        } else if userContext.currentPregnancyWeek < 27 { // Second trimester
            questions.append("Recommended exercises for second trimester?")
            questions.append("When will I feel my baby move?")
        } else if userContext.currentPregnancyWeek <= 42 { // Third trimester (up to 42 weeks)
            questions.append("Preparing for labor and delivery?")
            questions.append("What to pack in a hospital bag?")
        } else { // Postpartum or beyond typical pregnancy duration (or if week is 0 but not TTC)
            questions.append("Tips for postpartum recovery?")
            questions.append("Newborn care basics.")
        }

        // Context-specific questions based on UserHealthContext
        var specificQuestions: [String] = []
        if userContext.hasRisks {
            if let firstRisk = userContext.riskFactors.first {
                specificQuestions.append("How to manage risks like \(firstRisk)?")
            } else {
                specificQuestions.append("I have some health risks, what should I be aware of?")
            }
        }

        if userContext.currentPregnancyWeek > 0 && userContext.age > 35 {
            specificQuestions.append("Advice for pregnancy over 35?")
        }

        if !userContext.recentHealthMetrics.isEmpty {
            // Example: if a specific concerning metric was flagged in userContext, add a question.
            // This part requires userContext to have a way to signal "concerning" metrics.
            // For now, let's add a generic one if metrics exist.
            specificQuestions.append("Understanding my recent health metrics.")
        }

        // Combine and prioritize: Add specific questions first, then fill with generic ones.
        var finalSuggestions: [String] = []
        finalSuggestions.append(contentsOf: specificQuestions)

        for q in questions {
            if finalSuggestions.count < 3 && !finalSuggestions.contains(q) { // Limit to 3 suggestions
                finalSuggestions.append(q)
            }
        }

        // If still no suggestions (e.g. week is 0 but not TTC, no specific conditions), add very generic ones.
        if finalSuggestions.isEmpty {
            finalSuggestions.append("General health tips?")
            finalSuggestions.append("Ask me anything about your journey.")
        }

        return Array(Set(finalSuggestions)).prefix(3).map { $0 } // Ensure uniqueness and limit
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.9921568627, green: 0.9098039216, blue: 0.9568627451, alpha: 1)),
                        Color(#colorLiteral(red: 1, green: 0.9686274529, blue: 0.9764705896, alpha: 1)),
                        Color(#colorLiteral(red: 0.9764705896, green: 0.9568627477, blue: 1, alpha: 1))
                    ]),
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                VStack(spacing: 0) {
                    // Chat messages
                    if messages.isEmpty {
                        welcomeView
                    } else {
                        chatView
                    }
                    
                    // Input area with suggestions
                    inputArea
                }
            }
            .navigationTitle("Maatri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSuggestions.toggle()
                    }) {
                        Image(systemName: showSuggestions ? "lightbulb.fill" : "lightbulb")
                            .foregroundColor(.pink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        saveConversation()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.pink)
                    }
                    .disabled(messages.count < 3)
                }
            }
            .sheet(isPresented: $showFeedbackSheet) {
                if let message = currentFeedbackMessage {
                    feedbackView(for: message)
                }
            }
            .onAppear {
                if messages.isEmpty {
                    addInitialMessage()
                }
                loadUserContext()
                setupUserDataListeners()
            }
        }
    }
    
    // Enhanced welcome view
    private var welcomeView: some View {
        VStack(spacing: 25) {
            // Logo animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.pink.opacity(0.2), Color.pink.opacity(0.0)]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 45, weight: .medium))
                    .foregroundColor(.pink)
            }
            
            Text("Maatri AI")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(#colorLiteral(red: 0.8392156863, green: 0.1882352941, blue: 0.4, alpha: 1)))
            
            Text("Your personal maternal health assistant")
                .font(.system(size: 18))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if isContextLoaded {
                contextInfoCard
                    .padding(.top, 10)
            }
            
            Text("Here's how I can help you today:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.gray)
                .padding(.top, 20)
            
            // Feature cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                featureCard(title: "Pregnancy Advice", icon: "heart.text.square")
                featureCard(title: "Symptom Guidance", icon: "cross.case")
                featureCard(title: "Development Tracking", icon: "chart.xyaxis.line")
                featureCard(title: "Nutrition Tips", icon: "fork.knife")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // Feature card for welcome screen
    private func featureCard(title: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.pink)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // User context summary card
    private var contextInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if userContext.currentPregnancyWeek > 0 {
                HStack {
                    Label(
                        title: { Text("Week \(userContext.currentPregnancyWeek)") },
                        icon: { Image(systemName: "calendar") }
                    )
                    .foregroundColor(.pink)
                    
                    Spacer()
                    
                    Text(userContext.trimester + " Trimester")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Label(
                        title: { Text("Planning") },
                        icon: { Image(systemName: "chart.bar") }
                    )
                    .foregroundColor(.pink)
                }
            }
            
            if !userContext.recentHealthMetrics.isEmpty {
                Divider()
                    .padding(.vertical, 2)
                
                HStack {
                    ForEach(Array(userContext.recentHealthMetrics.prefix(2)), id: \.key) { key, value in
                        Label(
                            title: { Text(value) },
                            icon: { Image(systemName: healthMetricIcon(for: key)) }
                        )
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                        
                        if key != Array(userContext.recentHealthMetrics.prefix(2)).last?.key {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    // Icon for health metric
    private func healthMetricIcon(for metric: String) -> String {
        switch metric {
        case "Heart Rate": return "heart.fill"
        case "Temperature": return "thermometer"
        case "SpO2": return "lungs.fill"
        case "Contraction Intensity": return "waveform.path"
        default: return "staroflife"
        }
    }
    
    // Enhanced chat view with feedback options
    private var chatView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        VStack(alignment: .leading, spacing: 0) {
                            MessageBubble(message: message)
                            
                            // Feedback options for AI responses
                            if !message.isUser && message.feedback == .none {
                                HStack {
                                    Spacer()
                                    
                                    Text("Was this helpful?")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 4)
                                    
                                    Button(action: {
                                        provideFeedback(for: message, feedback: .helpful)
                                    }) {
                                        Image(systemName: "hand.thumbsup")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(5)
                                    }
                                    
                                    Button(action: {
                                        currentFeedbackMessage = message
                                        showFeedbackSheet = true
                                    }) {
                                        Image(systemName: "hand.thumbsdown")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(5)
                                    }
                                }
                                .padding(.trailing, 16)
                            }
                            
                            // Show feedback badge if provided
                            if message.feedback != .none && !message.isUser {
                                HStack {
                                    Spacer()
                                    
                                    if message.feedback == .helpful {
                                        Label("Helpful", systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.green.opacity(0.1))
                                            )
                                    } else {
                                        Text(message.feedback.rawValue)
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.orange.opacity(0.1))
                                            )
                                    }
                                }
                                .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    if isLoading {
                        typingIndicator
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, showSuggestions ? 16 : 68)
            }
            .onChange(of: messages.count) { _ in
                if let lastID = messages.last?.id {
                    withAnimation {
                        scrollView.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.clear)
    }
    
    // Typing indicator
    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 2) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 18))
                .foregroundColor(.pink)
                .padding(8)
                .background(Circle().fill(Color.white))
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.pink.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .offset(y: index % 2 == 0 ? -2 : 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
        }
    }
    
    // Enhanced input area
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Suggestion chips
            if showSuggestions && messages.count > 0 && !isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let questionsToDisplay = contextualSuggestions.isEmpty ? suggestedQuestions : contextualSuggestions
                        ForEach(questionsToDisplay, id: \.self) { question in
                            Button(action: {
                                inputText = question
                                sendMessage()
                            }) {
                                Text(question)
                                    .font(.system(size: 14))
                                    .foregroundColor(.pink)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1.5)
                                            .background(Capsule().fill(Color.white.opacity(0.7)))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.95),
                                    Color.white
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
                )
            }
            
            // Text input and send button
            HStack(spacing: 12) {
                HStack {
                    TextField("Ask Maatri...", text: $inputText)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .disabled(isLoading)
                }
                
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
        }
    }
    
    // Add welcome message
    private func addInitialMessage() {
        let welcomeMessage = Message(
            content: "Hello! I'm Maatri, your personal maternal health assistant. I'm here to support you on your pregnancy journey with reliable information and guidance. How can I help you today?",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
    // Load user data from Firestore
    private func loadUserContext() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else { return }
            
            // Parse basic user data
            var newContext = UserHealthContext()
            
            // Get user's age
            if let age = document.data()?["age"] as? Int {
                newContext.age = age
            }
            
            // Get pregnancy info
            if let lastPeriodTimestamp = document.data()?["lastPeriodDate"] as? Timestamp {
                let lastPeriodDate = lastPeriodTimestamp.dateValue()
                newContext.lastPeriodDate = lastPeriodDate
                
                // Calculate current week
                let days = Calendar.current.dateComponents([.day], from: lastPeriodDate, to: Date()).day ?? 0
                let week = days / 7
                newContext.currentPregnancyWeek = week
                
                // Determine trimester
                if week <= 13 {
                    newContext.trimester = "First"
                } else if week <= 26 {
                    newContext.trimester = "Second"
                } else {
                    newContext.trimester = "Third"
                }
                
                // Calculate due date (40 weeks from LMP)
                newContext.dueDate = Calendar.current.date(byAdding: .day, value: 280, to: lastPeriodDate) ?? Date()
            }
            
            // Get risk factors if any
            if let risks = document.data()?["riskFactors"] as? [String], !risks.isEmpty {
                newContext.hasRisks = true
                newContext.riskFactors = risks
            }
            
            // Load latest health metrics
            loadLatestHealthMetrics(userId: userId) { metrics in
                newContext.recentHealthMetrics = metrics
                self.userContext = newContext
                self.isContextLoaded = true
            }
        }
    }
    
    // Load the latest health metrics from Firestore
    private func loadLatestHealthMetrics(userId: String, completion: @escaping ([String: String]) -> Void) {
        let db = Firestore.firestore()
        var metrics: [String: String] = [:]
        
        db.collection("users").document(userId).collection("healthData")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading health metrics: \(error.localizedDescription)")
                    completion(metrics)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(metrics)
                    return
                }
                
                if let heartRate = document.data()["heartRate"] as? Double {
                    metrics["Heart Rate"] = "\(Int(heartRate)) bpm"
                }
                
                if let temperature = document.data()["temperature"] as? Double {
                    metrics["Temperature"] = String(format: "%.1f°C", temperature)
                }
                
                if let spo2 = document.data()["spo2"] as? Double {
                    metrics["SpO2"] = "\(Int(spo2))%"
                }
                
                if let contractionIntensity = document.data()["contractionIntensity"] as? Double {
                    metrics["Contraction Intensity"] = "\(Int(contractionIntensity))"
                }
                
                completion(metrics)
            }
    }
    
    // Set up listeners for real-time updates to user data
    private func setupUserDataListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Listen for changes to the user document
        db.collection("users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error listening for user updates: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                // Update user context when data changes
                loadUserContext()
            }
        
        // Listen for changes to health metrics
        db.collection("users").document(userId).collection("healthData")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening for health metrics updates: \(error.localizedDescription)")
                    return
                }
                
                // Update health metrics when new data is available
                loadLatestHealthMetrics(userId: userId) { metrics in
                    self.userContext.recentHealthMetrics = metrics
                }
            }
    }
    
    // Enhanced sendMessage to include previous messages for context
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputText, isUser: true)
        messages.append(userMessage)
        
        let userInput = inputText
        inputText = ""
        isLoading = true
        
        // Generate a response using Gemini with enhanced context
        Task {
            do {
                // Include user context and conversation history
                let contextInfo = userContext.toPromptText()
                
                // Determine use case for specific instructions
                var useCaseSpecificInstructions = ""
                let lowercasedUserInput = userInput.lowercased()

                // 1. Symptom-related query
                let symptomKeywords = ["symptom", "feel", "nausea", "headache", "tired", "cramp", "swelling", "pain"]
                if symptomKeywords.contains(where: lowercasedUserInput.contains) {
                    useCaseSpecificInstructions = """
                    The user is asking about a physical symptom.
                    When responding:
                    1. Acknowledge the symptom.
                    2. Briefly state if it's common for their current stage (if context allows, otherwise general).
                    3. Offer 1-2 general self-care tips or explanations if appropriate.
                    4. Clearly state when they should consult a healthcare provider regarding this symptom (e.g., if severe, persistent, or accompanied by other specific signs).
                    Your primary goal is to be informative and safe, not to diagnose.
                    """
                }
                // 2. Nutrition/Food query
                let nutritionKeywords = ["eat", "drink", "food", "diet", "nutrition", "avoid", "caffeine", "cheese", "fish", "supplement"]
                if nutritionKeywords.contains(where: lowercasedUserInput.contains) {
                    useCaseSpecificInstructions = """
                    The user has a nutrition-related question.
                    When responding:
                    1. Provide clear, evidence-based information regarding the food or nutrient in question.
                    2. Specify if it's generally safe, to be consumed in moderation, or to be avoided during pregnancy/breastfeeding (if context allows).
                    3. If suggesting alternatives or good sources, list 1-2 examples.
                    4. If the query is complex or relates to specific dietary needs/deficiencies, suggest consulting a doctor or registered dietitian.
                    """
                }
                // 3. Emotional well-being query
                let emotionKeywords = ["sad", "anxious", "stressed", "worried", "depressed", "mood", "feeling down"]
                if emotionKeywords.contains(where: lowercasedUserInput.contains) {
                    useCaseSpecificInstructions = """
                    The user is expressing emotional distress or asking about mental well-being.
                    When responding:
                    1. Acknowledge their feelings with empathy and validation.
                    2. Normalize their experience if appropriate (e.g., "It's common to feel anxious during pregnancy.").
                    3. Suggest 1-2 simple, actionable self-care or coping strategies (e.g., talking to someone, mindfulness, gentle exercise if appropriate).
                    4. Gently encourage them to speak with their healthcare provider or a mental health professional if feelings are overwhelming, persistent, or significantly impacting their daily life. Avoid trying to act as a therapist.
                    """
                }

                // Include the last 5 messages for context
                var conversationHistory = ""
                let recentMessages = messages.suffix(min(5, messages.count - 1)) // Exclude the message just added
                for message in recentMessages {
                    let role = message.isUser ? "User" : "Maatri"
                    conversationHistory += "\(role): \(message.content)\n\n"
                }
                
                // Check for any negative feedback to improve responses
                let feedbackMessages = messages.filter { !$0.isUser && $0.feedback != .none && $0.feedback != .helpful }
                var feedbackGuidance = ""
                if !feedbackMessages.isEmpty {
                    feedbackGuidance = "\nPrevious responses have received feedback indicating they were: "
                    let feedbackTypes = Set(feedbackMessages.map { $0.feedback.rawValue })
                    feedbackGuidance += feedbackTypes.joined(separator: ", ")
                    feedbackGuidance += ". Please ensure your response addresses these concerns."
                }
                
                let prompt = """
                You are Maatri, a compassionate and informative maternal health assistant specialized in pregnancy, fertility, and maternal care. 
                
                Here is information about the user you're helping:
                \(contextInfo)
                
                Recent conversation history:
                \(conversationHistory)
                
                \(useCaseSpecificInstructions)

                Answer the following message from this user who is using the MaaKosh app for maternal health tracking:

                User message: \(userInput)
                
                IMPORTANT FORMATTING GUIDELINES:
                - Write in plain text only - no markdown formatting
                - Do not use asterisks (*) for emphasis or bullets
                - Do not use hashtags (#) for headers
                - Do not use underscores (_) for emphasis
                - Do not use any special characters for formatting
                - Use simple paragraph breaks for structure
                - If you need to make a list, use simple numbers or hyphens with spaces
                
                Keep your response friendly, supportive and concise. 
                Make specific reference to their pregnancy stage, health metrics, or other relevant personal information where appropriate.
                Focus on providing evidence-based information about maternal health, pregnancy, and conception.
                If the user asks something outside your expertise, politely suggest consulting a healthcare provider.
                Do not explicitly mention that you have their health context or data in your response, just use it to personalize your answer.
                \(feedbackGuidance)
                """
                
                let response = try await model.generateContent(prompt)
                
                if let responseText = response.text {
                    // Process the response to remove any markdown formatting
                    let cleanedResponse = cleanMarkdownFormatting(responseText)
                    
                    DispatchQueue.main.async {
                        messages.append(Message(content: cleanedResponse, isUser: false))
                        isLoading = false
                        
                        // Analyze the conversation topics in background
                        analyzeConversationTopics()
                    }
                } else {
                    handleError("Could not generate a response")
                }
            } catch {
                handleError(error.localizedDescription)
            }
        }
    }
    
    // Function to clean any markdown formatting from the AI response
    private func cleanMarkdownFormatting(_ text: String) -> String {
        var cleanedText = text
        
        // Replace markdown heading patterns (# Text)
        let headingRegex = try? NSRegularExpression(pattern: "#+ (.*?)(\n|$)", options: [])
        cleanedText = headingRegex?.stringByReplacingMatches(
            in: cleanedText,
            options: [],
            range: NSRange(location: 0, length: cleanedText.count),
            withTemplate: "$1$2") ?? cleanedText
        
        // Replace asterisks for bold/italic
        cleanedText = cleanedText.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "\\*(.*?)\\*", with: "$1", options: .regularExpression)
        
        // Replace underscores for italic
        cleanedText = cleanedText.replacingOccurrences(of: "\\_(.*?)\\_", with: "$1", options: .regularExpression)
        
        // Replace backticks for code blocks
        let codeBlockPattern = "```[\\s\\S]*?```"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let nsString = cleanedText as NSString
            let range = NSRange(location: 0, length: nsString.length)
            cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
        }
        
        // Replace inline code
        cleanedText = cleanedText.replacingOccurrences(of: "`(.*?)`", with: "$1", options: .regularExpression)
        
        // Replace markdown links [text](url) with just text
        cleanedText = cleanedText.replacingOccurrences(of: "\\[(.*?)\\]\\(.*?\\)", with: "$1", options: .regularExpression)
        
        // Convert markdown bullet points to simple hyphens with space
        let bulletPattern = "^\\s*[\\*\\-\\+]\\s+"
        if let regex = try? NSRegularExpression(pattern: bulletPattern, options: [.anchorsMatchLines]) {
            let nsString = cleanedText as NSString
            let range = NSRange(location: 0, length: nsString.length)
            cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "- ")
        }
        
        return cleanedText
    }
    
    // Analyze conversation to identify topics
    private func analyzeConversationTopics() {
        // Only analyze if there are enough messages
        guard messages.count >= 4 else { return }
        
        // Build conversation text from the last 6 messages
        var conversationText = ""
        for message in messages.suffix(min(6, messages.count)) {
            let role = message.isUser ? "User" : "AI"
            conversationText += "\(role): \(message.content)\n\n"
        }
        
        Task {
            do {
                let prompt = """
                Analyze this maternal health conversation and extract 3-5 main topics being discussed.
                Return only the topics as a comma-separated list without numbering or explanation.
                Example: "morning sickness, nutrition, first trimester symptoms"
                
                Conversation:
                \(conversationText)
                """
                
                let response = try await model.generateContent(prompt)
                
                if let topicsText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let topics = topicsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    DispatchQueue.main.async {
                        conversationTopics = topics
                        
                        // Update suggested questions based on topics
                        updateSuggestedQuestions(based: topics)
                    }
                }
            } catch {
                print("Error analyzing conversation topics: \(error.localizedDescription)")
            }
        }
    }
    
    // Update suggested questions based on conversation topics
    private func updateSuggestedQuestions(based topics: [String]) {
        var newSuggestions: [String] = []
        guard !topics.isEmpty else {
            // If no topics, clear contextual suggestions or revert to default
            DispatchQueue.main.async {
                self.contextualSuggestions = [] // Or set to default stage-based suggestions if preferred
            }
            return
        }

        for topic in topics.prefix(2) { // Take top 2 topics to generate 1-2 suggestions
            let sanitizedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !sanitizedTopic.isEmpty {
                newSuggestions.append("Tell me more about \(sanitizedTopic).")
                // Example of a second type of follow-up, can be more varied
                if sanitizedTopic.contains("symptom") || sanitizedTopic.contains("feel") {
                    newSuggestions.append("What can I do about \(sanitizedTopic)?")
                } else if sanitizedTopic.contains("food") || sanitizedTopic.contains("nutrition") {
                    newSuggestions.append("Are there foods to avoid related to \(sanitizedTopic)?")
                }
            }
        }

        // Limit the number of contextual suggestions
        let finalSuggestions = Array(Set(newSuggestions)).prefix(2) // Remove duplicates and take max 2

        DispatchQueue.main.async {
            self.contextualSuggestions = Array(finalSuggestions)
            if !self.contextualSuggestions.isEmpty {
                self.showSuggestions = true // Ensure suggestions are visible if we have new ones
            }
        }
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            messages.append(Message(
                content: "I'm sorry, I encountered an error. Please try again later.",
                isUser: false
            ))
            isLoading = false
        }
    }
    
    // Feedback view for detailed feedback
    private func feedbackView(for message: Message) -> some View {
        VStack(spacing: 16) {
            Text("Help us improve Maatri")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 20)
            
            Text("What was the issue with this response?")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                ForEach(MessageFeedback.allCases.filter { $0 != .none && $0 != .helpful }, id: \.self) { feedback in
                    Button(action: {
                        provideFeedback(for: message, feedback: feedback)
                        showFeedbackSheet = false
                    }) {
                        HStack {
                            Text(feedback.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Cancel") {
                showFeedbackSheet = false
            }
            .foregroundColor(.pink)
            .padding(.bottom, 20)
        }
        .padding()
    }
    
    // Save user feedback for AI training
    private func provideFeedback(for message: Message, feedback: MessageFeedback) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        
        // Update message in the UI
        messages[index].feedback = feedback
        
        // Save feedback to Firestore
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let feedbackData: [String: Any] = [
            "userId": userId,
            "message": message.content,
            "feedback": feedback.rawValue,
            "timestamp": Timestamp(date: Date()),
            "userContext": userContext.toPromptText()
        ]
        
        let db = Firestore.firestore()
        db.collection("feedback").addDocument(data: feedbackData) { error in
            if let error = error {
                print("Error saving feedback: \(error.localizedDescription)")
            }
        }
    }
    
    // Save conversation for future training
    private func saveConversation() {
        guard let userId = Auth.auth().currentUser?.uid,
              !messages.isEmpty else { return }
        
        // First, generate conversation summary using Gemini
        Task {
            do {
                // Build conversation text
                var conversationText = ""
                for message in messages {
                    let role = message.isUser ? "User" : "AI"
                    conversationText += "\(role): \(message.content)\n\n"
                }
                
                let prompt = """
                Analyze this maternal health conversation and provide:
                1. A 1-2 sentence summary of what was discussed
                2. A list of 3-5 key topics/keywords that were covered
                3. Rate the quality and helpfulness of the AI responses on a scale of 1-10
                
                Conversation:
                \(conversationText)
                """
                
                let response = try await model.generateContent(prompt)
                
                if let analysisText = response.text {
                    // Save the conversation with analysis
                    let conversationData: [String: Any] = [
                        "userId": userId,
                        "messages": messages.map { [
                            "content": $0.content,
                            "isUser": $0.isUser,
                            "timestamp": Timestamp(date: $0.date),
                            "feedback": $0.feedback.rawValue
                        ] },
                        "analysis": analysisText,
                        "userContext": userContext.toPromptText(),
                        "timestamp": Timestamp(date: Date())
                    ]
                    
                    let db = Firestore.firestore()
                    db.collection("conversations").addDocument(data: conversationData) { error in
                        if let error = error {
                            print("Error saving conversation: \(error.localizedDescription)")
                        } else {
                            // Success notification
                            let successMessage = Message(
                                content: "This conversation has been saved to help improve Maatri. Thank you for your contribution!",
                                isUser: false
                            )
                            DispatchQueue.main.async {
                                messages.append(successMessage)
                            }
                        }
                    }
                }
            } catch {
                print("Error analyzing conversation: \(error.localizedDescription)")
            }
        }
    }
}

// Enhanced message bubble
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundColor(.pink)
                    .padding(8)
                    .background(Circle().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isUser ? 
                                  LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.8392156863, green: 0.1882352941, blue: 0.4, alpha: 1)), Color(#colorLiteral(red: 0.968627451, green: 0.3647058824, blue: 0.5647058824, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                  LinearGradient(gradient: Gradient(colors: [Color.white, Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    )
                    .foregroundColor(message.isUser ? .white : .black)
                
                // Timestamp
                Text(formatTime(message.date))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if message.isUser {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(#colorLiteral(red: 0.8392156863, green: 0.1882352941, blue: 0.4, alpha: 1)))
            } else {
                Spacer()
            }
        }
        .id(message.id)
        .padding(.horizontal, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MaatriView_Previews: PreviewProvider {
    static var previews: some View {
        MaatriView()
    }
} 
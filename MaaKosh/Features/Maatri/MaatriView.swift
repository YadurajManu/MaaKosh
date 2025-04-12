import SwiftUI
import GoogleGenerativeAI
import FirebaseAuth
import FirebaseFirestore

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let date = Date()
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
    
    // Initialize Gemini model with API key
    private let apiKey = "AIzaSyCueBkZoml0YMVXHxtMZeE7Xn-0iqDRpGU"
    private var model: GenerativeModel {
        let config = GenerationConfig(maxOutputTokens: 800)
        return GenerativeModel(name: "gemini-1.5-pro", apiKey: apiKey, generationConfig: config)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Welcome message header
                if messages.isEmpty {
                    welcomeView
                }
                
                // Chat messages
                ScrollViewReader { scrollView in
                    List {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onChange(of: messages.count) { _ in
                        if let lastID = messages.last?.id {
                            withAnimation {
                                scrollView.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // User context info indicator
                if isContextLoaded {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.pink)
                        Text("AI has your pregnancy data")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        TextField("Ask Maatri...", text: $inputText)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(25)
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.pink)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white)
                }
            }
            .navigationTitle("Maatri")
            .onAppear {
                if messages.isEmpty {
                    addInitialMessage()
                }
                loadUserContext()
                setupUserDataListeners()
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 15) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 70))
                .foregroundColor(.pink.opacity(0.7))
                .padding()
            
            Text("Maatri AI Assistant")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Text("Your personal maternal health assistant powered by AI")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
    
    private func addInitialMessage() {
        let welcomeMessage = Message(
            content: "Hello, I'm Maatri, your maternal health assistant. How can I help you today?",
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
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputText, isUser: true)
        messages.append(userMessage)
        
        let userInput = inputText
        inputText = ""
        isLoading = true
        
        // Generate a response using Gemini with user context
        Task {
            do {
                // Include user context in the prompt
                let contextInfo = userContext.toPromptText()
                
                let prompt = """
                You are Maatri, a compassionate and informative maternal health assistant specialized in pregnancy, fertility, and maternal care. 
                
                Here is information about the user you're helping:
                \(contextInfo)
                
                Answer the following message from this user who is using the MaaKosh app for maternal health tracking:

                User message: \(userInput)
                
                Keep your response friendly, supportive and concise. 
                Make specific reference to their pregnancy stage, health metrics, or other relevant personal information where appropriate.
                Focus on providing evidence-based information about maternal health, pregnancy, and conception.
                If the user asks something outside your expertise, politely suggest consulting a healthcare provider.
                Do not explicitly mention that you have their health context or data in your response, just use it to personalize your answer.
                """
                
                let response = try await model.generateContent(prompt)
                
                if let responseText = response.text {
                    DispatchQueue.main.async {
                        messages.append(Message(content: responseText, isUser: false))
                        isLoading = false
                    }
                } else {
                    handleError("Could not generate a response")
                }
            } catch {
                handleError(error.localizedDescription)
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
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.pink : Color(.systemGray6))
                    .foregroundColor(message.isUser ? .white : .black)
                    .cornerRadius(18)
                    .padding(message.isUser ? .leading : .trailing, 30)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .id(message.id)
    }
}

struct MaatriView_Previews: PreviewProvider {
    static var previews: some View {
        MaatriView()
    }
} 
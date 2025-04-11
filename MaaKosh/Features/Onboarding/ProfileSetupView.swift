//
//  ProfileSetupView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileSetupView: View {
    @State private var userProfile = UserProfile()
    @State private var showDatePicker = false
    @State private var activeField: FormField? = nil
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToHome = false
    @State private var currentStep = 1
    @State private var showingTooltip: FormField? = nil
    
    // Form configuration
    private let totalSteps = 5
    private let cycleOptions = [21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35]
    
    // Input validation flags
    private var isAgeValid: Bool { userProfile.age >= 13 && userProfile.age <= 60 }
    private var isPhoneValid: Bool { userProfile.phoneNumber.count >= 10 }
    private var isDateValid: Bool { userProfile.lastPeriodDate <= Date() }
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1: return isAgeValid
        case 2: return isPhoneValid
        case 3: return true // Partner name is optional
        case 4: return isDateValid
        case 5: return true // Cycle length always has a default valid value
        default: return false
        }
    }
    
    enum FormField: String {
        case age, phone, partner, period, cycle
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header with progress indicator
                VStack(spacing: 15) {
                    Text("Setup Your Profile")
                        .font(AppFont.titleMedium())
                        .foregroundColor(Color.maakoshDeepPink)
                    
                    Text("Step \(currentStep) of \(totalSteps)")
                        .font(AppFont.caption())
                        .foregroundColor(Color.black.opacity(0.6))
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(height: 8)
                                .foregroundColor(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: CGFloat(currentStep) / CGFloat(totalSteps) * geometry.size.width, height: 8)
                                .foregroundColor(Color.maakoshDeepPink)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                }
                .padding(.top, 40)
                
                // Form section
                ScrollView {
                    VStack(spacing: 30) {
                        // Dynamic form content based on current step
                        Group {
                            if currentStep == 1 {
                                ageInputView
                            } else if currentStep == 2 {
                                phoneInputView
                            } else if currentStep == 3 {
                                partnerInputView
                            } else if currentStep == 4 {
                                periodDateInputView
                            } else if currentStep == 5 {
                                cycleLengthInputView
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .animation(.easeInOut, value: currentStep)
                        
                        Spacer()
                        
                        // Navigation buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                if currentStep == totalSteps {
                                    saveProfile()
                                } else {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                            }) {
                                ZStack {
                                    Text(currentStep == totalSteps ? "Complete Setup" : "Next")
                                        .font(AppFont.buttonText())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(isCurrentStepValid ? Color.maakoshDeepPink : Color.gray.opacity(0.5))
                                        .cornerRadius(15)
                                        .shadow(color: isCurrentStepValid ? Color.maakoshDeepPink.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.3)
                                    }
                                }
                            }
                            .disabled(!isCurrentStepValid || isLoading)
                            
                            if currentStep > 1 {
                                Button(action: {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }) {
                                    Text("Back")
                                        .font(AppFont.body())
                                        .foregroundColor(Color.maakoshDeepPink)
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            hideKeyboard()
            showingTooltip = nil
        }
        .fullScreenCover(isPresented: $navigateToHome) {
            ContentView()
        }
    }
    
    // MARK: - Form Fields
    
    // Age input field
    private var ageInputView: some View {
        FormCard {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text("How old are you?")
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.black.opacity(0.8))
                
                Text("Your age helps us personalize your experience")
                    .font(AppFont.caption())
                    .foregroundColor(Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    TextField("Your age", value: $userProfile.age, format: .number)
                        .font(AppFont.body())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(
                                    userProfile.age == 0 ? Color.maakoshMediumPink.opacity(0.2) : 
                                        (isAgeValid ? Color.green.opacity(0.5) : Color.red.opacity(0.5)), 
                                    lineWidth: 1
                                )
                        )
                        .frame(width: 120)
                        .onTapGesture {
                            activeField = .age
                            showingTooltip = .age
                        }
                    
                    Text("years")
                        .font(AppFont.body())
                        .foregroundColor(Color.black.opacity(0.7))
                }
                
                if showingTooltip == .age {
                    TooltipView(text: "Please enter your age (between 13-60)")
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // Phone number input field
    private var phoneInputView: some View {
        FormCard {
            VStack(spacing: 20) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text("What's your phone number?")
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.black.opacity(0.8))
                
                Text("We'll use this for account recovery and important updates")
                    .font(AppFont.caption())
                    .foregroundColor(Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Your phone number", text: $userProfile.phoneNumber)
                    .font(AppFont.body())
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                userProfile.phoneNumber.isEmpty ? Color.maakoshMediumPink.opacity(0.2) : 
                                    (isPhoneValid ? Color.green.opacity(0.5) : Color.red.opacity(0.5)), 
                                lineWidth: 1
                            )
                    )
                    .onTapGesture {
                        activeField = .phone
                        showingTooltip = .phone
                    }
                
                if showingTooltip == .phone {
                    TooltipView(text: "Please enter a valid phone number (at least 10 digits)")
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // Partner name input field
    private var partnerInputView: some View {
        FormCard {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text("Your partner's name")
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.black.opacity(0.8))
                
                Text("Optional: Enter your partner's name for personalized content")
                    .font(AppFont.caption())
                    .foregroundColor(Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Partner's name (optional)", text: $userProfile.partnerName)
                    .font(AppFont.body())
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.maakoshMediumPink.opacity(0.2), lineWidth: 1)
                    )
                    .onTapGesture {
                        activeField = .partner
                    }
            }
            .padding(.vertical, 20)
        }
    }
    
    // Last period date input field
    private var periodDateInputView: some View {
        FormCard {
            VStack(spacing: 20) {
                Image(systemName: "calendar")
                    .font(.system(size: 40))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text("Last Menstrual Period")
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.black.opacity(0.8))
                
                Text("When did your last period start?")
                    .font(AppFont.caption())
                    .foregroundColor(Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        showDatePicker.toggle()
                        activeField = .period
                    }
                }) {
                    HStack {
                        Text(formatDate(userProfile.lastPeriodDate))
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(Color.maakoshDeepPink)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.maakoshMediumPink.opacity(0.2), lineWidth: 1)
                    )
                }
                
                if showDatePicker {
                    DatePicker(
                        "Select date",
                        selection: $userProfile.lastPeriodDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .transition(.scale.combined(with: .opacity))
                }
                
                if !isDateValid && showingTooltip == .period {
                    TooltipView(text: "Last period date cannot be in the future")
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // Cycle length input field
    private var cycleLengthInputView: some View {
        FormCard {
            VStack(spacing: 20) {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.maakoshDeepPink)
                
                Text("Menstrual Cycle Length")
                    .font(AppFont.titleSmall())
                    .foregroundColor(Color.black.opacity(0.8))
                
                Text("What is your average cycle length?")
                    .font(AppFont.caption())
                    .foregroundColor(Color.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    Picker("Cycle Length", selection: $userProfile.cycleLengthInDays) {
                        ForEach(cycleOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.maakoshMediumPink.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Text("The average cycle length is 28 days")
                    .font(AppFont.small())
                    .foregroundColor(Color.black.opacity(0.5))
                    .padding(.top, 5)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        showDatePicker = false
        activeField = nil
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found. Please try signing in again."
            showAlert = true
            return
        }
        
        isLoading = true
        
        userProfile.isProfileComplete = true
        userProfile.saveToFirestore(userId: user.uid) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Failed to save profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Navigate to main content view
                navigateToHome = true
            }
        }
    }
}

// Card container for form sections
struct FormCard<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ProfileSetupView()
} 
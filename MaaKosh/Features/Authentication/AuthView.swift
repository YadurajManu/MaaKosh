//
//  AuthView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum AuthViewState {
    case signIn
    case signUp
}

enum PasswordStrength: Int {
    case weak = 0
    case medium = 1
    case strong = 2
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

struct AuthView: View {
    @State private var authState: AuthViewState = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isAuthenticated = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var termsAccepted = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var isLoading = false
    
    // Validation states
    @State private var isEmailValid = false
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var showPasswordStrength = false
    
    // Tooltip states
    @State private var showEmailTooltip = false
    @State private var showPasswordTooltip = false
    @State private var showNameTooltip = false
    
    private var isFormValid: Bool {
        isEmailValid && !password.isEmpty && 
        (authState == .signIn || (!fullName.isEmpty && termsAccepted))
    }
    
    private var passwordStrength: PasswordStrength {
        let hasUppercase = password.contains { $0.isUppercase }
        let hasLowercase = password.contains { $0.isLowercase }
        let hasDigit = password.contains { $0.isNumber }
        let hasSpecialChar = password.contains { !$0.isLetter && !$0.isNumber }
        
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if hasUppercase && hasLowercase { strength += 1 }
        if hasDigit || hasSpecialChar { strength += 1 }
        
        return PasswordStrength(rawValue: min(strength, 2)) ?? .weak
    }
    
    var body: some View {
        if isAuthenticated {
            ContentView()
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo and title
                        VStack(spacing: 10) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: Color.maakoshDeepPink.opacity(0.2), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .rotation3DEffect(
                                    .degrees(3),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                            
                            Text("MaaKosh")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color.maakoshDeepPink)
                            
                            Text(authState == .signIn ? "Welcome Back" : "Create Account")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.7))
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                        
                        // Authentication form
                        VStack(spacing: 25) {
                            if authState == .signUp {
                                // Full name field (only for sign up)
                                VStack(alignment: .leading, spacing: 5) {
                                    AuthTextField(
                                        iconName: "person.fill",
                                        placeholder: "Full Name",
                                        text: $fullName,
                                        isValid: .constant(fullName.count >= 3),
                                        isFocused: $showNameTooltip
                                    )
                                    
                                    // Name tooltip
                                    if showNameTooltip {
                                        TooltipView(text: "Enter your full name (minimum 3 characters)")
                                    }
                                }
                            }
                            
                            // Email field with validation
                            VStack(alignment: .leading, spacing: 5) {
                                AuthTextField(
                                    iconName: "envelope.fill",
                                    placeholder: "Email",
                                    text: $email,
                                    isValid: $isEmailValid,
                                    isFocused: $isEmailFocused,
                                    keyboardType: .emailAddress,
                                    validator: { email in
                                        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
                                        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
                                        return emailPredicate.evaluate(with: email) && email.count > 5
                                    }
                                )
                                .onChange(of: email) { _ in
                                    showEmailTooltip = isEmailFocused && !isEmailValid && email.count > 0
                                }
                                .onTapGesture {
                                    showEmailTooltip = !isEmailValid && email.count > 0
                                }
                                
                                // Email tooltip
                                if showEmailTooltip {
                                    TooltipView(text: "Enter a valid email address (e.g., name@example.com)")
                                }
                            }
                            
                            // Password field with strength meter
                            VStack(alignment: .leading, spacing: 5) {
                                AuthSecureField(
                                    iconName: "lock.fill",
                                    placeholder: "Password",
                                    text: $password,
                                    isFocused: $isPasswordFocused
                                )
                                .onChange(of: password) { _ in
                                    showPasswordStrength = password.count > 0
                                    showPasswordTooltip = isPasswordFocused && password.count > 0 && passwordStrength == .weak
                                }
                                .onTapGesture {
                                    showPasswordTooltip = password.count > 0 && passwordStrength == .weak
                                }
                                
                                // Password strength meter (only if password has content)
                                if showPasswordStrength {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Password Strength: \(passwordStrength.description)")
                                            .font(.system(size: 12))
                                            .foregroundColor(passwordStrength.color)
                                        
                                        // Strength meter bar
                                        GeometryReader { geometry in
                                            HStack(spacing: 5) {
                                                ForEach(0..<3) { index in
                                                    Rectangle()
                                                        .fill(index <= passwordStrength.rawValue ? passwordStrength.color : Color.gray.opacity(0.3))
                                                        .frame(height: 5)
                                                        .cornerRadius(2.5)
                                                }
                                            }
                                            .frame(height: 5)
                                        }
                                        .frame(height: 5)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                }
                                
                                // Password tooltip
                                if showPasswordTooltip {
                                    TooltipView(text: "Create a strong password: at least 8 characters with uppercase, lowercase, and numbers or symbols")
                                }
                            }
                            
                            if authState == .signIn {
                                // Forgot password button (only for sign in)
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        forgotPassword()
                                    }) {
                                        Text("Forgot Password?")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.maakoshDeepPink)
                                    }
                                }
                                .padding(.top, -15)
                            }
                            
                            // Terms and conditions checkbox (only for sign up)
                            if authState == .signUp {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack(alignment: .center, spacing: 8) {
                                        // Custom checkbox
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                termsAccepted.toggle()
                                            }
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(termsAccepted ? Color.maakoshDeepPink : Color.gray, lineWidth: 1.5)
                                                    .frame(width: 22, height: 22)
                                                    .background(
                                                        termsAccepted ? 
                                                            RoundedRectangle(cornerRadius: 5)
                                                                .fill(Color.maakoshDeepPink.opacity(0.1)) : nil
                                                    )
                                                
                                                if termsAccepted {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(Color.maakoshDeepPink)
                                                }
                                            }
                                        }
                                        
                                        // Terms text with links
                                        Text("I agree to the ")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.black.opacity(0.7)) +
                                        Text("Terms & Conditions")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color.maakoshDeepPink) +
                                        Text(" and ")
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.black.opacity(0.7)) +
                                        Text("Privacy Policy")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color.maakoshDeepPink)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            termsAccepted.toggle()
                                        }
                                    }
                                    
                                    HStack {
                                        Button(action: { showTermsSheet = true }) {
                                            Text("Read Terms & Conditions")
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.maakoshDeepPink)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { showPrivacySheet = true }) {
                                            Text("Read Privacy Policy")
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.maakoshDeepPink)
                                        }
                                    }
                                    .padding(.horizontal, 5)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.5))
                                )
                            } else {
                                // Terms links for sign in (more subtle)
                                HStack {
                                    Spacer()
                                    Button(action: { showTermsSheet = true }) {
                                        Text("Terms")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.black.opacity(0.6))
                                    }
                                    Text("•")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.black.opacity(0.6))
                                    Button(action: { showPrivacySheet = true }) {
                                        Text("Privacy")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.black.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(.top, 5)
                            }
                            
                            // Main action button (Sign In/Sign Up)
                            Button(action: {
                                if isFormValid {
                                    if authState == .signIn {
                                        signIn()
                                    } else {
                                        signUp()
                                    }
                                }
                            }) {
                                ZStack {
                                    Text(authState == .signIn ? "Sign In" : "Sign Up")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(isFormValid ? Color.maakoshDeepPink : Color.gray.opacity(0.5))
                                        .cornerRadius(15)
                                        .shadow(color: isFormValid ? Color.maakoshDeepPink.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.3)
                                    }
                                }
                            }
                            .disabled(!isFormValid || isLoading)
                            .padding(.top, 10)
                            
                            // Toggle between sign in and sign up
                            HStack {
                                Text(authState == .signIn ? "Don't have an account?" : "Already have an account?")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.black.opacity(0.6))
                                
                                Button(action: {
                                    withAnimation {
                                        // Reset validation states
                                        showEmailTooltip = false
                                        showPasswordTooltip = false
                                        showNameTooltip = false
                                        termsAccepted = false
                                        
                                        authState = authState == .signIn ? .signUp : .signIn
                                    }
                                }) {
                                    Text(authState == .signIn ? "Sign Up" : "Sign In")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.maakoshDeepPink)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showTermsSheet) {
                TermsView()
            }
            .sheet(isPresented: $showPrivacySheet) {
                PrivacyView()
            }
        }
    }
    
    // MARK: - Firebase Authentication Methods
    
    private func signIn() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                alertMessage = handleAuthError(error)
                showAlert = true
            } else {
                // Successfully signed in
                isAuthenticated = true
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                isLoading = false
                alertMessage = handleAuthError(error)
                showAlert = true
            } else if let user = authResult?.user {
                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error updating user profile: \(error.localizedDescription)")
                    }
                }
                
                // Create user document in Firestore
                createUserDocument(user: user)
            }
        }
    }
    
    private func createUserDocument(user: User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "userId": user.uid
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Account created but failed to save profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Successfully created user document
                isAuthenticated = true
            }
        }
    }
    
    private func forgotPassword() {
        if isEmailValid {
            isLoading = true
            
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = handleAuthError(error)
                    showAlert = true
                } else {
                    alertMessage = "Password reset email sent! Check your inbox."
                    showAlert = true
                }
            }
        } else {
            alertMessage = "Please enter a valid email address to reset password"
            showAlert = true
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        
        switch errorCode {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "The email address is badly formatted."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account exists with this email. Please sign up."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Please sign in."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Please choose a stronger password."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many unsuccessful attempts. Please try again later."
        default:
            return "Authentication error: \(error.localizedDescription)"
        }
    }
}

// Terms and Conditions View
struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms and Conditions")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.maakoshDeepPink)
                        
                        Text("Last Updated: April 11, 2025")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.6))
                        
                        Text("Welcome to MaaKosh")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("These terms and conditions outline the rules and regulations for the use of MaaKosh App. By accessing this app we assume you accept these terms and conditions. Do not continue to use MaaKosh if you do not agree to take all of the terms and conditions stated on this page.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("1. User Data")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("MaaKosh collects and stores personal health information to provide you with pregnancy and maternal health tracking services. This information is protected and encrypted. You retain ownership of your personal data and may request export or deletion at any time.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                    
                    Group {
                        Text("2. Health Information")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("The health guidance provided through MaaKosh is for informational purposes only and is not a substitute for professional medical advice. Always consult with healthcare professionals for medical decisions.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("3. Account Security")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Privacy Policy View
struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.maakoshDeepPink)
                        
                        Text("Last Updated: April 11, 2025")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.6))
                        
                        Text("Your Privacy Matters")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("MaaKosh is committed to protecting your personal and health information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our maternal health tracking application.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("1. Information We Collect")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("We collect information you provide directly, including personal details, health data, pregnancy information, and account credentials. This data is necessary to provide you with personalized maternal health tracking and guidance.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                    
                    Group {
                        Text("2. How We Use Your Information")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("Your information is used to provide personalized health tracking, send relevant notifications, improve our services, and ensure the security of your account. We do not sell your personal data to third parties.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("3. Data Security")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("We implement industry-standard security measures to protect your data from unauthorized access or disclosure. Your health information is encrypted both in transit and at rest.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Tooltip View
struct TooltipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(10)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .transition(.opacity)
            .animation(.easeInOut, value: text)
    }
}

// Custom text field with icon and validation
struct AuthTextField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    @Binding var isValid: Bool
    @Binding var isFocused: Bool
    var keyboardType: UIKeyboardType = .default
    var validator: ((String) -> Bool)? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .foregroundColor(Color.maakoshDeepPink)
                .frame(width: 20)
            
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                isFocused = editing
                if !editing && validator != nil {
                    isValid = validator!(text)
                }
            })
            .font(.system(size: 16, design: .rounded))
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: text) { newValue in
                if let validate = validator {
                    isValid = validate(newValue)
                }
            }
            
            // Validation indicator
            if !text.isEmpty {
                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isValid ? .green : .red)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: isValid)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(text.isEmpty ? Color.maakoshMediumPink.opacity(0.2) : (isValid ? Color.green.opacity(0.5) : Color.red.opacity(0.5)), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

// Custom secure field with icon
struct AuthSecureField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .foregroundColor(Color.maakoshDeepPink)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.maakoshMediumPink.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .onTapGesture {
            isFocused = true
        }
    }
}

#Preview {
    AuthView()
} 
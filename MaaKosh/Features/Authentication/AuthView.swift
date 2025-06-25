//
//  AuthView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Security
import AuthenticationServices
import CryptoKit

// Typography constants for consistent styling
struct AppFont {
    // Font methods with system fallbacks
    static func titleLarge() -> Font {
        return Font.system(size: 32, weight: .bold, design: .rounded)
    }
    
    static func titleMedium() -> Font {
        return Font.system(size: 24, weight: .bold, design: .rounded)
    }
    
    static func titleSmall() -> Font {
        return Font.system(size: 20, weight: .semibold, design: .rounded)
    }
    
    static func body() -> Font {
        return Font.system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func caption() -> Font {
        return Font.system(size: 14, weight: .regular, design: .rounded)
    }
    
    static func small() -> Font {
        return Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    static func buttonText() -> Font {
        return Font.system(size: 18, weight: .semibold, design: .rounded)
    }
}

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                }
            }
    }
}

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
    @State private var showPassword = false
    @State private var isNewUser = false
    @State private var rememberMe = false
    
    // Validation states
    @State private var isEmailValid = false
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var showPasswordStrength = false
    
    // Tooltip states
    @State private var showEmailTooltip = false
    @State private var showPasswordTooltip = false
    @State private var showNameTooltip = false
    @State private var hasAppeared = false // Added for entrance animations
    @State private var showForgotPasswordSheet = false // Added for forgot password sheet
    
    // Apple Sign In states
    @State private var currentNonce: String?
    
    // Password visibility states
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
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
            if isNewUser {
                ProfileSetupView()
            } else {
                DashboardView()
            }
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 15) {
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
                                .font(AppFont.titleLarge())
                                .foregroundColor(Color.maakoshDeepPink)
                                .kerning(1.2)
                            
                            Text(authState == .signIn ? "Welcome Back" : "Create Account")
                                .font(AppFont.titleSmall())
                                .foregroundColor(Color.black.opacity(0.7))
                                .kerning(0.5)
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: hasAppeared)
                        
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
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: hasAppeared)
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
                                    showEmailTooltip = authState == .signUp && isEmailFocused && !isEmailValid && email.count > 0
                                }
                                .onTapGesture {
                                    showEmailTooltip = authState == .signUp && !isEmailValid && email.count > 0
                                }
                                
                                // Email tooltip
                                if showEmailTooltip {
                                    TooltipView(text: "Enter a valid email address (e.g., name@example.com)")
                                }
                            }
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(authState == .signUp ? 0.35 : 0.25), value: hasAppeared)
                            
                            // Password field with strength meter
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 15) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color.maakoshDeepPink)
                                        .frame(width: 20)
                                    
                                    Group {
                                        if showPassword {
                                            TextField(
                                                "Password",
                                                text: $password
                                            )
                                            .font(AppFont.body())
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                        } else {
                                            SecureField(
                                                "Password",
                                                text: $password
                                            )
                                            .font(AppFont.body())
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                        }
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showPassword.toggle()
                                        }
                                    }) {
                                        Image(showPassword ? "eye-solid" : "eye-closed")
                                            .renderingMode(.template)
                                            .foregroundColor(Color.maakoshDeepPink.opacity(0.7))
                                            .frame(width: 20, height: 20)
                                            .scaleEffect(showPassword ? 1.1 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: showPassword)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.maakoshMediumPink.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                .onChange(of: password) { _ in
                                    showPasswordStrength = authState == .signUp && password.count > 0
                                    showPasswordTooltip = authState == .signUp && isPasswordFocused && password.count > 0 && passwordStrength == .weak
                                }
                                .onTapGesture {
                                    isPasswordFocused = true
                                    showPasswordTooltip = authState == .signUp && password.count > 0 && passwordStrength == .weak
                                }
                                
                                // Password strength meter (only if password has content and in signup mode)
                                if showPasswordStrength && authState == .signUp {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Password Strength: \(passwordStrength.description)")
                                            .font(AppFont.small())
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
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(authState == .signUp ? 0.45 : 0.35), value: hasAppeared)
                            
                            if authState == .signIn {
                                // Forgot password button (only for sign in)
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showForgotPasswordSheet = true
                                    }) {
                                        Text("Forgot Password?")
                                            .font(AppFont.caption())
                                            .foregroundColor(Color.maakoshDeepPink)
                                    }
                                }
                                .padding(.top, -15)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: hasAppeared)
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
                                            .font(AppFont.caption())
                                            .foregroundColor(Color.black.opacity(0.7)) +
                                        Text("Terms & Conditions")
                                            .font(AppFont.caption())
                                            .foregroundColor(Color.maakoshDeepPink) +
                                        Text(" and ")
                                            .font(AppFont.caption())
                                            .foregroundColor(Color.black.opacity(0.7)) +
                                        Text("Privacy Policy")
                                            .font(AppFont.caption())
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
                                                .font(AppFont.small())
                                                .foregroundColor(Color.maakoshDeepPink)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { showPrivacySheet = true }) {
                                            Text("Read Privacy Policy")
                                                .font(AppFont.small())
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
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.55), value: hasAppeared)
                            } else {
                                // Terms links for sign in (more subtle) - REMOVING THIS SECTION
                                // This section has been removed to show terms only on sign-up
                            }
                            
                            // Remember Me option (only for sign in)
                            if authState == .signIn {
                                HStack {
                                    Button(action: {
                                        rememberMe.toggle()
                                    }) {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.maakoshDeepPink, lineWidth: 1.5)
                                                    .frame(width: 18, height: 18)
                                                
                                                if rememberMe {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.maakoshDeepPink)
                                                        .frame(width: 12, height: 12)
                                                }
                                            }
                                            
                                            Text("Remember me")
                                                .font(AppFont.caption())
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Keep the "Forgot Password?" link if it exists
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.40), value: hasAppeared)
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
                                        .font(AppFont.buttonText())
                                        .foregroundColor(.white)
                                        .opacity(isLoading ? 0 : 1) // Fade out text when loading
                                        .scaleEffect(isLoading ? 0.8 : 1) // Optionally scale down text

                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.3)
                                            .opacity(isLoading ? 1 : 0) // Fade in ProgressView
                                            .scaleEffect(isLoading ? 1 : 0.8) // Optionally scale up ProgressView
                                    }
                                }
                                .animation(.easeInOut(duration: 0.2), value: isLoading) // Animate these changes
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    ZStack { // Use ZStack to layer disabled and enabled states if needed, or just for gradient
                                        if isFormValid {
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.maakoshDeepPink.opacity(0.9), Color.maakoshMediumPink]), // Adjust colors for desired gradient
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        } else {
                                            Color.gray.opacity(0.5)
                                        }
                                    }
                                )
                                .cornerRadius(15)
                                .shadow(color: isFormValid ? Color.maakoshDeepPink.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(ActionButtonStyle())
                            .disabled(!isFormValid || isLoading)
                            .padding(.top, 10)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(authState == .signUp ? 0.65 : 0.55), value: hasAppeared)
                            
                            // Apple Sign In Section
                            VStack(spacing: 15) {
                                // Divider with "OR"
                                HStack {
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text("OR")
                                        .font(AppFont.caption())
                                        .foregroundColor(Color.gray)
                                        .padding(.horizontal, 10)
                                    
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Color.gray.opacity(0.3))
                                }
                                .padding(.horizontal, 10)
                                
                                // Apple Sign In Button
                                Button(action: {
                                    signInWithApple()
                                }) {
                                    HStack {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text("Continue with Apple")
                                            .font(AppFont.buttonText())
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.black)
                                    .cornerRadius(15)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                }
                                .buttonStyle(ActionButtonStyle())
                                .disabled(isLoading)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(authState == .signUp ? 0.75 : 0.65), value: hasAppeared)
                            }
                            .padding(.top, 15)
                            
                            // Toggle between sign in and sign up
                            HStack {
                                Text(authState == .signIn ? "Don't have an account?" : "Already have an account?")
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.black.opacity(0.6))
                                
                                Button(action: {
                                    withAnimation {
                                        // Reset validation states
                                        showEmailTooltip = false
                                        showPasswordTooltip = false
                                        showNameTooltip = false
                                        termsAccepted = false
                                        showPassword = false
                                        
                                        authState = authState == .signIn ? .signUp : .signIn
                                    }
                                }) {
                                    Text(authState == .signIn ? "Sign Up" : "Sign In")
                                        .font(AppFont.caption())
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.maakoshDeepPink)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(authState == .signUp ? 0.75 : 0.65), value: hasAppeared)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                .onAppear {
                    // Initial state for elements to be animated
                    self.hasAppeared = false
                    // Trigger animation after a very short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Use a single withAnimation block for the state change that triggers all animations
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            self.hasAppeared = true
                        }
                    }
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
            .sheet(isPresented: $showForgotPasswordSheet) {
                ForgotPasswordView()
            }
            .onAppear {
                loadSavedCredentials()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidSignOut"))) { _ in
                // Handle sign-out: reset state to show login form
                self.isAuthenticated = false
                self.isNewUser = false // Reset this flag too

                // Clear form fields
                self.email = ""
                self.password = ""
                self.fullName = ""

                // Reset validation and UI states
                self.isEmailValid = false
                self.isEmailFocused = false
                self.isPasswordFocused = false
                self.showPasswordStrength = false
                self.showEmailTooltip = false
                self.showPasswordTooltip = false
                self.showNameTooltip = false
                self.termsAccepted = false
                self.showPassword = false

                // Clear "Remember Me" state and saved credentials
                self.rememberMe = false
                self.clearSavedCredentials() // Call the existing method to clear from UserDefaults/Keychain

                // Reset authState to default if needed, e.g., to .signIn
                self.authState = .signIn
            }
        }
    }
    
    // MARK: - Apple Sign In Methods
    
    private func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = AppleSignInCoordinator.shared
        authorizationController.presentationContextProvider = AppleSignInCoordinator.shared
        
        // Set up the coordinator with our completion handler
        AppleSignInCoordinator.shared.configure(
            currentNonce: nonce,
            onSuccess: { credential in
                self.handleAppleSignInSuccess(credential: credential)
            },
            onFailure: { error in
                self.handleAppleSignInFailure(error: error)
            }
        )
        
        authorizationController.performRequests()
    }
    
    private func handleAppleSignInSuccess(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            alertMessage = "Invalid state: A login callback was received, but no login request was sent."
            showAlert = true
            return
        }
        
        guard let appleIDToken = credential.identityToken else {
            alertMessage = "Unable to fetch identity token"
            showAlert = true
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            alertMessage = "Unable to serialize token string from data"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create Firebase credential
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
        
        // Sign in with Firebase
        Auth.auth().signIn(with: firebaseCredential) { result, error in
            if let error = error {
                isLoading = false
                alertMessage = handleAuthError(error)
                showAlert = true
                return
            }
            
            guard let user = result?.user else {
                isLoading = false
                alertMessage = "Failed to get user information"
                showAlert = true
                return
            }
            
            // Check if this is a new user and handle profile creation
            handleAppleUserProfile(user: user, credential: credential)
        }
    }
    
    private func handleAppleSignInFailure(error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                // User canceled, don't show error
                return
            case .failed:
                alertMessage = "Apple Sign In failed. Please try again."
            case .invalidResponse:
                alertMessage = "Invalid response from Apple. Please try again."
            case .notHandled:
                alertMessage = "Apple Sign In not handled. Please try again."
            case .unknown:
                alertMessage = "Unknown Apple Sign In error. Please try again."
            @unknown default:
                alertMessage = "Apple Sign In error. Please try again."
            }
        } else {
            alertMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
        showAlert = true
    }
    
    private func handleAppleUserProfile(user: User, credential: ASAuthorizationAppleIDCredential) {
        let db = Firestore.firestore()
        
        // Check if user profile exists
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let document = document, document.exists {
                // Existing user - go to dashboard
                isAuthenticated = true
                isNewUser = false
            } else {
                // New user - create profile and go to setup
                var newProfile = UserProfile()
                
                // Get name from Apple ID if available
                var displayName = ""
                if let fullName = credential.fullName {
                    let firstName = fullName.givenName ?? ""
                    let lastName = fullName.familyName ?? ""
                    displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    newProfile.fullName = displayName
                }
                
                // If no name from Apple, try to get from Firebase user
                if displayName.isEmpty {
                    displayName = user.displayName ?? ""
                    newProfile.fullName = displayName
                }
                
                // Create initial profile document for Apple Sign In user
                let db = Firestore.firestore()
                let initialData: [String: Any] = [
                    "fullName": displayName.isEmpty ? "Apple User" : displayName,
                    "email": user.email ?? "",
                    "age": 0, // Will be set in profile setup
                    "phoneNumber": "",
                    "partnerName": "",
                    "lastPeriodDate": Date(),
                    "cycleLengthInDays": 28,
                    "isProfileComplete": false,
                    "authProvider": "apple",
                    "appleUserID": credential.user,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                db.collection("users").document(user.uid).setData(initialData) { error in
                    if let error = error {
                        alertMessage = "Failed to create profile: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        isAuthenticated = true
                        isNewUser = true
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign In Helper Functions
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Firebase Authentication Methods
    
    private func signIn() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            
            if let error = error {
                alertMessage = handleAuthError(error)
                showAlert = true
                return
            }
            
            // If remember me is checked, save credentials
            if rememberMe {
                saveCredentials()
            } else {
                // Clear any previously saved credentials
                clearSavedCredentials()
            }
            
            // Determine if this is a new user
            if let user = Auth.auth().currentUser {
                checkUserProfile(userId: user.uid)
            } else {
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
            "authProvider": "email",
            "age": 0,
            "phoneNumber": "",
            "partnerName": "",
            "lastPeriodDate": Date(),
            "cycleLengthInDays": 28,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "userId": user.uid,
            "isProfileComplete": false
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Account created but failed to save profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Set as new user to trigger profile setup
                isNewUser = true
                isAuthenticated = true
            }
        }
    }
    
    private func checkUserProfile(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                alertMessage = "Error checking profile: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            if let document = document, document.exists {
                // Check if profile is complete
                if let isProfileComplete = document.data()?["isProfileComplete"] as? Bool, isProfileComplete {
                    // User has completed profile setup
                    isNewUser = false
                } else {
                    // User needs to complete profile setup
                    isNewUser = true
                }
            } else {
                // No user document, create one and mark as new user
                let userData: [String: Any] = [
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp(),
                    "userId": userId,
                    "isProfileComplete": false
                ]
                
                db.collection("users").document(userId).setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    }
                }
                
                isNewUser = true
            }
            
            // Set authenticated state after profile check
            isAuthenticated = true
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
    
    // Add these new helper functions for credential management
    
    private func saveCredentials() {
        // Save email to UserDefaults
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(true, forKey: "rememberMe")
        
        // Save password to Keychain
        let passwordData = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MaaKoshUserPassword",
            kSecValueData as String: passwordData
        ]
        
        // First delete any existing password
        SecItemDelete(query as CFDictionary)
        
        // Then add the new password
        let status = SecItemAdd(query as CFDictionary, nil)
        print("Password saved with status: \(status)")
    }
    
    private func loadSavedCredentials() {
        // Only load if remember me was enabled
        guard UserDefaults.standard.bool(forKey: "rememberMe") else { return }
        
        // Load email from UserDefaults
        if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
            email = savedEmail
            
            // Update email validation state
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            isEmailValid = emailPredicate.evaluate(with: email) && email.count > 5
        }
        
        // Load password from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MaaKoshUserPassword",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let passwordData = result as? Data, 
           let savedPassword = String(data: passwordData, encoding: .utf8) {
            password = savedPassword
        }
        
        // Set remember me state
        rememberMe = true
    }
    
    private func clearSavedCredentials() {
        // Remove email from UserDefaults
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        UserDefaults.standard.set(false, forKey: "rememberMe")
        
        // Remove password from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MaaKoshUserPassword"
        ]
        
        SecItemDelete(query as CFDictionary)
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
                            .font(AppFont.titleMedium())
                            .foregroundColor(Color.maakoshDeepPink)
                        
                        Text("Last Updated: April 11, 2025")
                            .font(AppFont.caption())
                            .foregroundColor(Color.black.opacity(0.6))
                        
                        Text("Welcome to MaaKosh")
                            .font(AppFont.titleSmall())
                        
                        Text("These terms and conditions outline the rules and regulations for the use of MaaKosh App. By accessing this app we assume you accept these terms and conditions. Do not continue to use MaaKosh if you do not agree to take all of the terms and conditions stated on this page.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("1. User Data")
                            .font(AppFont.titleSmall())
                        
                        Text("MaaKosh collects and stores personal health information to provide you with pregnancy and maternal health tracking services. This information is protected and encrypted. You retain ownership of your personal data and may request export or deletion at any time.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                    
                    Group {
                        Text("2. Health Information")
                            .font(AppFont.titleSmall())
                        
                        Text("The health guidance provided through MaaKosh is for informational purposes only and is not a substitute for professional medical advice. Always consult with healthcare professionals for medical decisions.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("3. Account Security")
                            .font(AppFont.titleSmall())
                        
                        Text("You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")
                            .font(AppFont.body())
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
                            .font(AppFont.titleMedium())
                            .foregroundColor(Color.maakoshDeepPink)
                        
                        Text("Last Updated: April 11, 2025")
                            .font(AppFont.caption())
                            .foregroundColor(Color.black.opacity(0.6))
                        
                        Text("Your Privacy Matters")
                            .font(AppFont.titleSmall())
                        
                        Text("MaaKosh is committed to protecting your personal and health information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our maternal health tracking application.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("1. Information We Collect")
                            .font(AppFont.titleSmall())
                        
                        Text("We collect information you provide directly, including personal details, health data, pregnancy information, and account credentials. This data is necessary to provide you with personalized maternal health tracking and guidance.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                    
                    Group {
                        Text("2. How We Use Your Information")
                            .font(AppFont.titleSmall())
                        
                        Text("Your information is used to provide personalized health tracking, send relevant notifications, improve our services, and ensure the security of your account. We do not sell your personal data to third parties.")
                            .font(AppFont.body())
                            .foregroundColor(Color.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        Text("3. Data Security")
                            .font(AppFont.titleSmall())
                        
                        Text("We implement industry-standard security measures to protect your data from unauthorized access or disclosure. Your health information is encrypted both in transit and at rest.")
                            .font(AppFont.body())
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
            .font(AppFont.small())
            .foregroundColor(Color.maakoshDeepPink) // Use app's deep pink for text
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)) // Adjusted padding
            .background(
                Capsule() // Use Capsule shape for a softer, more playful look
                    .fill(Color.maakoshLightPink.opacity(0.95)) // Use a light app color, slightly opaque
                    .shadow(color: Color.maakoshMediumPink.opacity(0.4), radius: 3, x: 0, y: 2) // Softer shadow
            )
            .transition(.opacity.combined(with: .scale(scale: 0.85))) // Animate appearance/disappearance
            // The .animation on 'text' change was removed before, which is correct.
            // The transition will be animated by the parent view that controls the tooltip's visibility.
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
            .font(AppFont.body())
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
                .font(AppFont.body())
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

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEmailValid = false
    @State private var isEmailFocused = false
    @State private var hasAppeared = false
    @State private var isSuccess = false
    
    private var isFormValid: Bool {
        isEmailValid && !email.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching the main auth view
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 40)
                        
                        // Header section
                        VStack(spacing: 20) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.maakoshDeepPink.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: isSuccess ? "checkmark.circle.fill" : "key.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(isSuccess ? .green : Color.maakoshDeepPink)
                                    .scaleEffect(hasAppeared ? 1 : 0.5)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: hasAppeared)
                            }
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : -20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: hasAppeared)
                            
                            // Title and description
                            VStack(spacing: 12) {
                                Text(isSuccess ? "Check Your Email" : "Reset Password")
                                    .font(AppFont.titleMedium())
                                    .foregroundColor(Color.maakoshDeepPink)
                                    .multilineTextAlignment(.center)
                                
                                Text(isSuccess ? 
                                     "We've sent a password reset link to your email address. Please check your inbox and follow the instructions." :
                                     "Enter your email address and we'll send you a link to reset your password.")
                                    .font(AppFont.body())
                                    .foregroundColor(.black.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                        }
                        .padding(.horizontal, 30)
                        
                        if !isSuccess {
                            // Email input section
                            VStack(spacing: 20) {
                                // Email field
                                VStack(alignment: .leading, spacing: 8) {
                                    AuthTextField(
                                        iconName: "envelope.fill",
                                        placeholder: "Email Address",
                                        text: $email,
                                        isValid: $isEmailValid,
                                        isFocused: $isEmailFocused
                                    )
                                    .onChange(of: email) { newValue in
                                        validateEmail(newValue)
                                    }
                                    
                                    // Email validation indicator
                                    if !email.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(systemName: isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(isEmailValid ? .green : .red)
                                            
                                            Text(isEmailValid ? "Valid email address" : "Please enter a valid email")
                                                .font(AppFont.caption())
                                                .foregroundColor(isEmailValid ? .green : .red)
                                        }
                                        .padding(.leading, 45)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                                
                                // Send reset button
                                Button(action: {
                                    sendPasswordReset()
                                }) {
                                    ZStack {
                                        Text("Send Reset Link")
                                            .font(AppFont.buttonText())
                                            .foregroundColor(.white)
                                            .opacity(isLoading ? 0 : 1)
                                            .scaleEffect(isLoading ? 0.8 : 1)
                                        
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.2)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: isFormValid ? 
                                                [Color.maakoshDeepPink.opacity(0.9), Color.maakoshMediumPink] :
                                                [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
                                            ),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: isFormValid ? Color.maakoshDeepPink.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                                }
                                .buttonStyle(ActionButtonStyle())
                                .disabled(!isFormValid || isLoading)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: hasAppeared)
                            }
                            .padding(.horizontal, 30)
                        } else {
                            // Success state buttons
                            VStack(spacing: 15) {
                                // Open email app button
                                Button(action: {
                                    openEmailApp()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.open.fill")
                                            .font(.system(size: 18))
                                        Text("Open Email App")
                                            .font(AppFont.buttonText())
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.maakoshDeepPink.opacity(0.9), Color.maakoshMediumPink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .buttonStyle(ActionButtonStyle())
                                
                                // Resend button
                                Button(action: {
                                    withAnimation {
                                        isSuccess = false
                                    }
                                }) {
                                    Text("Resend Email")
                                        .font(AppFont.body())
                                        .foregroundColor(Color.maakoshDeepPink)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 30)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(AppFont.body())
                        }
                        .foregroundColor(Color.maakoshDeepPink)
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Trigger entrance animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func validateEmail(_ email: String) {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isEmailValid = emailPredicate.evaluate(with: email) && email.count > 5
        }
    }
    
    private func sendPasswordReset() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = handleAuthError(error)
                    showAlert = true
                } else {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isSuccess = true
                    }
                    
                    // Add haptic feedback for success
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func openEmailApp() {
        if let url = URL(string: "mailto:") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        
        switch errorCode {
        case AuthErrorCode.invalidEmail.rawValue:
            return "The email address is not valid."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email address."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many requests. Please try again later."
        default:
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AuthView()
} 
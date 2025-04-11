//
//  AuthView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI

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
        isEmailValid && !password.isEmpty && (authState == .signIn || !fullName.isEmpty)
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
                                    // Forgot password action
                                }) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.maakoshDeepPink)
                                }
                            }
                            .padding(.top, -15)
                        }
                        
                        // Main action button (Sign In/Sign Up)
                        Button(action: {
                            // Will implement Firebase auth later
                            // For now, simulate successful auth
                            isAuthenticated = true
                        }) {
                            Text(authState == .signIn ? "Sign In" : "Sign Up")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(isFormValid ? Color.maakoshDeepPink : Color.gray.opacity(0.5))
                                .cornerRadius(15)
                                .shadow(color: isFormValid ? Color.maakoshDeepPink.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                        }
                        .disabled(!isFormValid)
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
                    
                    Spacer()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
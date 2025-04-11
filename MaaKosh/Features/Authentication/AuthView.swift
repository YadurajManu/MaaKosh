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

struct AuthView: View {
    @State private var authState: AuthViewState = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isAuthenticated = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                            AuthTextField(
                                iconName: "person.fill",
                                placeholder: "Full Name",
                                text: $fullName
                            )
                        }
                        
                        // Email field
                        AuthTextField(
                            iconName: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // Password field
                        AuthSecureField(
                            iconName: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                        
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
                                .background(Color.maakoshDeepPink)
                                .cornerRadius(15)
                                .shadow(color: Color.maakoshDeepPink.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 10)
                        
                        // Toggle between sign in and sign up
                        HStack {
                            Text(authState == .signIn ? "Don't have an account?" : "Already have an account?")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.6))
                            
                            Button(action: {
                                withAnimation {
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

// Custom text field with icon
struct AuthTextField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .foregroundColor(Color.maakoshDeepPink)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .keyboardType(keyboardType)
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
    }
}

// Custom secure field with icon
struct AuthSecureField: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    
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
    }
}

#Preview {
    AuthView()
} 
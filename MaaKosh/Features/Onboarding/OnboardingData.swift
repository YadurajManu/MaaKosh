//
//  OnboardingData.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseFirestore

// User profile model to store information after signup
struct UserProfile: Codable {
    var fullName: String = "" // Added
    var email: String = ""
    var age: Int = 0
    var phoneNumber: String = ""
    var partnerName: String = ""
    var lastPeriodDate: Date = Date()
    var cycleLengthInDays: Int = 28
    var isProfileComplete: Bool = false
    var authProvider: String = "email" // "email", "apple", etc.
    
    // Calculate estimated due date (EDD) - approximately 280 days from last period
    var estimatedDueDate: Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lastPeriodDate) ?? Date()
    }
    
    // Calculate current pregnancy week based on last period date
    var currentPregnancyWeek: Int {
        let days = Calendar.current.dateComponents([.day], from: lastPeriodDate, to: Date()).day ?? 0
        return days / 7
    }
    
    // Save user profile to Firestore
    func saveToFirestore(userId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "fullName": fullName, // Added
            "email": email,
            "age": age,
            "phoneNumber": phoneNumber,
            "partnerName": partnerName,
            "lastPeriodDate": lastPeriodDate,
            "cycleLengthInDays": cycleLengthInDays,
            "isProfileComplete": true,
            "authProvider": authProvider,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Use setData instead of updateData to create or update the document
        db.collection("users").document(userId).setData(userData, merge: true, completion: completion)
    }
}

// Extension to create Color from hex
extension Color {
    static let maakoshLightPink = Color(hex: "FFEDFA")
    static let maakoshMediumLightPink = Color(hex: "FFB8E0")
    static let maakoshMediumPink = Color(hex: "EC7FA9")
    static let maakoshDeepPink = Color(hex: "BE5985")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let accentColor: Color
    let mainIcon: String
    let smallIcons: [String]
}

struct OnboardingData {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "maakosh.welcome",
            title: "Welcome to MaaKosh",
            description: "Your comprehensive maternal and neonatal care companion from conception to newborn care.",
            accentColor: Color.maakoshDeepPink,
            mainIcon: "heart.circle.fill",
            smallIcons: ["heart.fill", "star.fill", "moon.fill"]
        ),
        OnboardingPage(
            image: "maakosh.pregnancy.planning",
            title: "Pre-Pregnancy Planning",
            description: "Track your menstrual cycle, predict fertility windows, and get personalized nutrition guidance.",
            accentColor: Color.maakoshDeepPink,
            mainIcon: "calendar.badge.clock",
            smallIcons: ["pill.fill", "leaf.fill", "moon.stars.fill"]
        ),
        OnboardingPage(
            image: "maakosh.pregnancy.monitoring",
            title: "Pregnancy Monitoring",
            description: "Real-time health tracking and risk prediction to ensure a safe and healthy pregnancy journey.",
            accentColor: Color.maakoshDeepPink,
            mainIcon: "waveform.path.ecg",
            smallIcons: ["heart.fill", "chart.line.uptrend.xyaxis", "stethoscope"]
        ),
        OnboardingPage(
            image: "maakosh.postnatal",
            title: "Post-Pregnancy Care",
            description: "Monitor your newborn's health and track your postnatal recovery with personalized guidance.",
            accentColor: Color.maakoshDeepPink,
            mainIcon: "person.2.fill",
            smallIcons: ["person.fill", "heart.fill", "bandage.fill"]
        )
    ]
}   
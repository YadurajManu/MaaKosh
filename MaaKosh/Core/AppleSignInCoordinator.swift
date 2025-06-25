//
//  AppleSignInCoordinator.swift
//  MaaKosh
//
//  Created by AI Assistant on 11/04/25.
//

import Foundation
import AuthenticationServices
import UIKit

class AppleSignInCoordinator: NSObject, ObservableObject {
    static let shared = AppleSignInCoordinator()
    
    private var currentNonce: String?
    private var onSuccess: ((ASAuthorizationAppleIDCredential) -> Void)?
    private var onFailure: ((Error) -> Void)?
    
    override init() {
        super.init()
    }
    
    func configure(
        currentNonce: String,
        onSuccess: @escaping (ASAuthorizationAppleIDCredential) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.currentNonce = currentNonce
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            onSuccess?(appleIDCredential)
        } else {
            onFailure?(AppleSignInError.invalidCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onFailure?(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Custom Error Types
enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingNonce
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received"
        case .missingNonce:
            return "Missing nonce for Apple Sign In"
        }
    }
} 
//
//  SigninManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit

class SigninManager {
    enum UserConfirmedStatus {
        case confirmed
        case unconfirmed
    }
    enum SignUpError: Error {
        case userAccountAlreadyExists
        case wrongEmailOrPassword
        case invalidPassword //For creating an account the password must be at least x digits long etc
        case noInternet
    }
    enum ConfirmSignupError : Error {
        case wrongCode
        case noInternet
    }
    enum ResendConfirmCodeError :Error {
        case noInternet
    }
    enum ForgotPassword:Error {
        case wrongEmail
        case noInternet
    }
    enum ConfirmForgotPasswordError:Error{
        case wrongCode
        case invalidPassword
        case noInternet
    }
    
    enum LoginResult {
        case success(isValidCredentials: Bool, isExistingUser: Bool)
        case failed(Error)
    }
    

    static let shared = SigninManager()

    var user: Any?
    
    init() {
        
        
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return false
    }
    
    
    func isExistingUser(email: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            fulfill(email == "a@a.aa")
        }
    }
    
    func login(email: String, password: String) -> Promise<LoginResult> {
        return Promise { fulfill, reject in
            let valid = password == "aaa"
            let existing = email == "a@a.aa"
            fulfill(LoginResult.success(isValidCredentials: valid, isExistingUser: existing))
        }
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        return Promise { fulfill, reject in
            fulfill(())
        }
    }
    
    func resendConfirmCode() -> Promise<Void>{
        return Promise { fulfill, reject in
            fulfill(())
        }
    }
    
    func forgotPassword(email:String) ->Promise<Void> {
        return Promise { fulfill, reject in
            fulfill(())
        }
    }
    
    func confirmForgotPassword(code:String, password:String) ->Promise<Void> {
        return Promise { fulfill, reject in
            fulfill(())
        }
    }
    
    
    
}

//
//  InviteViewController.swift
//  screenshot
//
//  Created by Corey Werner on 10/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import GoogleSignIn
import Firebase
//import FirebaseInvites

class InviteViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let extendedPadding = Geometry.extendedPadding()
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .gray8
        view.addSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalToConstant: 240).isActive = true
        separator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        NSLayoutConstraint(item: separator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.1, constant: 0).isActive = true
        
        let googleButton = MainButton()
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.backgroundColor = .white
        googleButton.setTitleColor(.black, for: .normal)
        googleButton.setTitle("Google Sign In", for: .normal)
        googleButton.addTarget(self, action: #selector(googleSignIn), for: .touchUpInside)
        view.addSubview(googleButton)
        googleButton.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -extendedPadding).isActive = true
        googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let noLoginButton = MainButton()
        noLoginButton.translatesAutoresizingMaskIntoConstraints = false
        noLoginButton.setTitle("Without Login", for: .normal)
        noLoginButton .addTarget(self, action: #selector(presentActivityViewController), for: .touchUpInside)
        view.addSubview(noLoginButton)
        noLoginButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: extendedPadding).isActive = true
        noLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func presentActivityViewController() {
        let text = "Download SCREENSHOP, the app that lets you shop any screenshot, for free! https://crazeapp.com/app/"
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: Google
    
    func googleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            GIDSignIn.sharedInstance().signInSilently()
            presentGoogleInvite()
            
        } else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func presentGoogleInvite() {
        if let invite = Invites.inviteDialog() {
            invite.setInviteDelegate(self)
            
            // NOTE: You must have the App Store ID set in your developer console project
            // in order for invitations to successfully be sent.
            
            // A message hint for the dialog. Note this manifests differently depending on the
            // received invitation type. For example, in an email invite this appears as the subject.
            invite.setMessage("Try this out!\n -\(GIDSignIn.sharedInstance().currentUser.profile.name)")
            // Title for the dialog, this is what the user sees before sending the invites.
            invite.setTitle("Invites Example")
            invite.setDeepLink("app_url")
            invite.setCallToActionText("Install!")
            invite.setCustomImage("https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
            invite.open()
        }
    }
}

extension InviteViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            print("||| google sign in error: \(error)")
            return
        }
        
        guard let authentication = user.authentication else {
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        print("||| google sign in credentials: \(credential)")
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("||| google sign in auth error: \(error)")
                return
            }
            
            // User is signed in
            // ...
            self.presentGoogleInvite()
            
            print("||| signed in, hurray!")
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}

extension InviteViewController: InviteDelegate {
    func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
        
    }
    
//    - (void)inviteFinishedWithInvitations:(NSArray<NSString *> *)invitationIds error:(NSError *)error {
//    if (error) {
//    NSLog(@"||| %@", error.localizedDescription);
//
//    } else {
//    NSLog(@"||| %li invites sent", invitationIds.count);
//    }
//    }
}

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

class InviteViewController: BaseViewController, GIDSignInUIDelegate {
    let shareText = "Download SCREENSHOP, the app that lets you shop any screenshot, for free!"
    
    fileprivate var googleButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let extendedPadding = Geometry.extendedPadding
        
        let helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.titleLabel.text = "Tell a Friend"
        helperView.backgroundColor = view.backgroundColor
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: extendedPadding).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .gray8
        helperView.contentView.addSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalToConstant: 240).isActive = true
        separator.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        NSLayoutConstraint(item: separator, attribute: .centerY, relatedBy: .equal, toItem: helperView.contentView, attribute: .centerY, multiplier: 0.9, constant: 0).isActive = true
        
        googleButton = MainButton()
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.backgroundColor = .white
        googleButton.setTitleColor(.black, for: .normal)
        googleButton.setTitle("Google Invite", for: .normal)
        googleButton.setImage(UIImage(named: "InviteGoogleIcon"), for: .normal)
        googleButton.addTarget(self, action: #selector(googleSignIn), for: .touchUpInside)
        helperView.contentView.addSubview(googleButton)
        googleButton.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -extendedPadding).isActive = true
        googleButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        
        let noLoginButton = MainButton()
        noLoginButton.translatesAutoresizingMaskIntoConstraints = false
        noLoginButton.setTitle("Share", for: .normal)
        noLoginButton .addTarget(self, action: #selector(presentActivityViewController), for: .touchUpInside)
        helperView.contentView.addSubview(noLoginButton)
        noLoginButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: extendedPadding).isActive = true
        noLoginButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
    }
    
    func presentActivityViewController() {
        let text = shareText + " https://crazeapp.com/app/"
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: Google
    
    func googleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        var isLoading = false
        
        if (GIDSignIn.sharedInstance().currentUser != nil) {
            presentGoogleInvite()
            
        } else if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            GIDSignIn.sharedInstance().signInSilently()
            isLoading = true
            
        } else {
            GIDSignIn.sharedInstance().signIn()
            isLoading = true
        }
        
        if isLoading {
            googleButton.activityIndicator?.color = .crazeRed
            googleButton.isLoading = true
        }
    }
    
    func presentGoogleInvite() {
        if let invite = Invites.inviteDialog() {
            invite.setInviteDelegate(self)
            
            // NOTE: You must have the App Store ID set in your developer console project
            // in order for invitations to successfully be sent.
            
            invite.setTitle("Invites Your Friends")
            invite.setMessage(shareText)
            invite.setDeepLink("io.crazeapp.screenshot.dev") // TODO:
            invite.setCallToActionText("Install!")
            invite.setCustomImage("https://static.crazeapp.com/screenshop-icon-500.png")
            invite.open()
        }
    }
}

extension InviteViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            googleButton.isLoading = false
            
            AnalyticsTrackers.standard.track("Google Sign In", properties: ["Error": error.localizedDescription])
            return
        }
        
        guard let authentication = user.authentication else {
            googleButton.isLoading = false
            
            AnalyticsTrackers.standard.track("Google Sign In", properties: ["Error": "No User Authentication"])
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            self.googleButton.isLoading = false
            
            var analyticsProperties = [String: Any]()
            
            if let displayName = user?.displayName {
                analyticsProperties["User Name"] = displayName
            }
            if let email = user?.email {
                analyticsProperties["User Email"] = email
            }
            
            if let error = error {
                analyticsProperties["Error"] = error.localizedDescription
                AnalyticsTrackers.standard.track("Google Sign In", properties: analyticsProperties)
                return
            }
            
            self.presentGoogleInvite()
            
            AnalyticsTrackers.standard.track("Google Sign In", properties: analyticsProperties)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // TODO: ???
    }
}

extension InviteViewController: InviteDelegate {
    func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
        if let error = error {
            AnalyticsTrackers.standard.track("Google Invite", properties: ["Error": error.localizedDescription])
            
        } else {
            AnalyticsTrackers.standard.track("Google Invite", properties: ["Sent": invitationIds.count])
        }
    }
}

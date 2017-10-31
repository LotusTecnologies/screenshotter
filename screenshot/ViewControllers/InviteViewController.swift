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
import FBSDKShareKit

class InviteViewController: BaseViewController, GIDSignInUIDelegate {
    let shareText = "Download SCREENSHOP, the app that lets you shop any screenshot, for free!"
    
    fileprivate let googleButton = MainButton()
    fileprivate let facebookButton = MainButton()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Tell a Friend"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let padding = Geometry.padding
        let extendedPadding = Geometry.extendedPadding
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.topAnchor.constraint(greaterThanOrEqualTo: topLayoutGuide.bottomAnchor, constant: extendedPadding).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
        containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -extendedPadding).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding).isActive = true
        NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.1, constant: 0).isActive = true
        
        facebookButton.translatesAutoresizingMaskIntoConstraints = false
        facebookButton.backgroundColor = UIColor(red: 60/255, green: 90/255, blue: 150/255, alpha: 1)
        facebookButton.setTitle("Facebook Invite", for: .normal)
        facebookButton.setImage(UIImage(named: "InviteFacebookIcon"), for: .normal)
        facebookButton.addTarget(self, action: #selector(presentFacebookInvite), for: .touchUpInside)
        containerView.addSubview(facebookButton)
        facebookButton.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        facebookButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        facebookButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.backgroundColor = .white
        googleButton.setTitleColor(.black, for: .normal)
        googleButton.setTitle("Google Invite", for: .normal)
        googleButton.setImage(UIImage(named: "InviteGoogleIcon"), for: .normal)
        googleButton.addTarget(self, action: #selector(googleSignIn), for: .touchUpInside)
        containerView.addSubview(googleButton)
        googleButton.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        googleButton.topAnchor.constraint(equalTo: facebookButton.bottomAnchor, constant: extendedPadding).isActive = true
        googleButton.widthAnchor.constraint(equalTo: facebookButton.widthAnchor).isActive = true
        googleButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .gray9
        containerView.addSubview(separator)
        separator.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: extendedPadding).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalToConstant: 260).isActive = true
        separator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let shareButton = MainButton()
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("Share To Other Apps", for: .normal)
        shareButton.setImage(UIImage(named: "InviteShare"), for: .normal)
        shareButton .addTarget(self, action: #selector(presentActivityViewController), for: .touchUpInside)
        containerView.addSubview(shareButton)
        shareButton.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        shareButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: extendedPadding).isActive = true
        shareButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        shareButton.widthAnchor.constraint(equalTo: googleButton.widthAnchor).isActive = true
        shareButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
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
        if let invite = Invites.inviteDialog(), let bundleIdentifier = Bundle.main.bundleIdentifier {
            invite.setInviteDelegate(self)
            invite.setTitle("Invites Your Friends")
            invite.setMessage(shareText)
            invite.setDeepLink(bundleIdentifier)
            invite.setCallToActionText("Install!")
            invite.setCustomImage("https://static.crazeapp.com/screenshop-icon-500.png")
            invite.open()
        }
    }
    
    // MARK: Facebook
    
    func presentFacebookInvite() {
        // https://developers.facebook.com/quickstarts/1960379067541863/?platform=app-links-host
        
        let content = FBSDKAppInviteContent()
        content.appLinkURL = URL(string: "https://fb.me/1992192421027194")
        content.appInvitePreviewImageURL = URL(string: "https://static.crazeapp.com/screenshop-logo-1200x628.png")
        
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
    }
    
    // MARK: Share
    
    func presentActivityViewController() {
        let text = shareText + " https://screenshopit.com/"
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
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
            
            if let name = user?.displayName {
                analyticsProperties["User Name"] = name
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
        AnalyticsTrackers.standard.track("Google Sign Out", properties: [
            "User Name": user.profile.name,
            "User Email": user.profile.email,
            "Error": error.localizedDescription
            ])
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

extension InviteViewController: FBSDKAppInviteDialogDelegate {
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
        AnalyticsTrackers.standard.track("Facebook Invite", properties: ["Sent": results])
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        AnalyticsTrackers.standard.track("Facebook Invite", properties: ["Error": error.localizedDescription])
    }
}

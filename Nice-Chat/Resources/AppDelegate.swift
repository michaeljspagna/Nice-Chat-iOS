//
//  AppDelegate.swift
//  Nice-Chat
//
//  Created by Michael Spagna on 1/15/21.
//

import UIKit
import Firebase
import GoogleSignIn
@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!,
              didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        guard error == nil else{
            if let error = error{
                print("Failed to Sign In with Google \(error)")
            }
            return
        }
        print("Did Sign In with google")
        guard let email = user.profile.email,
              let firstname = user.profile.givenName,
              let lastname = user.profile.familyName else{ return }
        UserDefaults.standard.setValue(email, forKey: "email")
        UserDefaults.standard.setValue("\(firstname) \(lastname)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email, completion: { exists in
            if !exists{
                let chatUser = ChatAppUser(firstName: firstname,
                                           lastName: lastname,
                                           emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                let filename = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePictuer(with: data, filename: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("Storage Manager Error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                        
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing auth obj off of google user")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else{
                print("Failed to log in with google creden")
                return
            }
        })
        print("Signed in with google")
        NotificationCenter.default.post(name: .didLogInNotification, object: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google User Was Disconnected")
    }
    
}


//
//  DatabaseManager.swift
//  Nice-Chat
//
//  Created by Michael Spagna on 1/17/21.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    let powerBounds = ["0000": [1,1], "0001": [0.99, 0.51], "0010": [0.5,0.5], "0011": [0.49, 0.02], "0100": [0.01, 0.01]]
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "--")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "--")
        return safeEmail
    }
    
}

// MARK: -  Account Management
extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping((Bool) -> Void)){
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    let newUser = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newUser)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }else{
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            
        })
    }
}

extension DatabaseManager {
    public func getDataForPath(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK: Sending messages / conversations
extension DatabaseManager {
    public enum DatabaseError: Error {
        case failedToFetch
    }
    ///Fetches and returns all chatrooms
    public func getAllConversations(completion: @escaping (Result<[Chatroom], Error>) -> Void) {
        database.child("chatrooms").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let chatrooms: [Chatroom] = value.compactMap({ dictionary in
                guard let id = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let message = dictionary["message"] as? String else{
                    completion(.failure(DatabaseError.failedToFetch))
                    return nil
                }
                let bound = self.powerBounds[id]
                let maxPower = Float(bound?[0] ?? 1.0)
                let minPower = Float(bound?[1] ?? 0.0)
                print(name, maxPower, minPower)
                return Chatroom(id: id,
                                name: name,
                                message: message,
                                maxPower: maxPower,
                                minPower: minPower)
            })
            completion(.success(chatrooms))
        })
        
    }
    

    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let id = dictionary["id"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["senderEmail"] as? String,
                      let type = dictionary["type"] as? String,
                      let content = dictionary["content"] as? String,
                      let date = ChatroomViewController.dateFormatter.date(from: dateString) else{
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: id,
                               sentDate: date,
                               kind: .text(content))
                
            })
            completion(.success(messages))
        })
        
    }
    

    public func sendMessageInChatroom(to chatroom: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        // add new message to messages
        self.database.child("\(chatroom)/messages").observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatroomViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myName = UserDefaults.standard.value(forKey: "name") as? String else{
                completion(false)
                return
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            
            let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry : [String: Any] = [
                "content": message,
                "date": dateString,
                "id": newMessage.messageId,
                "name": myName,
                "senderEmail": currentSafeEmail,
                "type": newMessage.kind.messageKindString
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(chatroom)/messages").setValue(currentMessages, withCompletionBlock: { error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                completion(true)
            })
        })
    }
    
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        return DatabaseManager.safeEmail(emailAddress: emailAddress)
    }
    var profilePictureFileName:String{
        return "\(safeEmail)_profile_picture.png"
    }
}

//
//  StorageManager.swift
//  Nice-Chat
//
//  Created by Michael Spagna on 2/1/21.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion w/ url
    public func uploadProfilePictuer(with data: Data, filename: String, completion: @escaping UploadPictureCompletion){
        storage.child("images/\(filename)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else{
                //fail
                print("Failed to upload pic to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(filename)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("failed to get dl url")
                    completion(.failure(StorageErrors.failedToGetDLURL))
                    return
                }
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDLURL
    }
    
    public func downloadURL(for path: String,  completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetDLURL))
                return
            }
            completion(.success(url))
        })
    }
}

//
//  FirebaseManager.swift
//  GraduationProject
//
//  Created by Kris on 5/17/23.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

final class FireBaseManager: ObservableObject
{
    let db = Firestore.firestore()
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    func createUser() {
        var ref: DocumentReference? = nil
        
        ref = db.collection("users").addDocument(data: [
            "first": "Ada",
            "last": "Lovelace",
            "born": 1815
        ]) { err in
            if let err = err {
                self.handleError(err.localizedDescription)
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    private func handleError(_ errorMessage: String) {
        self.errorMessage = errorMessage
        self.showError.toggle()
    }
}

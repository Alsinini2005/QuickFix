//
//  Classes.swift
//  QuickFix
//
//  Created by BP-36-201-07 on 01/12/2025.
//

class User {
    var userID : String
    var userName : String
    var email : String
    var phone : Int
    
    init(userID: String, userName: String, email: String, phone: Int) {
        self.userID = userID
        self.userName = userName
        self.email = email
        self.phone = phone
    }
}

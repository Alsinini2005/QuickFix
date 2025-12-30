//
//
//

class User {
    var userID : String
    var name : String
    var email : String
    var password : String
    var phone : Int
    
    init(userID: String, name: String, email: String,password: String, phone: Int) {
        self.userID = userID
        self.name = name
        self.email = email
        self.password = password
        self.phone = phone
    }
}

//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    init() { }
    
    init(name: String, username: String, passwordHash: String) {
        self.name = name
        self.username = username
        self.passwordHash = passwordHash
    }
}

// MARK: - Authentication
extension User {
    func generateToken() throws -> UserToken {
        return .init(value: [UInt8].random(count: 16).base64,
                     expirationDate: Date(timeIntervalSinceNow: 60*60*24*30),
                     userID: try self.requireID())
    }
    
    struct Create: Content, Validatable {
        let name: String
        let username: String
        let password: String
        let confirmPassword: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
            validations.add("username", as: String.self, is: .characterSet(.alphanumerics))
            validations.add("password", as: String.self, is: .count(8...))
        }
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey = \User.$username
    static var passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - Migration
extension User {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("name", .string, .required)
                .field("username", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "username")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(User.schema)
                .delete()
        }
    }
}

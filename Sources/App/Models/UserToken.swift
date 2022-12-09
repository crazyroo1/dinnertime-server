//
//  UserToken.swift
//  vapor-server
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Field(key: "expiration_date")
    var expirationDate: Date
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    
    init(value: String, expirationDate: Date, userID: User.IDValue) {
        self.value = value
        self.expirationDate = expirationDate
        self.$user.id = userID
    }
}

// MARK: - Authtication
extension UserToken: ModelTokenAuthenticatable {
    static var valueKey = \UserToken.$value
    static var userKey = \UserToken.$user
    
    var isValid: Bool {
        expirationDate > .now
    }
}

// MARK: - Migration
extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }

        func prepare(on database: Database) async throws {
            try await database.schema(UserToken.schema)
                .id()
                .field("value", .string, .required)
                .field("expiration_date", .date, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(UserToken.schema)
                .delete()
        }
    }
}

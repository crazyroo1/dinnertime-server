//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

struct UserRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("createaccount", use: createAccount)
        
        let passwordProtected = users.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
        
        let tokenAuthenticated = users.grouped(UserToken.authenticator())
        tokenAuthenticated.get("me", use: me)
    }
    
    func createAccount(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        let data = try req.content.decode(User.Create.self)
        guard data.password == data.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        if try await !User
                        .query(on: req.db)
                        .filter(\.$username, .equal, data.username)
                        .all()
                        .isEmpty {
            throw Abort(.badRequest, reason: "A user with that username already exists")
        }
        
        let user = User(name: data.name,
                        username: data.username,
                        passwordHash: try Bcrypt.hash(data.password))
        
        try await user.save(on: req.db)
        
        return .ok
    }
    
    func login(req: Request) async throws -> UserToken {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
    
    func me(req: Request) async throws -> User {
        return try req.auth.require(User.self)
    }
}

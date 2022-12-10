//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

struct TagRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tags = routes
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
            .grouped("tags")
        
        tags.get(use: all)
        tags.post("new", use: new)
        tags.delete("delete", use: delete)
    }
    
    func all(req: Request) async throws -> [Tag] {
        let tags = try await Tag.query(on: req.db)
            .sort(\.$value)
            .all()
        
        return tags
    }
    
    func new(req: Request) async throws -> HTTPStatus {
        let value = try req.content.get(String.self, at: "value")
        
        let tag = Tag(value: value)
        try await tag.save(on: req.db)
        
        return .ok
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let value = try req.content.get(String.self, at: "value")
        
        guard let tag = try await Tag
            .query(on: req.db)
            .filter(\.$value, .equal, value)
            .first() else {
            throw Abort(.badRequest, reason: "A tag with that value does not exist")
        }
        
        try await tag.delete(on: req.db)
        
        return .ok
    }
}

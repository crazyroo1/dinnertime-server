//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

struct LocationRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let locations = routes
            .grouped(UserToken.authenticator())
            .grouped(User.guardMiddleware())
            .grouped("locations")
        
        locations.get(use: all)
        locations.post("new", use: new)
        locations.delete("delete", use: delete)
    }
    
    func all(req: Request) async throws -> [Location] {
        let locations = try await Location
            .query(on: req.db)
            .with(\.$tags)
            .sort(\.$name)
            .all()
        
        return locations
    }
    
    func new(req: Request) async throws -> HTTPStatus {
        try Location.Create.validate(content: req)
        let data = try req.content.decode(Location.Create.self)
        
        let location = Location(name: data.name)
        try await location.save(on: req.db)
        
        return .ok
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let name = try req.content.get(String.self, at: "name")
        
        guard let location = try await Location
            .query(on: req.db)
            .filter(\.$name, .equal, name)
            .first() else {
            throw Abort(.badRequest, reason: "A location with that name does not exist")
        }
        
        try await location.delete(on: req.db)
        
        return .ok
    }
}

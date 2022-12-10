//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class Location: Model, Content {
    static let schema = "locations"
    
    @ID()
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: LocationTag.self, from: \.$location, to: \.$tag)
    var tags: [Tag]
    
    init() { }
    
    init(name: String) {
        self.name = name
    }
}

extension Location {
    struct Create: Content, Validatable {
        let name: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
        }
    }
}

extension Location {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Location.schema)
                .id()
                .field("name", .string, .required)
                .unique(on: "name")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Location.schema)
                .delete()
        }
    }
}

extension Location: Hashable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

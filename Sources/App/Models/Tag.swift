//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class Tag: Model, Content {
    static let schema = "tags"
    
    @ID()
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Siblings(through: LocationTag.self, from: \.$tag, to: \.$location)
    var locations: [Location]
    
    init() { }
    
    init(value: String) {
        self.value = value
    }
}

extension Tag {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Tag.schema)
                .id()
                .field("value", .string, .required)
                .unique(on: "value")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Tag.schema)
                .delete()
        }
    }
}

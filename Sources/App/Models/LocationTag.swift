//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class LocationTag: Model {
    static let schema = "location+tag"
    
    @ID()
    var id: UUID?
    
    @Parent(key: "location_id")
    var location: Location
    
    @Parent(key: "tag_id")
    var tag: Tag
    
    init() { }
    
    init(location: Location, tag: Tag) throws {
        self.$location.id = try location.requireID()
        self.$tag.id = try tag.requireID()
    }
}

extension LocationTag {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(LocationTag.schema)
                .id()
                .field("location_id", .uuid, .required, .references(Location.schema, "id"))
                .field("tag_id", .uuid, .required, .references(Tag.schema, "id"))
                .unique(on: "location_id", "tag_id")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(LocationTag.schema)
                .delete()
        }
    }
}

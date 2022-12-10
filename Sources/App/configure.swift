import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
//    app.databases.use(.sqlite(.memory), as: .sqlite)

    app.migrations.add(User.Migration())
    app.migrations.add(UserToken.Migration())
    app.migrations.add(Location.Migration())
    app.migrations.add(Tag.Migration())
    app.migrations.add(LocationTag.Migration())
    
    try await app.autoMigrate()

    // register routes
    try routes(app)
}

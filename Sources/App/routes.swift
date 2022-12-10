import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserRoutes())
    try app.register(collection: LocationRoutes())
    try app.register(collection: TagRoutes())
    try app.register(collection: SessionRoutes())
}

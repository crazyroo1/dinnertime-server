import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserRoutes())
    try app.register(collection: LocationRoutes())
    try app.register(collection: TagRoutes())
    try app.register(collection: SessionRoutes())
    
    app.post("shutdown") { req -> HTTPStatus in
        Task.detached {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            fatalError()
        }
        return .ok
    }
}

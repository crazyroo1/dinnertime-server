//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

struct SessionRoutes: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sessions = routes
            .grouped("sessions")
        
        sessions.webSocket("join", ":key", onUpgrade: join)
    }
    
    func join(req: Request, socket: WebSocket) async {
        do {
            let tokenValue = try req.query.get(String.self, at: "token")
            guard let token = try await UserToken.query(on: req.db)
                .filter(\.$value == tokenValue)
                .with(\.$user)
                .first() else {
                try await socket.close()
                return
            }
            
            let user = token.user
            
            guard let key = req.parameters.get("key") else {
                try await socket.close()
                return
            }
            
            SessionManager
                .shared
                .connectUserToSession(req: req,
                                      sessionKey: key,
                                      user: user,
                                      socket: socket)
        } catch {
            print("Web socket error: \(error)")
        }
    }
}

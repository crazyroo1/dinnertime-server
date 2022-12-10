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
            .grouped(UserToken.authenticator())
            .grouped("sessions")
        
        sessions.webSocket("join", shouldUpgrade: { req in
            print("should upgrade?")
            print(req)
            let tokenValue = try req.query.get(String.self, at: "token").fromBase64()
            print("token: " + tokenValue)
            guard let token = try await UserToken.query(on: req.db)
                .filter(\.$value == tokenValue)
                .with(\.$user)
                .first() else {
                print("no token")
                return nil
            }
            print("got token: \(token)")
            req.auth.login(token.user)
            print("got user")
            return [:]
        }, onUpgrade: join)
    }
    
    func join(req: Request, socket: WebSocket) async {
        do {
//            let tokenValue = try req.query.get(String.self, at: "token")
//            guard let token = try await UserToken.query(on: req.db)
//                .filter(\.$value == tokenValue)
//                .with(\.$user)
//                .first() else {
//                try await socket.close()
//                return
//            }
//
//            let user = token.user
            print("upgraded")
            let user = try req.auth.require(User.self)
            print("upgraded and has user")
            
            let key = try req.query.get(String.self, at: "key")
            
            guard key != "" else {
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

extension String {
    func fromBase64() -> String {
        return String(data: Data(base64Encoded: self)!, encoding: .utf8)!
    }
}

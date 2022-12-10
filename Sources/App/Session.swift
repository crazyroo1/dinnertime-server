//
//  File.swift
//  
//
//  Created by Turner Eison on 12/9/22.
//

import Fluent
import Vapor

final class SessionManager {
    static let shared = SessionManager()
    static var db: Database! = nil
    
    var sessions = [String: Session]()
    
    func connectUserToSession(req: Request, sessionKey: String, user: User, socket: WebSocket) {
        Self.db = req.db
        
        let session = sessions[sessionKey, default: Session()]
        let sessionUser = SessionUser(user: user, socket: socket)
        
        session.addUser(sessionUser)
        sessions[sessionKey] = session
        
        socket.onClose.whenComplete { [weak session] result in
            print("socket closed for reason \(result) - \(socket.closeCode)")
            print(self.sessions)
            guard let session else { return }
            print("session in memory")
            
            session.removeUser(sessionUser)
            
            Task {
                try await session.sendUserCountUpdate()
            }
            
            if session.canBeSafelyRemoved {
                self.sessions[sessionKey] = nil
                print("session removed.")
            }
        }
    }
}

final class Session {
    private var users = [SessionUser]()
    private var preferences = [UUID: [Location]]()
    
    func addUser(_ sessionUser: SessionUser) {
        users.append(sessionUser)
        
        print("added user. new list is \(users)")
        Task {
            try await sendUserCountUpdate()
        }
        
        prepareSocketForMessage(sessionUser)
    }
    
    func sendUserCountUpdate() async throws {
        for socket in users.map({ $0.socket }) {
            try await socket.send("\(users.count)")
        }
    }
    
    func prepareSocketForMessage(_ sessionUser: SessionUser) {
        sessionUser.socket.onText { [weak self] socket, message async in
            print("got message")
            guard let self else { return }
            print("has self")
            await self.handle(message, from: sessionUser)
            
            // uncomment if only one message is getting through
            // prepareSocketForMessage(sessionUser)
        }
    }
    
    /*
     Message Format:
     Code-Params
     
     Code:
     - preferences
     
     Params:
     ; separated
     */
    func handle(_ message: String, from user: SessionUser) async {
        print("handling message \(message)")
        var message = message
        guard let code = message
            .split(separator: "-", maxSplits: 1)
            .map(String.init)
            .first else {
            return
        }
        
        print("code: \(code)")
        
        message.removeSubrange(message.startIndex ... message.firstIndex(of: "-")!) // can force unwrap bc guard above
        
        switch code {
        case "preferences": await setPreferences(message, for: user)
        default: print("error")
        }
    }
    
    private func makeDecision() async {
        var allPreferences = preferences.map { $0.value }.map { Set($0) }
        
        var intersection = Set(allPreferences.first ?? [])
        allPreferences.removeFirst()
        
        for preference in allPreferences {
            intersection.formIntersection(preference)
        }
        
        print("final intersection: \(intersection)")
        
        guard let decision = intersection.randomElement() else {
            await tellUsersNoIntersection()
            return
        }
        
        print(users)
        print(users.map { $0.socket })
        for socket in users.map({ $0.socket }) {
            try! await socket.send(decision.name)
        }
    }
    
    private func tellUsersNoIntersection() async {
        for socket in users.map({ $0.socket }) {
            try? await socket.send("n/a")
        }
    }
    
    private func setPreferences(_ message: String, for user: SessionUser) async {
        print("setting preferences")
        let locationNames = message.split(separator: ";").map(String.init)
        
        let locations = try? await Location
            .query(on: SessionManager.db)
            .filter(\.$name ~~ locationNames)
            .all()
        
        preferences[try! user.user.requireID()] = locations
        
        print("preferences updated: \(preferences)")
        
//        if preferences.keys.elementsEqual(users.map { $0.user.id! }) { // all are finished
//            await makeDecision()
//        }
        
        if preferences.count >= users.count {
            await makeDecision()
        }
    }
    
    func removeUser(_ sessionUser: SessionUser) {
        users.removeAll { user in
            user == sessionUser
        }
        
        preferences[try! sessionUser.user.requireID()] = nil
        
        print("user removed. new list of users is \(users)")
    }
    
    var canBeSafelyRemoved: Bool { users.isEmpty }
}

struct SessionUser: Equatable {
    let user: User
    let socket: WebSocket
    
    static func == (lhs: SessionUser, rhs: SessionUser) -> Bool {
        lhs.user.id == rhs.user.id
    }
}

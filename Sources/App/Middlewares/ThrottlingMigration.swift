//
//  AddExtraFieldsToHistory.swift
//  App
//
//  Created by Hadi Sharghi on 10/16/1397 AP.
//

import FluentMySQL
import Vapor

struct ThrottlingMigration: Migration {
    typealias Database = MySQLDatabase
    
    
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(ThrottleData.self, on: connection) { (builder) in
            builder.field(for: \.key)
            builder.field(for: \.attempts)
            builder.field(for: \.availableAt)
            
            builder.unique(on: \.key)
        }
    }

    static func revert(on connection: MySQLConnection) -> EventLoopFuture<Void> {
        return Database.update(ThrottleData.self, on: connection) { (builder) in

        }
    }
    
}


struct MySQLVersion: Codable {
    let version: String
}


struct ThrottleData: MySQLModel {
    var id: Int?
    
    var key: String
    var attempts: Int
    var availableAt: Date
}


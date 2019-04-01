import Vapor
import SQLite
import FluentSQLite

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // "It works" page
    router.grouped(SessionsMiddleware.self)
        .get { req -> EventLoopFuture<View> in
        let a = try req.session()["kkk"]

        return try req.view().render("welcome")
    }
    struct SQLiteVersion: Codable {
        let version: String
    }

    // Says hello
    router.throttled().get("hello", String.parameter)  { req throws  -> Future<String> in

            print("hadi")
            return req.future("hadi")
            
//            let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))
//            return req.withPooledConnection(to: .sqlite) { (conn: SQLiteDatabase.Connection) in
//                return conn.select().
//                    .all(decoding: SQLiteVersion.self)
//                }.map { rows in
//                    return rows[0].version
//            }

//
//        return try req.view().render("hello", [
//            "name": req.parameters.next(String.self)
//        ])
    }
}

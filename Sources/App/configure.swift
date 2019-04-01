import Leaf
import Vapor
import SQLite
import FluentSQLite
import MySQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(LeafProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Use Leaf for rendering views
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
//    middlewares.use(ThrottleRequestsMiddleware(rate: 10))
    
    services.register(middlewares)
    

    let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))
//    let mysql = try SQLiteDatabase(storage: .memory)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    try services.register(FluentSQLiteProvider())

    config.prefer(SQLiteCache.self, for: KeyedCache.self)

    
    try services.register(MySQLProvider())
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "127.0.0.1", port: 3306, username: "root", password: "hadi2400", database: "vapor"))
    
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

}

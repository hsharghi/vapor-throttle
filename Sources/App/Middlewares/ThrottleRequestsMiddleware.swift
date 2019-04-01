//
//  ThrottleRequestsMiddleware.swift
//  App
//
//  Created by Hadi Sharghi on 1/4/1398 AP.
//

import Vapor
import SQLite
import FluentSQLite
import MySQL

final class ThrottleRequestsMiddleware: Middleware {
    
    let limiter: RateLimiter
    
    init(limiter: RateLimiter) {
        self.limiter = limiter
    }
    
    init(numRequests: Int, per interval: RateLimiter.Interval) {
        self.limiter = RateLimiter(numRequests: numRequests, per: interval)
    }
    
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        limiter.db = try request.connectionPool(to: .mysql)
        
        let responder = BasicResponder { req in
            let key = try self.resolveRequestSignature(request: request)
            if self.limiter.tooManyAttempts(key: key, max: 10) {
                throw Abort(.forbidden, headers: HTTPHeaders(self.getHeaders(key: key).toTuples()), reason: "Too many requests")
            }
            
            return request.withPooledConnection(to: .mysql) { (conn: MySQLDatabase.Connection) in
                return conn.raw("SELECT @@version as version")
                    .all(decoding: MySQLVersion.self)
                }.flatMap { rows in
                    let v = rows[0].version
                    print("Version: \(v)")
                    return try next.respond(to: request)
            }
        }
        return try responder.respond(to: request)
    }
}

enum ThrottleError: Error {
    case invalidRequest
    case tooManyRequests(tryIn: Int)
}

extension ThrottleRequestsMiddleware {
    
    /// Resolve the number of attempts if the user is authenticated or not.
    private func getMaxAttempts() -> Int {
        return limiter.maxAttempts
    }


    /// Resolve request signature.
    private func resolveRequestSignature(request: Request) throws -> String
    {
        var key: String?
        if let token = request.http.headers.bearerAuthorization {
            key = token.token
        }
        if let host = request.http.remotePeer.hostname,
            let port = request.http.remotePeer.port {
            key = "\(host)\(port)"
            print(key!)
        }

        guard key != nil else {
            throw Abort(.forbidden, reason: "Can not verify request")
        }

        return key!
    }
    
    
    /// Create a 'too many attempts' exception.
    private func buildException(key:String) -> ThrottleError
    {
        return ThrottleError.tooManyRequests(tryIn: 10)
//    $retryAfter = $this->getTimeUntilNextRetry($key);
//
//    $headers = $this->getHeaders(
//    $maxAttempts,
//    $this->calculateRemainingAttempts($key, $maxAttempts, $retryAfter),
//    $retryAfter
//    );
//
//    return new ThrottleRequestsException(
//    'Too Many Attempts.', null, $headers
//    );
    }
    
    
    /// Get the number of seconds until the next retry.
    private func getTimeUntilNextRetry(key: String) -> Int {
        return limiter.availableIn(key: key)
    }
    
    

    /// Add the limit header information to the given response.
    private func addHeaders(request: Request, key: String) -> Request
    {
        getHeaders(key: key).forEach { (headerData) in
            let (key, value) = headerData
            request.http.headers.add(name: key, value: value)
        }
        
        return request
    }


    /// Get the limit headers information.
    private func getHeaders(key: String) -> [String: String] {
        var headers = [
            "X-RateLimit-Limit" : "\(limiter.maxAttempts)",
            "X-RateLimit-Remaining" : "\(limiter.retriesLeft(key: key, maxAttempts: limiter.maxAttempts))"
        ]

        let retryAfter:Int? = nil
        if let retryAfter = retryAfter {
            headers["Retry-After"] = "\(retryAfter)"
            headers["X-RateLimit-Reset"] = "\(Int(availableAt(delay: TimeInterval(exactly: retryAfter) ?? 0).timeIntervalSince1970))"
        }
        
        return headers
    }

    
    /// Get the "available at" UNIX timestamp.
    private func availableAt(delay: TimeInterval) -> Date {
        return Date().addingTimeInterval(delay)
    }

}

extension Router {
    func throttled(numRequests: Int = 10, per interval: RateLimiter.Interval = .second) -> Router {
        return self.grouped(ThrottleRequestsMiddleware(numRequests: numRequests, per: interval))
    }
}

extension Dictionary where Key == String, Value == String  {
    func toTuples() -> [(String, String)] {
        var tuples: [(String, String)] = []
        for (key, value) in self {
            tuples.append((key, value))
        }
        return tuples
    }
}


//
//  RateLimiter.swift
//  App
//
//  Created by Hadi Sharghi on 1/6/1398 AP.
//

import Vapor
import FluentMySQL



class RateLimiter {
    
    public enum Interval {
        case second
        case minute
        case hour
        case day
    }
    
    public var db: MySQLDatabase

    private let limit: Int
    private let per: Interval
    
    init(numRequests: Int, per interval: Interval ) {
        self.limit = numRequests
        self.per = interval
    }
    
    public var interval: Int {
        switch per {
        case .second:
            return 1
        case .minute:
            return 60
        case .hour:
            return 3_600
        case .day:
            return 86_400
        }
    }
    
    public var maxAttempts: Int {
        return limit
    }
    
    /// Determine if the given key has been "accessed" too many times.
    public func tooManyAttempts(key: String, max: Int) -> Bool {
        
        return true
    }
    
    
    /// Increment the counter for a given key for a given decay time.
    public func hit(key: String, decayMinutes: Int = 1) -> Int {
        return 1
    }
    
    
    /// Get the number of attempts for the given key.
    public func attempts(key: String) -> Int {
        return 0
    }
    
    
    /// Reset the number of attempts for the given key.
    public func resetAttempts(key: String) {
        
    }
    
    /// Get the number of retries left for the given key.
    public func retriesLeft(key: String, maxAttempts: Int) -> Int {
        return maxAttempts
    }
    
    
    /// Clear the hits and lockout timer for the given key.
    public func clear(key: String) {
        resetAttempts(key: key);
        
//        forget($key.':timer');
    }
    
    
    /// Get the number of seconds until the "key" is accessible again.
    public func availableIn(key: String) -> Int {
        return 0
    }
}



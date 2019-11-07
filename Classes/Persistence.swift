//
//  Persistence.swift
//  Alamofire
//
//  Created by Zed on 2019/10/11.
//

import Foundation


public protocol Persistence: Codable {
    func getProperties() -> [String: Any?]?
    func save(to fileName: String)
    static func persistenceURL() -> URL
    static func load(from fileName: String) -> Self?
}
extension Persistence {
    /// Return name and value of all properties as Dictionary
    public func getProperties() -> [String: Any?]? {
        var properties: [String: Any?] = [:]
        
        
        if let superMirror = Mirror(reflecting: self).superclassMirror,
            let superProperties = getProperties(from: superMirror)
        {
            for superProperty in superProperties {
                properties[superProperty.key] = superProperty.value
            }
        }
        
        let selfMirror = Mirror(reflecting: self)
        if let selfProperties = getProperties(from: selfMirror) {
            for selfProperty in selfProperties {
                properties[selfProperty.key] = selfProperty.value
            }
        }
        
        if properties.count == 0 { return nil }
        return properties
    }
    
    /// return url of persistence folder
    public static func persistenceURL() -> URL {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        let persistenceURL = URL(fileURLWithPath: cachePath!).appendingPathComponent("Persistence")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: persistenceURL.path) == false {
            do {
                try fileManager.createDirectory(at: persistenceURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error { MLog("Create `Persistence` folder fail \n\(error)") }
        }
        return persistenceURL
    }
    
    /// Save instance to persistence path with specify file name
    public func save(to fileName: String) {
        var data: Data?
        do { data = try JSONEncoder().encode(self) }
        catch let error { MLog("JSON encode fail \n\(error)") }
        
        if data != nil {
            let url = Self.persistenceURL().appendingPathComponent(fileName)
            
            do { try data?.write(to: url, options: .atomic) }
            catch let error { MLog("Data save fail \n\(error)") }
        }
    }
    
    /// load persistence file data and return initialize instance
    public static func load(from fileName: String) -> Self? {
        let url = persistenceURL().appendingPathComponent(fileName)
        var data: Data?
        
        do {
            try data = Data(contentsOf: url)
            if data != nil {
                return try JSONDecoder().decode(Self.self, from: data!)
            }
        }
        catch let error { MLog("Load fail, \n\(error)") }
        
        return nil
    }
    
    // MARK: Private method
    private func getProperties(from mirror: Mirror) -> [String: Any?]? {
        guard mirror.children.count > 0 else { return nil }
        
        var properties: [String: Any?] = [:]
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            let propertyValue = child.value
            
            if let persistenceObject = propertyValue as? Persistence {
                print("Custom Object: \(propertyValue)")
                let objectProperties = persistenceObject.getProperties()
                properties[propertyName] = objectProperties
            }
            else { properties[propertyName] = propertyValue }
        }
        return properties
    }
}

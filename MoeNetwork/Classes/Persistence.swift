//
//  Persistence.swift
//  Alamofire
//
//  Created by Zed on 2019/10/11.
//
/**
 【持久化数据】
 1. 将数据写入到沙盒文件，进行持久化保存
 2. 读取沙盒文件，解析返回保存的数据
 */

import Foundation
import MoeCommon


// MARK: - 持化化存储协议

public protocol Persistence: Codable {
    func getProperties() -> [String: Any?]?
    func save(to fileName: String)
    static func persistenceURL() -> URL
    static func load(from fileName: String) -> Self?
}

extension Persistence {
    /// 返回已存储的所有「键值对」
    /// - Returns: 已存储的所有「Key：Value」
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
    
    /// 返回持久化文件的存储目录
    /// - Returns: 存储目录
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
    
    /// 将持久化数据保存至存储目录的指定文件
    /// - Parameter fileName: 指定文件的文件名
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
    
    /// 加载解析指定文件的数据，实例化成持久化数据实例
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
                MLog("Custom Object: \(propertyValue)")
                let objectProperties = persistenceObject.getProperties()
                properties[propertyName] = objectProperties
            }
            else { properties[propertyName] = propertyValue }
        }
        return properties
    }
}

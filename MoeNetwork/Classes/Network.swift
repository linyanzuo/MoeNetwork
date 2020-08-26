//
//  Network.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//


// MARK: 请求
extension Request {
    /// 请求报头域（请求头）
    public typealias HeaderField = [String: String]
    
    /// 请求参数
    public typealias Parameter = [String: Any]
    
    /// 请求方法
    public enum Method: String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case delete = "DELETE"
        case head   = "HEAD"
        case patch  = "PATCH"
    }

    /// 参数编码类型，即【Content-Type】的配置
    public enum ParameterEncoding {
        case urlEncoding
        /// JSON格式的请求参数，即【Content-Type="application/json"】
        case jsonEncoding
        case xmlEncoding
    }
}


// MARK: 响应
extension Response {
    /// 序列化器
    public enum Serializer {
//        case data
//        case string
        case json
        case xml
        case dataObject(DataObject.Type)
        
        public static func == (lhs: Response.Serializer, rhs: Response.Serializer) -> Bool {
            switch (lhs, rhs) {
            case (.json, .json): return true
            case (.xml, .xml): return true
            case (.dataObject(let a), .dataObject(let b)): return a == b
            default:
                return false
            }
        }
        
        public var responseType: DataObject.Type? {
            switch self {
            case .dataObject(let type):
                return type
            default:
                return nil
            }
        }
    }
}

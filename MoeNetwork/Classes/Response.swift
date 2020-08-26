//
//  Response.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//
/**
 【响应】基类
 */

import HandyJSON
import Alamofire


public typealias DataObject = HandyJSON


/// 响应及处理过的数据结果
open class Response {
    public required init() {
        self.response = nil
        self.originalData = nil
    }

    /// 请求开始时间
    public var startTime: Date?
    /// 请求完成时间
    public var completedTime: Date?
    
    /// 服务器响应URL请求的底层响应
    public var response: HTTPURLResponse?
    
    /// 服务器返回的原始数据
    public var originalData: Data?
    
    /// XML序列化后的字典
    public var xmlDictionary: [String: Any]?
    
    /// JSON序列化后的字典
    public var jsonDictionary: [String: Any]?
    
    /// DataObject序列化后的对象
    public var dataObject: DataObject?
}


// MARK: DataObject序列化器

extension Alamofire.Request {
    public static func serializeResponseDataObject(
        options: JSONSerialization.ReadingOptions,
        responseType: DataObject.Type,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) -> Result<Any> {
        guard error == nil else { return .failure(error!) }
        let emptyDataStatusCodes: Set<Int> = [204, 205]
        if let response = response, emptyDataStatusCodes.contains(response.statusCode) {
            return .success(NSNull())
        }

        guard let validData = data, validData.count > 0 else {
            return .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
        }

        do {
            let json = try JSONSerialization.jsonObject(with: validData, options: options)
            guard let dict = json as? [String: Any] else {
                ///  Todo: JSON格式错误导致HandyJson序列化失败
                let reason = AFError.ResponseSerializationFailureReason.jsonSerializationFailed(error: error!)
                return .failure(AFError.responseSerializationFailed(reason: reason))
            }
            guard let responseObject = responseType.deserialize(from: dict) else {
                ///  Todo: HandyJSON序列化失败
                let reason = AFError.ResponseSerializationFailureReason.jsonSerializationFailed(error: error!)
                return .failure(AFError.responseSerializationFailed(reason: reason))
            }
            return .success(responseObject)
        } catch {
            ///  Todo: JSON格式错误导致HandyJson序列化失败
            return .failure(AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error)))
        }
    }
}


// MARK: - 扩展HandyJSON类型的响应数据处理

extension Alamofire.DataRequest {
    public static func handyJsonResponseSerializer(
        options: JSONSerialization.ReadingOptions = .allowFragments,
        responseType: DataObject.Type
    ) -> DataResponseSerializer<Any> {
        return DataResponseSerializer { _, response, data, error in
            return Alamofire.Request.serializeResponseDataObject(
                options: options,
                responseType: responseType,
                response: response,
                data: data,
                error: error
            )
        }
    }
}


//extension Alamofire.AFError {
//    public enum ResponseSerializationFailureReason {
//        /// `JSONSerialization`因底层系统错误导致序列化失败
//        case handyJsonSerializationFailed(error: Error)
//    }
//}
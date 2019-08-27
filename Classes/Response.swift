//
//  Response.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit
import HandyJSON


open class Response: HandyJSON {
    public required init() {}

    // MARK: Methods that subclass should override

    /// Response data from server which represent the status message
    /// Subclass should override this method to return the error code from response
    open func statusMessage() -> String {
        return "Default Error Message from Response of MoeNetwork"
    }

    /// status code in response data from server, which represent the status
    /// Subclass should override this method to return the error code from response
    open func statusCode() -> Int {
        return -1
    }

    /// Response data from server which represent the target data that you really want
    /// Subclass should override this method to return the target data from response
    open func data() -> ResponseData? {
        return nil
    }

    public static func responseType() -> Response.Type {
        return Response.self
    }
}


public protocol ResponseData: HandyJSON {
}

//
//  DispatchQueue+Alamofire.swift
//
//  Copyright (c) 2014 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Dispatch
import Foundation

extension DispatchQueue {
    /// 该Qos等级用于用户交互的任务，如动画、事件响应、更新应用的交互
    ///
    /// `userInteractive`任务在系统中拥有最高优先级。处理用户交互、或积极更新交互界面的任务或队列，可使用该类型。
    /// 比如为动画、或追踪交互事件使用该类型
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    /// 该Qos等级用于可能会妨碍用户操作的任务
    ///
    /// `userInitiated`任务在系统中拥有仅次于`userInteractive`的次高优先级。
    /// 该等级赋值于用户正在操作中迫切需要(立即)得到结果的任务，否则可能妨碍使用应用
    /// 比如，使用该Qos等级加载想展示给用户查看的邮件内容
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    /// 该Qos等级用于用户并不主动了解情况的任务
    ///
    /// `utility`任务的优先级比`default`、`userInitiated`、`userInteractive`任务的低，但高于`background`任务
    /// 该等级赋值于并不会妨碍用户继续使用应用的任务。
    /// 比如，使用该Qos等级于持续时间较长、用户并不关心其进度的任务
    static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    /// 该Qos等级用于维护或清理已创建的任务
    ///
    /// `background`任务的优先级是所有任务中最低的。
    /// 该等级赋值于应用在后台运行时执行工作的任务或调度队列
    static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }

    /// 计划在延迟多长时间后， 异步执行指定的闭包
    /// - Parameter delay: 延迟执行的时间
    /// - Parameter closure: 要执行的闭包
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}

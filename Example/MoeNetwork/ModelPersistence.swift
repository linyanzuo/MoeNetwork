//
//  ModelPersistence.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/10/11.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import MoeNetwork


class Person: Persistence {
    var id = "0411"
    var name: String? = "zed"
}

class Developer: Person {
    var grade: [String: Int] = [
        "First" : 1,
        "Second" : 2,
        "Third" : 3
    ]
    var speed = 60
    var subject: Subject = Subject()
}

class Require: Persistence {
    var ageLeast = 18
    var teacher = Teacher()
}

class Subject: Require {
    var name = "iOS"
    var experience = 5
}

struct Teacher: Persistence, Codable {
    var name = "Teacher"
    var subject = "iOS"
    var grade = 9
}


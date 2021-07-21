//
//  Category.swift
//  IGToDoApp
//
//  Created by İsmail on 17.07.2021.
//

import Foundation
import RealmSwift

class Category : Object {
//    @objc dynamic var id : String = UUID().uuidString
    @objc dynamic var name : String = ""
    @objc dynamic var creationDate : Date?
    let items = List<Item>()
}

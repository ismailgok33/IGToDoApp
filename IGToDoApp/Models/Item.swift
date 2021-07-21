//
//  Item.swift
//  IGToDoApp
//
//  Created by İsmail on 17.07.2021.
//

import Foundation
import RealmSwift

class Item : Object {
//    @objc dynamic var id : String = UUID().uuidString
    @objc dynamic var title : String = ""
    @objc dynamic var done : Bool = false
    @objc dynamic var creationDate : Date?
    var parentCategory = LinkingObjects(fromType: Category.self, property: "items")
}

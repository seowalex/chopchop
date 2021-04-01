//
//  OnlineIngredientRecord.swift
//  ChopChop
//
//  Created by Cao Wenjie on 27/3/21.
//
import FirebaseFirestore

struct OnlineIngredientRecord {
    var name: String
    var quantity: QuantityRecord
}

extension OnlineIngredientRecord: Codable {
}

extension OnlineIngredientRecord {
    func toIngredientDetails() throws -> OnlineIngredientDetails {
        try OnlineIngredientDetails(name: name, quantity: quantity.toQuantity())
    }
}

extension OnlineIngredientRecord {
    func toRecipeIngredient() throws -> RecipeIngredient {
        try RecipeIngredient(name: name, quantity: quantity.toQuantity())
    }
}

extension OnlineIngredientRecord {
    func toDict() -> [String: Any] {
        ["name": name, "quantity": quantity.toDict()]
    }
}

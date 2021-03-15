import Foundation

/**
 Represents a batch of an ingredient.
 A batch contains some quantity of an ingredient with the same expiry date.
 */
class IngredientBatch {
    private(set) var quantity: Quantity
    private(set) var expiryDate: Date?

    init(quantity: Quantity, expiryDate: Date?) {
        self.quantity = quantity
        self.expiryDate = expiryDate
    }

    var isEmpty: Bool {
        quantity.value == 0
    }

    func add(_ quantity: Quantity) throws {
        try self.quantity += quantity
    }

    func subtract(_ quantity: Quantity) throws {
        try self.quantity -= quantity
    }
}

/**
 Two batches are compared based on their expiry dates.
 Two batches are equal if they have the same expiry date and quantity
 */
extension IngredientBatch: Comparable {
    static func < (lhs: IngredientBatch, rhs: IngredientBatch) -> Bool {
        guard let rightDate = rhs.expiryDate else {
            return true
        }

        guard let leftDate = lhs.expiryDate else {
            return false
        }

        return leftDate < rightDate
    }

    static func == (lhs: IngredientBatch, rhs: IngredientBatch) -> Bool {
        lhs.expiryDate == rhs.expiryDate && lhs.quantity == rhs.quantity
    }
}

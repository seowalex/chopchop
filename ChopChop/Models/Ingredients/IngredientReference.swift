/**
 Represents some quantity of an ingredient.
 */
struct IngredientReference {
    let name: String
    private(set) var quantity: Quantity

    init(name: String, quantity: Quantity) {
        self.name = name
        self.quantity = quantity
    }

    mutating func add(_ quantity: Quantity) throws {
        try self.quantity += quantity
    }

    mutating func subtract(_ quantity: Quantity) throws {
        try self.quantity -= quantity
    }

    mutating func scale(_ factor: Double) throws {
        try self.quantity *= factor
    }
}

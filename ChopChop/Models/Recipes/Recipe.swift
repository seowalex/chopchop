import Foundation
import GRDB

/// Note there is no relationship between steps and ingredients after parsing stage
class Recipe: FetchableRecord, ObservableObject {
    var id: Int64?
    @Published var onlineId: String?
    @Published private(set) var name: String
    @Published private(set) var servings: Double
    @Published var recipeCategoryId: Int64?
    @Published private(set) var difficulty: Difficulty?
    @Published private(set) var ingredients: [RecipeIngredient]
    @Published private(set) var stepGraph: RecipeStepGraph

    init(name: String, onlineId: String? = nil, servings: Double = 1,
         recipeCategoryId: Int64? = nil, difficulty: Difficulty? = nil,
         ingredients: [RecipeIngredient] = [], graph: RecipeStepGraph = RecipeStepGraph()) throws {
        self.onlineId = onlineId
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw RecipeError.invalidName
        }
        self.name = trimmedName

        guard servings > 0 else {
            throw RecipeError.invalidServings
        }
        self.servings = servings
        self.recipeCategoryId = recipeCategoryId
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.stepGraph = graph
        assert(checkRepresentation())
    }

    func updateRecipe(_ newRecipe: Recipe) {
        assert(checkRepresentation())
        name = newRecipe.name
        servings = newRecipe.servings
        recipeCategoryId = newRecipe.recipeCategoryId
        difficulty = newRecipe.difficulty
        ingredients = newRecipe.ingredients
        stepGraph = newRecipe.stepGraph
        assert(checkRepresentation())
    }

    // ingredient related functions
    func addIngredient(name: String, quantity: Quantity) throws {
        assert(checkRepresentation())
        if let existingIngredient = ingredients.first(where: { $0.name == name }) {
            try existingIngredient.add(quantity)
        } else {
            let addedIngredient = try RecipeIngredient(name: name, quantity: quantity)
            ingredients.append(addedIngredient)
        }
        assert(checkRepresentation())
    }

    func removeIngredient(_ removedIngredient: RecipeIngredient) throws {
        assert(checkRepresentation())
        guard (ingredients.contains { $0 == removedIngredient }) else {
            throw RecipeError.nonExistentIngredient
        }

        ingredients.removeAll { $0 == removedIngredient }
        assert(checkRepresentation())
    }

    func updateIngredient(oldIngredient: RecipeIngredient, name: String, quantity: Quantity) throws {
        // note there is no effect on steps on updating ingredients
        assert(checkRepresentation())
        guard ingredients.contains(where: { $0.name == oldIngredient.name }) else {
            throw RecipeError.nonExistentIngredient
        }
        if oldIngredient.name == name {
            oldIngredient.updateQuantity(quantity)
        } else {
            guard let existingIngredient = ingredients.first(where: { $0.name == name }) else {
                try oldIngredient.rename(name)
                oldIngredient.updateQuantity(quantity)
                return
            }
            try removeIngredient(oldIngredient)
            try existingIngredient.add(quantity)

        }
        assert(checkRepresentation())
    }

    /// Returns total time taken to complete the recipe in seconds, computed from time taken for each step
    var totalTimeTaken: Int {
        stepGraph.nodes.map { $0.label.timeTaken }.reduce(0, +)
    }

    private func checkRepresentation() -> Bool {
        !name.isEmpty && servings > 0 && checkNoDuplicateIngredients(ingredients: ingredients)
    }

    private func checkNoDuplicateIngredients(ingredients: [RecipeIngredient]) -> Bool {
        // synonyms of ingredients are allowed e.g. brinjal and eggplant
        return ingredients.allSatisfy { ingredient -> Bool in
            ingredients.filter { $0.name == ingredient.name }.count == 1
        }
    }

    required init(row: Row) {
        id = row[RecipeRecord.Columns.id]
        onlineId = row[RecipeRecord.Columns.onlineId]
        recipeCategoryId = row[RecipeRecord.Columns.recipeCategoryId]
        name = row[RecipeRecord.Columns.name]
        servings = row[RecipeRecord.Columns.servings]
        difficulty = row[RecipeRecord.Columns.difficulty]
        ingredients = row.prefetchedRows["recipeIngredients"]?.compactMap {
            let record = RecipeIngredientRecord(row: $0)
            guard let quantity = try? Quantity(from: record.quantity) else {
                return nil
            }

            return try? RecipeIngredient(name: record.name, quantity: quantity)
        } ?? []

        stepGraph = row["recipeStepGraph"]
    }

}

extension Recipe: Equatable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.name == rhs.name
    }
}

extension Recipe: NSCopying {
    // TODO: Properly copy step graph
    func copy(with zone: NSZone? = nil) -> Any {
        let newIngredients = ingredients.compactMap { $0.copy() as? RecipeIngredient }

        do {
            let copy = try Recipe(
                name: name,
                servings: servings,
                difficulty: difficulty,
                ingredients: newIngredients,
                graph: stepGraph)
            copy.id = id
            copy.recipeCategoryId = recipeCategoryId
            return copy
        } catch {
            fatalError("Cannot copy Recipe")
        }

    }
}

enum RecipeError: String, Error {
    case invalidName = "Recipe name cannot be empty."
    case invalidServings = "Recipe serving should be positive."
    case invalidCuisine = "Cuisine chosen is non-existent."
    case invalidIngredients = "Ingredients are invalid."
    case nonExistentStep = "Recipe step is non-existent."
    case nonExistentIngredient = "Ingredients are non-existent."
    case invalidReorderSteps = "Invalid reorder steps."
}

import SwiftUI
import Combine

class CompleteSessionRecipeViewModel: ObservableObject {
    @Published var deductibleIngredientsViewModels: [DeductibleIngredientViewModel] = []
    @Published var isSuccess = false
    private var recipe: Recipe

    private let storageManager = StorageManager()
    private(set) var ingredientsInStore: [IngredientInfo] = []
    private var ingredientsCancellable: AnyCancellable?

    init(recipe: Recipe) {
        self.recipe = recipe

        ingredientsCancellable = ingredientsPublisher()
            .sink { [weak self] ingredients in
                self?.ingredientsInStore = ingredients
                if self?.isSuccess == false {
                    self?.deductibleIngredientsViewModels = self?.convertToDeductibleIngredientViewModels(recipeIngredients: recipe.ingredients) ?? []
                }
            }
    }

    func submit() {
        var ingredientsToSave: [Ingredient] = []
        // atomic
        for ingredientViewModel in deductibleIngredientsViewModels {
            ingredientViewModel.updateError(isError: false) // reset error

            guard let amount = Double(ingredientViewModel.deductBy) else {
                ingredientViewModel.updateError(isError: true)
                continue
            }

            guard let id = ingredientViewModel.ingredient.id else {
                assertionFailure("Ingredient should have id")
                continue
            }
            guard let ingredient = try? storageManager.fetchIngredient(id: id) else {
                continue
            }

            guard let quantityUsed = try? Quantity(ingredientViewModel.recipeIngredient.quantity.type, value: amount) else {
                ingredientViewModel.updateError(isError: true)
                continue
            }

            guard let sufficientAmount = try? ingredient.contains(quantity: quantityUsed), sufficientAmount else {
                ingredientViewModel.updateError(isError: true)
                continue
            }

            do {
                try ingredient.use(quantity: quantityUsed)
                ingredientsToSave.append(ingredient)
            } catch {
                assertionFailure("Ingredient should have sufficient quantity")
                continue
            }
        }

        guard (deductibleIngredientsViewModels.allSatisfy { !$0.isError }) else {
            return
        }

        // only do database operations here
        for var ingredient in ingredientsToSave {
            do {
                try storageManager.saveIngredient(&ingredient)
            } catch {
                assertionFailure("Couldn't save ingredient")
            }
        }

        isSuccess = deductibleIngredientsViewModels.allSatisfy { !$0.isError }
    }

    private func ingredientsPublisher() -> AnyPublisher<[IngredientInfo], Never> {
        storageManager.ingredientsPublisher()
            .catch { _ in
                Just<[IngredientInfo]>([])
            }
            .eraseToAnyPublisher()
    }

    private func convertToDeductibleIngredientViewModels(recipeIngredients: [RecipeIngredient]) -> [DeductibleIngredientViewModel] {

        recipeIngredients.compactMap { recipeIngredient -> DeductibleIngredientViewModel? in
            guard let mappedIngredientId = (ingredientsInStore.first { $0.name == recipeIngredient.name })?.id else {
                return nil
            }
            guard let mappedIngredient = try? storageManager.fetchIngredient(id: mappedIngredientId) else {
                return nil
            }

            return DeductibleIngredientViewModel(ingredient: mappedIngredient, recipeIngredient: recipeIngredient)
        }
    }

}

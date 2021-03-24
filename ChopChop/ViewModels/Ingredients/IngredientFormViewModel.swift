import SwiftUI
import Combine

class IngredientFormViewModel: ObservableObject {
    private(set) var ingredient: Ingredient?
    let isEdit: Bool

    @Published var selectedType: BaseQuantityType
    @Published var inputName: String
    @Published var selectedCategory: IngredientCategory?
    @Published var image: UIImage
    @Published private(set) var ingredientCategories: [IngredientCategory] = []

    @Published var isShowingPhotoLibrary = false
    var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary

    private let storageManager = StorageManager()
    private var ingredientCategoriesCancellable: AnyCancellable?

    init(edit ingredient: Ingredient) {
        self.ingredient = ingredient
        self.isEdit = true

        self.selectedType = ingredient.quantityType
        self.inputName = ingredient.name
        self.image = storageManager.fetchIngredientImage(name: ingredient.name) ?? UIImage()

        ingredientCategoriesCancellable = storageManager.ingredientCategoriesPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] categories in
                self?.ingredientCategories = categories
                self?.selectedCategory = categories.first(where: { $0.id == ingredient.ingredientCategoryId })
            })
    }

    init(addToCategory categoryId: Int64?) {
        self.ingredient = nil
        self.isEdit = false

        self.selectedType = .count
        self.inputName = ""
        self.image = UIImage()

        ingredientCategoriesCancellable = storageManager.ingredientCategoriesPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] categories in
                self?.ingredientCategories = categories
                self?.selectedCategory = categories.first(where: { $0.id == categoryId })
            })
    }

    var areFieldsValid: Bool {
        !inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() throws {
        guard areFieldsValid else {
            return
        }

        if isEdit {
            try ingredient?.rename(inputName)

            if image != UIImage() {
                try storageManager.saveIngredientImage(image, name: inputName)
            }
        } else {
            ingredient = try Ingredient(name: inputName, type: selectedType)
        }

        guard var savedIngredient = ingredient else {
            return
        }

        if let category = selectedCategory {
            try category.add(savedIngredient)
        } else {
            savedIngredient.ingredientCategoryId = nil
        }

        if image != UIImage() {
            try storageManager.saveIngredientImage(image, name: inputName)
        }

        try storageManager.saveIngredient(&savedIngredient)
    }

    func reset() {
        self.selectedType = .count
        self.inputName = ""
        self.selectedCategory = nil
        self.image = UIImage()
    }
}

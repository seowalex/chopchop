import Combine
import SwiftUI

final class SidebarViewModel: ObservableObject {
    @Published private(set) var recipeCategories: [RecipeCategory] = []
    @Published private(set) var ingredientCategories: [IngredientCategory] = []

    @Published var alertIsPresented = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    @Published var sheetIsPresented = false
    @Published var categoryName = ""
    @Published var categoryType: CategoryType?

    private let storageManager = StorageManager()
    private var recipeCategoriesCancellable: AnyCancellable?
    private var ingredientCategoriesCancellable: AnyCancellable?

    // to pass into OnlineRecipeCollectionViewModel
    @Published private(set) var followeeIds: [String] = []
    @Published private(set) var userIds: [String] = []
    private var followeesCancellable: AnyCancellable?
    private var usersCancellable: AnyCancellable?

    private let settings: UserSettings

    init(settings: UserSettings) {
        self.settings = settings
        recipeCategoriesCancellable = recipeCategoriesPublisher()
            .sink { [weak self] categories in
                self?.recipeCategories = categories
            }

        ingredientCategoriesCancellable = ingredientCategoriesPublisher()
            .sink { [weak self] categories in
                self?.ingredientCategories = categories
            }

        followeesCancellable = followeesPublisher()
            .sink { [weak self] followees in
                self?.followeeIds = followees.compactMap { $0.id }
            }

        usersCancellable = allUsersPublisher()
            .sink { [weak self] users in
                self?.userIds = users.compactMap { $0.id }.filter { $0 != self?.settings.userId }
            }
    }

    func addRecipeCategory(name: String) {
        do {
            var category = try RecipeCategory(name: name)
            try storageManager.saveRecipeCategory(&category)
        } catch {
            if let message = (error as? LocalizedError)?.errorDescription {
                alertTitle = "Error"
                alertMessage = message
            } else {
                alertTitle = "Database error"
                alertMessage = "\(error)"
            }

            alertIsPresented = true
        }
    }

    func addIngredientCategory(name: String) {
        do {
            var category = try IngredientCategory(name: name)
            try storageManager.saveIngredientCategory(&category)
        } catch {
            if let message = (error as? LocalizedError)?.errorDescription {
                alertTitle = "Error"
                alertMessage = message
            } else {
                alertTitle = "Database error"
                alertMessage = "\(error)"
            }

            alertIsPresented = true
        }
    }

    func deleteRecipeCategories(at offsets: IndexSet) {
        do {
            let ids = offsets.compactMap { recipeCategories[$0].id }
            try storageManager.deleteRecipeCategories(ids: ids)
        } catch {
            alertTitle = "Database error"
            alertMessage = "\(error)"

            alertIsPresented = true
        }
    }

    func deleteIngredientCategories(at offsets: IndexSet) {
        do {
            let ids = offsets.compactMap { ingredientCategories[$0].id }
            try storageManager.deleteIngredientCategories(ids: ids)
        } catch {
            alertTitle = "Database error"
            alertMessage = "\(error)"

            alertIsPresented = true
        }
    }

    private func recipeCategoriesPublisher() -> AnyPublisher<[RecipeCategory], Never> {
        storageManager.recipeCategoriesPublisher()
            .catch { _ in
                Just<[RecipeCategory]>([])
            }
            .eraseToAnyPublisher()
    }

    private func ingredientCategoriesPublisher() -> AnyPublisher<[IngredientCategory], Never> {
        storageManager.ingredientCategoriesPublisher()
            .catch { _ in
                Just<[IngredientCategory]>([])
            }
            .eraseToAnyPublisher()
    }

    private func followeesPublisher() -> AnyPublisher<[User], Never> {
        guard let USER_ID = settings.userId else {
            fatalError()
        }

        return storageManager.allFolloweesPublisher(userId: USER_ID)
            .catch { _ in
                Just<[User]>([])
            }
            .eraseToAnyPublisher()
    }

    private func allUsersPublisher() -> AnyPublisher<[User], Never> {
        storageManager.allUsersPublisher()
            .catch { _ in
                Just<[User]>([])
            }
            .eraseToAnyPublisher()
    }
}

extension SidebarViewModel {
    enum CategoryType {
        case recipe, ingredient
    }
}

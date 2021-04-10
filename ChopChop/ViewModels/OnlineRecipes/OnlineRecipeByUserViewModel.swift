import SwiftUI
import Combine

class OnlineRecipeByUserViewModel: OnlineRecipeViewModel {
    @Published var creatorName = "No name" {
        willSet { self.objectWillChange.send() }
    }

    override init(recipe: OnlineRecipe, downloadRecipeViewModel: DownloadRecipeViewModel, settings: UserSettings) {
        super.init(recipe: recipe, downloadRecipeViewModel: downloadRecipeViewModel, settings: settings)

        storageManager.fetchUserById(userId: recipe.userId) {
            user, _ in
            guard let name = user?.name else {
                return
            }
            self.creatorName = name
        }
    }

    var ownRating: RecipeRating? {
        recipe.ratings.first(where: { $0.userId == settings.userId })
    }

    func tapRating(_ ratingValue: Int) {
        guard let userId = settings.userId else {
            assertionFailure()
            return
        }

        guard let rating = RatingScore(rawValue: ratingValue + 1) else {
            assertionFailure()
            return
        }

        guard ownRating != nil else {
            storageManager.rateRecipe(recipeId: recipe.id, userId: userId, rating: rating)
            return
        }
        storageManager.rerateRecipe(recipeId: recipe.id, newRating: RecipeRating(userId: userId, score: rating))
    }

    func removeRating() {
        guard let ownRating = ownRating else {
            assertionFailure()
            return
        }

        storageManager.unrateRecipe(recipeId: recipe.id, rating: ownRating)
    }

}

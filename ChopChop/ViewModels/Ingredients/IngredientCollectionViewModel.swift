import Combine
import Foundation

final class IngredientCollectionViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var filterByExpiryDate = false {
        didSet {
            expiryDateStart = Calendar.current.startOfDay(for: Date())
            expiryDateEnd = Calendar.current.startOfDay(for: Date())
        }
    }
    @Published var expiryDateStart = Calendar.current.startOfDay(for: Date())
    @Published var expiryDateEnd = Calendar.current.startOfDay(for: Date())
    @Published private(set) var ingredients: [IngredientInfo] = []

    let title: String
    let categoryIds: [Int64]

    private let storageManager = StorageManager()
    private var ingredientsCancellable: AnyCancellable?

    init(title: String, categoryIds: [Int64] = []) {
        self.title = title
        self.categoryIds = categoryIds

        ingredientsCancellable = ingredientsPublisher()
            .sink { [weak self] ingredients in
                self?.ingredients = ingredients
            }
    }

    private func ingredientsPublisher() -> AnyPublisher<[IngredientInfo], Never> {
        // swiftlint:disable line_length
        $query.combineLatest($filterByExpiryDate, $expiryDateStart, $expiryDateEnd).map { [self] query, filterByExpiryDate, expiryDateStart, expiryDateEnd
            -> AnyPublisher<[IngredientInfo], Error> in
            storageManager.ingredientsPublisher(query: query,
                                                categoryIds: categoryIds,
                                                expiresAfter: filterByExpiryDate ? expiryDateStart : .distantPast,
                                                expiresBefore: filterByExpiryDate ? expiryDateEnd : .distantFuture)
        }
        .map { ingredientsPublisher in
            ingredientsPublisher.catch { _ in
                Just<[IngredientInfo]>([])
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
        // swiftlint:enable line_length
    }
}

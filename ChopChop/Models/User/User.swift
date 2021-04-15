import Foundation

struct User: Identifiable, CachableEntity {
    let id: String
    let name: String
    let followees: [String]
    let ratings: [UserRating]
    let createdAt: Date
    let updatedAt: Date

    init(id: String, name: String, followees: [String], ratings: [UserRating], createdAt: Date, updatedAt: Date) throws {
        self.id = id
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw UserError.emptyName
        }
        self.name = trimmedName

        self.followees = followees
        self.ratings = ratings
        self.followees = followees
        self.ratings = ratings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

}

enum UserError: Error {
    case emptyName
}

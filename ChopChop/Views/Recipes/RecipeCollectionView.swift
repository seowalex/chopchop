import SwiftUI

struct RecipeCollectionView: View {
    @ObservedObject var viewModel: RecipeCollectionViewModel
    @State private var showingPopover = false

    var body: some View {
        VStack {
            SearchBar(text: $viewModel.query, placeholder: "Search recipes...")
            Button(action: {
                showingPopover = true
            }) {
                if viewModel.selectedIngredients.isEmpty {
                    Text("Filter by ingredients...")
                } else {
                    Text(viewModel.selectedIngredients.joined(separator: ", "))
                }
            }
            .popover(isPresented: $showingPopover) {
                List(Array(viewModel.ingredients.keys), id: \.self) { ingredient in
                    Button(action: {
                        if viewModel.selectedIngredients.contains(ingredient) {
                            viewModel.selectedIngredients.remove(ingredient)
                        } else {
                            viewModel.selectedIngredients.insert(ingredient)
                        }
                    }) {
                        HStack {
                            Text(ingredient)
                            Spacer()

                            if viewModel.selectedIngredients.contains(ingredient) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .frame(width: 200, height: 200)
            }
            List(viewModel.recipes) { recipe in
                NavigationLink(
                    destination: Text(recipe.name)
                ) {
                    HStack(alignment: .top) {
                        Image("recipe")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                            .clipped()
                        VStack(alignment: .leading) {
                            Text(recipe.name)
                            Text("Absolutely delish")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding([.top, .bottom], 8)
                }
            }
        }
        .navigationTitle(Text(viewModel.category.name))
        .onDisappear {
            viewModel.query = ""
        }
    }
}

struct RecipeCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeCollectionView(viewModel: RecipeCollectionViewModel(category: RecipeCategory(name: "")))
    }
}

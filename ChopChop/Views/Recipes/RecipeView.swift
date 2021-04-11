import SwiftUI

struct RecipeView: View {
    @ObservedObject var viewModel: RecipeViewModel
    @EnvironmentObject var settings: UserSettings
    var body: some View {
        ScrollView {
            VStack {
                if viewModel.image == UIImage() {
                    defaultRecipeBanner
                } else {
                    recipeBanner
                }
                recipeDetails
            }
            Button(action: {
                viewModel.publish()
            }) {
                Label(viewModel.isPublished ? "Publish changes": "Publish", systemImage: "paperplane")
            }
        }
        .background(
            NavigationLink(
                destination: RecipeFormView(
                    viewModel: RecipeFormViewModel(
                        recipe: viewModel.recipe
                    )
                ),
                isActive: $viewModel.isShowingForm
            ) {
                EmptyView()
            }
        )
        .navigationTitle(viewModel.recipeName)
        .toolbar {
            Button(action: { viewModel.isShowingForm = true }) {
                Image(systemName: "square.and.pencil")
            }
        }
        .onAppear {
            viewModel.isShowingForm = false
            viewModel.fetchParentRecipe()
        }
    }

    var recipeDetails: some View {
        VStack(alignment: .center) {
            if let parentRecipe = viewModel.parentRecipe {
                NavigationLink(
                    destination: OnlineRecipeByUserView(
                        viewModel: OnlineRecipeByUserViewModel(
                            recipe: parentRecipe,
                            downloadRecipeViewModel: DownloadRecipeViewModel(),
                            settings: settings
                        )
                    )
                ) {
                    Text("Adapted from here")
                }
            } else {
                Text("Test")
            }
            Text("General").font(.title).underline()
            general
            Spacer()
            Text("Ingredients").font(.title).underline()
            ingredient
            Spacer()
            Text("Instructions").font(.title).underline()
            instruction
        }
        .padding()
    }

    var defaultRecipeBanner: some View {
        Image("recipe")
            .resizable()
            .scaledToFill()
            .frame(height: 300)
            .clipped()
            .overlay(
                Rectangle()
                    .foregroundColor(.clear)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .clear, .black]),
                            startPoint: .top,
                            endPoint: .bottom))
            )
    }

    var general: some View {
        VStack {
            Text("Serves \(viewModel.serving.removeZerosFromEnd()) \(viewModel.serving == 1 ? "person" : "people")")
            HStack {
                Text("Difficulty: ")
                DifficultyView(difficulty: viewModel.difficulty)
            }
            HStack {
                Text("Cuisine: ")
                Text(viewModel.recipeCategory.isEmpty ? "Unspecified" : viewModel.recipeCategory)
            }
            Text("Time taken: \(viewModel.totalTimeTaken)")
        }.font(.body)
    }

    var ingredient: some View {
        VStack(alignment: .center) {
            ForEach(viewModel.ingredients, id: \.self) { ingredient in
                Text(ingredient.description)
            }
        }.font(.body)
    }

    var instruction: some View {
        VStack(alignment: .leading) {
            ForEach(0..<viewModel.stepGraph.nodes.count, id: \.self) { idx in
                HStack(alignment: .top) {
                    Text("Step \(idx + 1):")
                        .bold()
                    Text(viewModel.stepGraph.topologicallySortedNodes[idx].label.content)
                }
            }
            HStack {
                Spacer()
                NavigationLink(destination: EditorGraphView(viewModel: EditorGraphViewModel(graph: viewModel.stepGraph,
                                                                                            isEditable: false))) {
                    Label("Detailed instruction view", systemImage: "rectangle.expand.vertical")
                }
                .padding()
                Spacer()
            }
        }.font(.body)
    }

    var recipeBanner: some View {
        Image(uiImage: viewModel.image)
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .clipped()
                .overlay(
                    Rectangle()
                        .foregroundColor(.clear)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .clear, .black]),
                                startPoint: .top,
                                endPoint: .bottom))
                )
    }
}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        // swiftlint:disable force_try
        RecipeView(viewModel: RecipeViewModel(recipe: try! Recipe(name: "Test"), settings: UserSettings()))
    }
}

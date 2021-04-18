import SwiftUI

struct RecipeStepTimerRowView: View {
    @ObservedObject var viewModel: RecipeStepTimerRowViewModel

    var body: some View {
        HStack {
            HStack {
                TextField("Hours", text: Binding(get: { viewModel.hours },
                                                 set: viewModel.setHours))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                Text("h")
            }
            .frame(width: 60)
            .padding(.trailing)
            HStack {
                TextField("Minutes", text: Binding(get: { viewModel.minutes },
                                                   set: viewModel.setMinutes))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                Text("m")
            }
            .frame(width: 60)
            .padding(.trailing)
            HStack {
                TextField("Seconds", text: Binding(get: { viewModel.seconds },
                                                   set: viewModel.setSeconds))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                Text("s")
            }
            .frame(width: 60)
        }
    }
}

struct RecipeStepTimerRowView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeStepTimerRowView(viewModel: RecipeStepTimerRowViewModel())
    }
}

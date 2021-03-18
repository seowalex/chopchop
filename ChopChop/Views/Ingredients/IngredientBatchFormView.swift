import SwiftUI

struct IngredientBatchFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: IngredientBatchFormViewModel

    var body: some View {
        Form {
            quantitySection
            expiryDateSection
            saveButton
        }
    }

    var quantitySection: some View {
        Section(header: Text("QUANTITY")) {
            // TODO: integrate quantity units
            let units = ["ml", "l"]
            HStack {
                TextField("Quantity", text: $viewModel.inputQuantity)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                Text(viewModel.selectedUnit)
                Spacer()
                Picker("Unit", selection: $viewModel.selectedUnit) {
                    ForEach(units, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }

    var expiryDateSection: some View {
        Section(header: Text("EXPIRY DATE")) {
            Toggle(isOn: $viewModel.expiryDateEnabled) {
                Text("Expires")
            }
            if viewModel.expiryDateEnabled {
                DatePicker(
                    "Expiry Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date])
            }
        }
    }

    var saveButton: some View {
        Button(action: save) {
            Text("Save")
                .foregroundColor(viewModel.areFieldsValid ? .blue : .gray)
        }
        .disabled(!viewModel.areFieldsValid)
    }

    func save() {
        defer {
            presentationMode.wrappedValue.dismiss()
        }

        do {
            try viewModel.save()
        } catch {
            return
        }
    }
}

struct IngredientBatchEditView_Previews: PreviewProvider {
    // swiftlint:disable force_try
    static var previews: some View {
        IngredientBatchFormView(
            viewModel: IngredientBatchFormViewModel(
                edit: IngredientBatch(
                    quantity: try! Quantity(.count, value: 3),
                    expiryDate: Date().addingTimeInterval(100_000))))
    }
}

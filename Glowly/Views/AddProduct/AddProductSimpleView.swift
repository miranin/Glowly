//
//  AddProductSimpleView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

struct AddProductSimpleView: View {
    @ObservedObject var productStore: ProductStore
    @State private var name = ""
    @State private var brand = ""
    @State private var category: ProductCategory = .foundation
    @State private var purchaseDate = Date()
    @State private var isSensitiveSafe = false
    @State private var isAcneSafe = true
    @State private var notes = ""
    @State private var isSaving = false
    // Photo/AI handled in AddEntryChooserView

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основное")) {
                    TextField("Название", text: $name)
                    TextField("Бренд", text: $brand)
                    Picker("Категория", selection: $category) {
                        ForEach(ProductCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                }
                // Photo-related actions moved to AddEntryChooserView (action sheet)
                Section(header: Text("Даты")) {
                    DatePicker("Покупка", selection: $purchaseDate, displayedComponents: .date)
                }
                Section(header: Text("Персонализация")) {
                    Toggle("Для чувствительной кожи", isOn: $isSensitiveSafe)
                    Toggle("Acne-safe", isOn: $isAcneSafe)
                }
                Section(header: Text("Заметки")) {
                    TextField("Текст", text: $notes, axis: .vertical)
                }
                Section {
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView() } else { Text("Сохранить") }
                    }
                    .disabled(name.isEmpty || brand.isEmpty || isSaving)
                }
            }
            .navigationTitle("Добавить")
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        let product = Product(
            name: name,
            brand: brand,
            category: category,
            applicationZone: .face, // Default zone, can be made configurable later
            purchaseDate: purchaseDate,
            barcode: nil,
            imageData: nil,
            notes: notes,
            isActive: true,
            isSensitiveSafe: isSensitiveSafe,
            isAcneSafe: isAcneSafe
        )
        productStore.addProduct(product)
        name = ""; brand = ""; notes = ""
        isSaving = false
    }

    // No photo/AI here
}

#Preview {
    AddProductSimpleView(productStore: ProductStore())
}



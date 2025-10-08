//
//  ProductConfirmationView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ProductConfirmationView: View {
    @ObservedObject var productStore: ProductStore
    let analysis: ProductAnalysis
    let image: UIImage?
    let onConfirmed: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var brand: String
    @State private var selectedCategory: ProductCategory
    @State private var purchaseDate = Date()
    @State private var expiryDate = Date()
    @State private var hasExpiryDate = true
    @State private var notes: String
    @State private var shade: String
    @State private var ingredients = ""
    @State private var howToUse = ""
    @State private var benefits = ""
    @State private var warnings = ""
    @State private var isSensitiveSafe = false
    @State private var isAcneSafe = true
    @State private var isSaving = false
    @State private var showingSuccessAlert = false
    
    init(productStore: ProductStore, analysis: ProductAnalysis, image: UIImage?, onConfirmed: @escaping () -> Void) {
        self.productStore = productStore
        self.analysis = analysis
        self.image = image
        self.onConfirmed = onConfirmed
        
        // Initialize state with analysis data
        self._name = State(initialValue: analysis.productName.isEmpty ? "Новый продукт" : analysis.productName)
        self._brand = State(initialValue: analysis.brand.isEmpty ? "Неизвестный бренд" : analysis.brand)
        self._selectedCategory = State(initialValue: analysis.category)
        self._notes = State(initialValue: "")
        self._shade = State(initialValue: analysis.shade)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Подтвердите данные")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Проверьте и отредактируйте информацию о продукте")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Image Preview
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                    
                    // Editable Fields
                    VStack(spacing: 20) {
                        // Product Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Название продукта")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Введите название", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Brand
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Бренд")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Введите бренд", text: $brand)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Категория")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Menu {
                                ForEach(ProductCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        if hasExpiryDate {
                                            expiryDate = Calendar.current.date(byAdding: .day, value: category.suggestedShelfLifeDays, to: purchaseDate) ?? purchaseDate
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: category.icon)
                                            Text(category.rawValue)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedCategory.icon)
                                        .foregroundColor(.pink)
                                    
                                    Text(selectedCategory.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        
                        // Shade (if available)
                        if !shade.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Оттенок")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Введите оттенок", text: $shade)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        
                        // Purchase Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Дата покупки")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .onChange(of: purchaseDate) { _ in
                                    if hasExpiryDate {
                                        expiryDate = Calendar.current.date(byAdding: .day, value: selectedCategory.suggestedShelfLifeDays, to: purchaseDate) ?? purchaseDate
                                    }
                                }
                        }
                        
                        // Expiry Date
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Срок годности")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $hasExpiryDate)
                                    .toggleStyle(SwitchToggleStyle(tint: .pink))
                            }
                            
                            if hasExpiryDate {
                                DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }

                        // Personalization tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Персонализация")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Toggle(isOn: $isSensitiveSafe) {
                                Text("Подходит для чувствительной кожи")
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .pink))
                            Toggle(isOn: $isAcneSafe) {
                                Text("Acne-safe")
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .pink))
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Заметки")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Дополнительная информация", text: $notes, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(2...4)
                        }
                        
                        // Divider
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Detailed Information Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Theme.info)
                                Text("Детальная информация")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("AI будет заполнять эти поля автоматически")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // How to Use
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Как использовать", systemImage: "hand.raised.fill")
                                .font(.headline)
                                .foregroundColor(Theme.info)
                            
                            TextField("Инструкция по применению", text: $howToUse, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Польза", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(Theme.success)
                            
                            TextField("Преимущества (через запятую)", text: $benefits, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(2...4)
                            
                            Text("Пример: Увлажняет кожу, Выравнивает тон")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Warnings
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Предупреждения", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(Theme.warning)
                            
                            TextField("Меры предосторожности (через запятую)", text: $warnings, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(2...4)
                            
                            Text("Пример: Избегайте попадания в глаза")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Состав", systemImage: "flask.fill")
                                .font(.headline)
                                .foregroundColor(Theme.accent)
                            
                            TextField("Список ингредиентов", text: $ingredients, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(3...8)
                            
                            Text("Пример: Aqua, Glycerin, Niacinamide...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProduct) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Сохранение...")
                            }
                        } else {
                            Text("Сохранить")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || brand.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveProduct() {
        guard !isSaving else { return }
        
        isSaving = true
        
        // Simulate a small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var product = Product(
                name: self.name,
                brand: self.brand,
                category: self.selectedCategory,
                purchaseDate: self.purchaseDate,
                expiryDate: self.hasExpiryDate ? self.expiryDate : nil,
                barcode: nil,
                imageData: self.image?.jpegData(compressionQuality: 0.8),
                notes: self.notes.isEmpty ? "" : self.notes,
                isActive: true,
                isSensitiveSafe: self.isSensitiveSafe,
                isAcneSafe: self.isAcneSafe
            )
            
            // Add detailed information
            product.ingredients = self.ingredients
            product.howToUse = self.howToUse
            product.benefits = self.benefits.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            product.warnings = self.warnings.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            self.productStore.addProduct(product)
            self.isSaving = false
            // Inform parent and dismiss
            self.onConfirmed()
            self.dismiss()
        }
    }
}

#Preview {
    ProductConfirmationView(
        productStore: ProductStore(),
        analysis: ProductAnalysis(
            brand: "L'Oréal",
            productName: "True Match Foundation",
            category: .foundation,
            shade: "W3",
            confidence: 0.85,
            rawText: "L'Oréal True Match Foundation W3"
        ),
        image: nil,
        onConfirmed: {}
    )
}

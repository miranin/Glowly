//
//  AddProductView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct AddProductView: View {
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var brand = ""
    @State private var selectedCategory = ProductCategory.foundation
    @State private var purchaseDate = Date()
    @State private var barcode = ""
    @State private var notes = ""
    @State private var ingredients = ""
    @State private var howToUse = ""
    @State private var benefits: String = ""
    @State private var warnings: String = ""
    @State private var isSensitiveSafe = false
    @State private var isAcneSafe = true
    @State private var showingBarcodeScanner = false
    @State private var isSaving = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)
                        
                        Text("Добавить продукт")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Заполни информацию о новом продукте")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Product Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Название продукта")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Например: Тональный крем", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Brand
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Бренд")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Например: L'Oréal", text: $brand)
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
                        
                        // Barcode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Штрихкод (опционально)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                TextField("Введите штрихкод", text: $barcode)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button(action: { showingBarcodeScanner = true }) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.title2)
                                        .foregroundColor(.pink)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.pink.opacity(0.1))
                                        )
                                }
                            }
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
                            Text("Эти поля будут заполнены AI автоматически в будущем")
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
                            
                            Text("Пример: Увлажняет кожу, Выравнивает тон, Придает сияние")
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
                            
                            Text("Пример: Избегайте попадания в глаза, Хранить в прохладном месте")
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
                            
                            Text("Пример: Aqua, Glycerin, Niacinamide, Ceramides...")
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
            .dismissKeyboardOnTap()
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(barcode: $barcode)
            }
            .alert("Продукт добавлен!", isPresented: $showingSuccessAlert) {
                Button("Отлично!") {
                    dismiss()
                }
            } message: {
                Text("\(name) от \(brand) успешно добавлен в вашу косметичку!")
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
                applicationZone: .face, // Default zone, can be made configurable later
                purchaseDate: self.purchaseDate,
                barcode: self.barcode.isEmpty ? nil : self.barcode,
                imageData: nil,
                notes: self.notes,
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
            self.showingSuccessAlert = true
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
    }
}

struct BarcodeScannerView: View {
    @Binding var barcode: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                Text("Сканирование штрихкода")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Наведите камеру на штрихкод продукта")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder for actual barcode scanning
                // In a real app, you would integrate with AVFoundation
                VStack(spacing: 12) {
                    TextField("Введите штрихкод вручную", text: $barcode)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Button("Использовать тестовый код") {
                        barcode = "1234567890123"
                    }
                    .foregroundColor(.pink)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .dismissKeyboardOnTap()
        }
    }
}

#Preview {
    AddProductView(productStore: ProductStore())
}

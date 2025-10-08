//
//  BagListView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

struct BagListView: View {
    @ObservedObject var productStore: ProductStore
    @State private var selectedProduct: Product?
    @State private var selectedCategory: CosmeticCategory? = nil
    @State private var selectedSubcategory: ProductCategory? = nil
    @State private var showingAddProduct = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    categoryGrid
                    if let category = selectedCategory {
                        categoryProductsView(for: category)
                    } else {
                        allProductsView
                    }
                }
                .padding(20)
            }
            .navigationTitle("Косметичка")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: productStore.shareExportURL())
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSimpleSheet(product: product, productStore: productStore)
            }
            .sheet(isPresented: $showingAddProduct) {
                AddEntryChooserView(productStore: productStore)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Твоя косметичка")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(activeProductsCount) активных продуктов")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if let expiringCount = expiringProductsCount, expiringCount > 0 {
                    VStack(spacing: 4) {
                        Text("\(expiringCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("скоро истекает")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(CosmeticCategory.allCases, id: \.self) { category in
                CosmeticCategoryCard(
                    category: category,
                    productCount: productsForCategory(category).count,
                    isSelected: selectedCategory == category
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
        }
    }

    private func categoryProductsView(for category: CosmeticCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Все") {
                    selectedCategory = nil
                    selectedSubcategory = nil
                }
                .font(.caption)
                .foregroundColor(Theme.accent)
            }
            
            // Subcategory filter chips
            subcategoryFilterView(for: category)
            
            let products = filteredProductsForCategory(category)
            if products.isEmpty {
                EmptyCategoryView(category: category) {
                    showingAddProduct = true
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(products) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            ProductCard(
                                product: product,
                                productStore: productStore
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(category.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(category.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func subcategoryFilterView(for category: CosmeticCategory) -> some View {
        let subcategories = category.matchingCategories.filter { subcategory in
            activeProducts.contains { $0.category == subcategory }
        }
        
        if subcategories.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    SubcategoryChip(
                        title: "Все",
                        isSelected: selectedSubcategory == nil,
                        color: category.color
                    ) {
                        selectedSubcategory = nil
                    }
                    
                    ForEach(subcategories, id: \.self) { subcategory in
                        SubcategoryChip(
                            title: subcategory.rawValue,
                            isSelected: selectedSubcategory == subcategory,
                            color: category.color
                        ) {
                            selectedSubcategory = subcategory
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        )
    }

    private var allProductsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Все продукты")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(activeProductsCount) шт.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if activeProducts.isEmpty {
                EmptyBagView {
                    showingAddProduct = true
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activeProducts) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            ProductCard(
                                product: product,
                                productStore: productStore
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var activeProducts: [Product] {
        productStore.products.filter { $0.isActive }
    }

    private var activeProductsCount: Int {
        activeProducts.count
    }

    private var expiringProductsCount: Int? {
        let expiring = productStore.getExpiringProducts().count
        return expiring > 0 ? expiring : nil
    }

    private func productsForCategory(_ category: CosmeticCategory) -> [Product] {
        activeProducts.filter { product in
            category.matchingCategories.contains(product.category)
        }
    }
    
    private func filteredProductsForCategory(_ category: CosmeticCategory) -> [Product] {
        let categoryProducts = productsForCategory(category)
        
        if let selectedSubcategory = selectedSubcategory {
            return categoryProducts.filter { $0.category == selectedSubcategory }
        }
        
        return categoryProducts
    }
}

enum CosmeticCategory: CaseIterable {
    case facialSkincare
    case makeup
    case hairCare
    case bodyCare
    
    var title: String {
        switch self {
        case .facialSkincare: return "Уход за лицом"
        case .makeup: return "Макияж"
        case .hairCare: return "Волосы"
        case .bodyCare: return "Тело"
        }
    }
    
    var icon: String {
        switch self {
        case .facialSkincare: return "face.smiling"
        case .makeup: return "paintbrush.pointed"
        case .hairCare: return "hair"
        case .bodyCare: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .facialSkincare: return Color(red: 0.85, green: 0.33, blue: 0.52) // rose
        case .makeup: return Color(red: 0.95, green: 0.62, blue: 0.10) // orange
        case .hairCare: return Color(red: 0.40, green: 0.30, blue: 0.45) // mauve
        case .bodyCare: return Color(red: 0.14, green: 0.66, blue: 0.40) // green
        }
    }
    
    var matchingCategories: [ProductCategory] {
        switch self {
        case .facialSkincare:
            return [.cleanser, .moisturizer, .serum, .sunscreen, .mask, .primer]
        case .makeup:
            return [.foundation, .concealer, .powder, .blush, .bronzer, .highlighter, 
                   .eyeshadow, .eyeliner, .mascara, .lipstick, .lipGloss, .lipLiner, 
                   .settingSpray]
        case .hairCare:
            return [.other] // Hair products would be in "other" for now
        case .bodyCare:
            return [.other] // Body products would be in "other" for now
        }
    }
}

struct CosmeticCategoryCard: View {
    let category: CosmeticCategory
    let productCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.2), category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                }
                
                VStack(spacing: 4) {
                    Text(category.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(productCount) продуктов")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, height: 120) // Fixed size for all cards
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.1) : Theme.neutralLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: isSelected ? category.color.opacity(0.2) : Color.black.opacity(0.03),
                        radius: isSelected ? 6 : 3,
                        x: 0,
                        y: isSelected ? 3 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct EmptyCategoryView: View {
    let category: CosmeticCategory
    let onAddProduct: () -> Void
    
    var body: some View {
        Button(action: onAddProduct) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.2), category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(category.color)
                }
                
                VStack(spacing: 8) {
                    Text("Добавь продукты для \(category.title.lowercased())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Нажми, чтобы добавить")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(category.color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(category.color.opacity(0.2), lineWidth: 1, antialiased: true)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyBagView: View {
    let onAddProduct: () -> Void
    
    var body: some View {
        Button(action: onAddProduct) {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.2), Theme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.accent)
                }
                
                VStack(spacing: 12) {
                    Text("Твоя косметичка пуста")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Добавь свой первый продукт,\nчтобы начать пользоваться AI-помощником")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Нажми, чтобы добавить")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.accent.opacity(0.1))
                        )
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.accent.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1, antialiased: true)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubcategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BagListView(productStore: ProductStore())
}



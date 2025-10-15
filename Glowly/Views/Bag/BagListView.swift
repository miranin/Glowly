//
//  BagListView.swift
//  Glowly
//
//  Redesigned on 10/10/25.
//

import SwiftUI

struct BagListView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedProduct: Product?
    @State private var selectedCategory: ProductCategory? = nil
    @State private var searchText = ""
    @State private var showingAddProduct = false
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userProfilePresenter.userProfile.name ?? "Вика"
        
        let greetingKey: String
        switch hour {
        case 0..<6: greetingKey = "bag_greeting_evening"
        case 6..<12: greetingKey = "bag_greeting_morning"
        case 12..<18: greetingKey = "bag_greeting_afternoon"
        default: greetingKey = "bag_greeting_evening"
        }
        
        return "\(languageManager.translate(greetingKey)) \(name)!"
    }
    
    private var filteredProducts: [Product] {
        let products = selectedCategory != nil ? productsForCategory(selectedCategory!) : productStore.products
        
        if searchText.isEmpty {
            return products
        }
        
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header с приветствием и notification
                    headerSection
                    
                    // Search Bar
                    searchBar
                    
                    // Horizontal Categories
                    categoriesScrollView
                    
                    // Products Grid
                    productsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Tab bar padding
            }
            .background(Color(.systemGray6).opacity(0.3)) // Light gray background like Figma
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddProduct) {
            AddEntryChooserView(productStore: productStore)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSimpleSheet(product: product, productStore: productStore)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
            HStack {
            Text(greeting)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.primary)
            
                Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            TextField(languageManager.translate("bag_search"), text: $searchText)
                .font(.system(size: 16, weight: .regular))
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Categories Scroll View
    private var categoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Products
                categoryChip(
                    title: languageManager.translate("bag_all_products"),
                    count: productStore.products.count,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // Categories
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    let count = productsForCategory(category).count
                    if count > 0 {
                        categoryChip(
                            title: category.localizedName(languageManager: languageManager),
                            count: count,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func categoryChip(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                
                Text("(\(count))")
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.accent : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        LazyVStack(spacing: 12) {
            // Add Product Card
            addProductCard
            
            // Products
            if filteredProducts.isEmpty && !searchText.isEmpty {
                emptySearchView
            } else {
                ForEach(filteredProducts) { product in
                    productCard(product)
                }
            }
        }
    }
    
    // MARK: - Add Product Card
    private var addProductCard: some View {
        Button {
            showingAddProduct = true
        } label: {
            HStack(spacing: 12) {
                // Plus Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.translate("bag_add_product"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(languageManager.translate("bag_add_new"))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(6)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Product Card
    private func productCard(_ product: Product) -> some View {
        Button {
            selectedProduct = product
        } label: {
            HStack(spacing: 12) {
                // Product Image
                if let imageData = product.imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        )
                }
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    // Title: Product Name + Brand
                    Text("\(product.name) \(product.brand)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Subtitle: Brand
                    Text(product.brand)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    // Tags: Application Zone
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            tagBadge(product.applicationZone.localizedName(languageManager: languageManager))
                        }
                    }
                }
                
                Spacer()
                
                // 3-Dot Menu
                Menu {
                    Button {
                        // Edit
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        deleteProduct(product)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(90))
                        .padding(6)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Tag Badge
    private func tagBadge(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tagColor(tag))
            .cornerRadius(10)
    }
    
    private func tagColor(_ applicationZone: String) -> Color {
        // Яркие цвета для зон применения как на Figma дизайне
        let zoneLower = applicationZone.lowercased()
        
        // Application zone colors - яркие цвета
        if zoneLower.contains("лицо") || zoneLower.contains("face") { return Color(hex: "#FFB4A2") } // coral
        if zoneLower.contains("глаза") || zoneLower.contains("eyes") { return Color(hex: "#A7D8DE") } // cyan
        if zoneLower.contains("губы") || zoneLower.contains("lips") { return Color(hex: "#FF8FAB") } // pink
        if zoneLower.contains("щеки") || zoneLower.contains("cheeks") { return Color(hex: "#FFB6D9") } // light pink
        if zoneLower.contains("тело") || zoneLower.contains("body") { return Color(hex: "#B8E986") } // lime
        if zoneLower.contains("волосы") || zoneLower.contains("hair") { return Color(hex: "#D4A8FF") } // purple
        if zoneLower.contains("руки") || zoneLower.contains("hands") { return Color(hex: "#FFB86C") } // orange
        if zoneLower.contains("ноги") || zoneLower.contains("feet") { return Color(hex: "#E8B4E8") } // light purple
        if zoneLower.contains("ногти") || zoneLower.contains("nails") { return Color(hex: "#FFB4A2") } // coral
        if zoneLower.contains("шея") || zoneLower.contains("neck") { return Color(hex: "#A7D8DE") } // cyan
        if zoneLower.contains("декольте") || zoneLower.contains("décolletage") { return Color(hex: "#FFB6D9") } // light pink
        
        return Color(hex: "#C8C8C8") // default gray
    }
    
    // MARK: - Empty Search View
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Продукты не найдены")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Helper Methods
    private func productsForCategory(_ category: ProductCategory) -> [Product] {
        productStore.products.filter { $0.category == category }
    }
    
    // Функция больше не нужна, так как показываем только бренд
    
    private func daysRemaining(from date: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(0, days)
    }
    
    private func deleteProduct(_ product: Product) {
        productStore.deleteProduct(product)
    }
}

#Preview {
    BagListView(
        productStore: ProductStore(),
        userProfilePresenter: UserProfilePresenter()
    )
}


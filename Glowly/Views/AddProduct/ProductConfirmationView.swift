//
//  ProductConfirmationView.swift
//  Glowly
//

import SwiftUI

struct ProductConfirmationView: View {
    @ObservedObject var productStore: ProductStore
    let analysisResult: AnalyzedProductResult
    let image: UIImage?
    let onConfirmed: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var brand: String
    @State private var selectedCategory: ProductCategory
    @State private var purchaseDate = Date()
    @State private var notes: String = ""
    @State private var ingredients: String
    @State private var howToUse: String
    @State private var benefits: String
    @State private var warnings: String
    @State private var isSensitiveSafe: Bool
    @State private var isAcneSafe: Bool
    @State private var isSaving = false

    init(
        productStore: ProductStore,
        analysisResult: AnalyzedProductResult,
        image: UIImage?,
        onConfirmed: @escaping () -> Void
    ) {
        self.productStore = productStore
        self.analysisResult = analysisResult
        self.image = image
        self.onConfirmed = onConfirmed

        _name = State(initialValue: analysisResult.productName.isEmpty ? "Новый продукт" : analysisResult.productName)
        _brand = State(initialValue: analysisResult.brand.isEmpty ? "" : analysisResult.brand)
        _selectedCategory = State(initialValue: analysisResult.mappedCategory)
        // Editable raw-ingredients field: prefer the full INCI list, fall back to
        // ingredient names (with roles stripped) so the field stays readable.
        let rawIngredients = analysisResult.ingredientsRaw.isEmpty
            ? analysisResult.keyIngredients.map { $0.components(separatedBy: " — ").first ?? $0 }.joined(separator: ", ")
            : analysisResult.ingredientsRaw
        _ingredients = State(initialValue: rawIngredients)
        _howToUse = State(initialValue: analysisResult.howToUse)
        _benefits = State(initialValue: analysisResult.benefits.joined(separator: ", "))
        _warnings = State(initialValue: analysisResult.warnings.joined(separator: ", "))
        _isSensitiveSafe = State(initialValue: analysisResult.isSensitiveSafe)
        _isAcneSafe = State(initialValue: analysisResult.isAcneSafe)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Header ──
                    headerSection

                    // ── Image ──
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    // ── AI Summary ──
                    if !analysisResult.productDescription.isEmpty {
                        aiSummarySection
                    }

                    // ── Rich AI-extracted info (read-only) ──
                    aiInsightsSection

                    // ── Editable fields ──
                    VStack(spacing: 0) {
                        formSection("Основная информация") {
                            fieldGroup {
                                stackedField("Название продукта", placeholder: "Например: Dermaclear Cleansing Foam", text: $name)
                                Divider().padding(.leading, 16)
                                stackedField("Бренд", placeholder: "Например: Dr.Jart+", text: $brand)
                            }
                        }

                        formSection("Категория") {
                            fieldGroup {
                                Menu {
                                    ForEach(ProductCategory.allCases, id: \.self) { cat in
                                        Button(action: { selectedCategory = cat }) {
                                            Label(cat.rawValue, systemImage: cat.icon)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedCategory.icon)
                                            .foregroundColor(Theme.accent)
                                            .frame(width: 22)
                                        Text(selectedCategory.rawValue)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                }
                            }
                        }

                        formSection("Дата покупки") {
                            fieldGroup {
                                HStack {
                                    Text("Дата")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 16)
                                    Spacer()
                                    DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .padding(.trailing, 16)
                                        .padding(.vertical, 10)
                                }
                            }
                        }

                        formSection("Совместимость") {
                            fieldGroup {
                                Toggle(isOn: $isSensitiveSafe) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "leaf")
                                            .foregroundColor(.green)
                                            .frame(width: 22)
                                        Text("Для чувствительной кожи")
                                    }
                                    .padding(.leading, 16)
                                }
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                                .toggleStyle(SwitchToggleStyle(tint: .green))

                                Divider().padding(.leading, 16)

                                Toggle(isOn: $isAcneSafe) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.shield")
                                            .foregroundColor(.blue)
                                            .frame(width: 22)
                                        Text("Не комедогенный (acne-safe)")
                                    }
                                    .padding(.leading, 16)
                                }
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            }
                        }

                        formSection("Состав") {
                            fieldGroup {
                                TextEditor(text: $ingredients)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .overlay(alignment: .topLeading) {
                                        if ingredients.isEmpty {
                                            Text("Перечислите ингредиенты через запятую")
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.top, 16)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }

                        formSection("Как использовать") {
                            fieldGroup {
                                TextEditor(text: $howToUse)
                                    .frame(minHeight: 72)
                                    .padding(12)
                                    .overlay(alignment: .topLeading) {
                                        if howToUse.isEmpty {
                                            Text("Инструкция по применению")
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.top, 16)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }

                        formSection("Польза") {
                            fieldGroup {
                                TextEditor(text: $benefits)
                                    .frame(minHeight: 60)
                                    .padding(12)
                                    .overlay(alignment: .topLeading) {
                                        if benefits.isEmpty {
                                            Text("Увлажнение, выравнивание тона...")
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.top, 16)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }

                        formSection("Предупреждения") {
                            fieldGroup {
                                TextEditor(text: $warnings)
                                    .frame(minHeight: 60)
                                    .padding(12)
                                    .overlay(alignment: .topLeading) {
                                        if warnings.isEmpty {
                                            Text("Избегайте контакта с глазами...")
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.top, 16)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }

                        formSection("Заметки") {
                            fieldGroup {
                                TextEditor(text: $notes)
                                    .frame(minHeight: 60)
                                    .padding(12)
                                    .overlay(alignment: .topLeading) {
                                        if notes.isEmpty {
                                            Text("Личные заметки о продукте...")
                                                .foregroundColor(Color(.placeholderText))
                                                .padding(.top, 16)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProduct) {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Сохранить").fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    // MARK: - Sub-views

    private var isConfident: Bool { analysisResult.confidence >= 0.7 }

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((isConfident ? Color.green : Color.orange).opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: isConfident ? "checkmark.seal.fill" : "pencil.and.outline")
                    .font(.system(size: 24))
                    .foregroundColor(isConfident ? .green : .orange)
            }
            .padding(.top, 16)

            Text(isConfident ? "Продукт распознан" : "Проверьте данные")
                .font(.title3.weight(.bold))

            Text(isConfident
                 ? "AI определил продукт — отредактируйте при необходимости"
                 : "AI не уверен в распознавании. Заполните или исправьте поля ниже")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Confidence pill
            HStack(spacing: 5) {
                Image(systemName: "gauge.medium")
                    .font(.system(size: 11, weight: .semibold))
                Text("Точность \(Int(analysisResult.confidence * 100))%")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isConfident ? .green : .orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((isConfident ? Color.green : Color.orange).opacity(0.12))
            .clipShape(Capsule())
            .padding(.top, 2)
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
    }

    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                Text("AI Summary")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.accent)
            }
            Text(analysisResult.productDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - AI Insights (read-only rich info)

    @ViewBuilder
    private var aiInsightsSection: some View {
        VStack(spacing: 14) {
            // Usage time + safety badges row
            usageAndSafetyRow

            // Key ingredients with roles
            if !analysisResult.keyIngredients.isEmpty {
                insightCard(icon: "leaf.fill", title: "Активные ингредиенты", tint: Theme.success) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(analysisResult.keyIngredients, id: \.self) { ing in
                            ingredientRow(ing)
                        }
                    }
                }
            }

            // Skin types
            if !analysisResult.skinTypes.isEmpty {
                insightCard(icon: "person.fill", title: "Подходит для", tint: Theme.info) {
                    chipFlow(analysisResult.skinTypes.map { skinTypeLabel($0) }, tint: Theme.info)
                }
            }

            // Concerns targeted
            if !analysisResult.detectedConcerns.isEmpty {
                insightCard(icon: "target", title: "Решает проблемы", tint: Theme.accent) {
                    chipFlow(analysisResult.detectedConcerns.map { concernLabel($0) }, tint: Theme.accent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var usageAndSafetyRow: some View {
        HStack(spacing: 10) {
            badge(icon: usageIcon, text: usageLabel, tint: Theme.accent)
            if analysisResult.isSensitiveSafe {
                badge(icon: "leaf", text: "Для чувств. кожи", tint: Theme.success)
            }
            badge(
                icon: analysisResult.isAcneSafe ? "checkmark.shield" : "exclamationmark.shield",
                text: analysisResult.isAcneSafe ? "Acne-safe" : "Комедогенно",
                tint: analysisResult.isAcneSafe ? Theme.info : Theme.warning
            )
            Spacer(minLength: 0)
        }
    }

    private func badge(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func insightCard<Content: View>(
        icon: String, title: String, tint: Color, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func ingredientRow(_ raw: String) -> some View {
        let parts = raw.components(separatedBy: " — ")
        let name = parts.first ?? raw
        let role = parts.count > 1 ? parts.dropFirst().joined(separator: " — ") : ""
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.success.opacity(0.5))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                if !role.isEmpty {
                    Text(role)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func chipFlow(_ items: [String], tint: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tint)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Label helpers

    private var usageLabel: String {
        switch analysisResult.usageTime.lowercased() {
        case "morning": return "Утром"
        case "night": return "Вечером"
        default: return "Утро и вечер"
        }
    }

    private var usageIcon: String {
        switch analysisResult.usageTime.lowercased() {
        case "morning": return "sun.max.fill"
        case "night": return "moon.fill"
        default: return "sun.and.horizon.fill"
        }
    }

    private func skinTypeLabel(_ key: String) -> String {
        switch key.lowercased() {
        case "oily": return "Жирная"
        case "dry": return "Сухая"
        case "combination": return "Комбинированная"
        case "sensitive": return "Чувствительная"
        case "normal": return "Нормальная"
        case "all": return "Все типы"
        case "acne_prone", "acne": return "Склонная к акне"
        case "mature": return "Зрелая"
        default: return key.capitalized
        }
    }

    private func concernLabel(_ key: String) -> String {
        switch key.lowercased() {
        case "acne": return "Акне"
        case "aging": return "Старение"
        case "dryness": return "Сухость"
        case "hyperpigmentation": return "Пигментация"
        case "pores": return "Поры"
        case "redness": return "Покраснения"
        case "sensitivity": return "Чувствительность"
        case "brightening": return "Сияние"
        case "firmness": return "Упругость"
        case "dark_circles": return "Тёмные круги"
        default: return key.capitalized
        }
    }

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            content()
        }
    }

    private func fieldGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(minWidth: 110, alignment: .leading)
                .padding(.leading, 16)
            content()
                .padding(.trailing, 16)
        }
        .padding(.vertical, 13)
    }

    /// Cleaner label-above-input field (replaces the cramped inline layout).
    private func stackedField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .submitLabel(.next)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Save

    private func saveProduct() {
        guard !isSaving else { return }
        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var product = Product(
                name: self.name,
                brand: self.brand.isEmpty ? "Неизвестный бренд" : self.brand,
                category: self.selectedCategory,
                applicationZone: .face,
                purchaseDate: self.purchaseDate,
                barcode: nil,
                imageData: self.image?.jpegData(compressionQuality: 0.75),
                notes: self.notes,
                isActive: true,
                isSensitiveSafe: self.isSensitiveSafe,
                isAcneSafe: self.isAcneSafe
            )
            product.ingredients = self.ingredients
            product.howToUse = self.howToUse
            product.benefits = self.benefits
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            product.warnings = self.warnings
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            // Persist AI-extracted rich info for the detail view
            product.productDescription = self.analysisResult.productDescription
            product.keyIngredients = self.analysisResult.keyIngredients
            product.skinTypes = self.analysisResult.skinTypes
            product.concerns = self.analysisResult.detectedConcerns
            product.usageTime = self.analysisResult.usageTime

            self.productStore.addProduct(product)
            self.isSaving = false
            self.onConfirmed()
            self.dismiss()
        }
    }
}

#Preview {
    ProductConfirmationView(
        productStore: ProductStore(),
        analysisResult: AnalyzedProductResult(
            brand: "Dr.Jart+",
            productName: "Dermaclear Microfoam Cleansing Foam",
            category: "cleanser",
            applicationZone: "face",
            productDescription: "A gentle foaming cleanser that deeply purifies pores while maintaining the skin's moisture balance. Suitable for all skin types.",
            keyIngredients: ["Centella Asiatica", "Glycerin", "Niacinamide"],
            ingredients: ["Centella Asiatica", "Glycerin", "Niacinamide"],
            ingredientsRaw: "",
            skinTypes: ["all", "sensitive"],
            detectedConcerns: ["sensitivity", "pores"],
            usageTime: "both",
            howToUse: "Apply to damp skin, massage gently, rinse thoroughly.",
            benefits: ["Deep cleansing", "Gentle on skin", "Maintains moisture"],
            warnings: ["Avoid contact with eyes"],
            isSensitiveSafe: true,
            isAcneSafe: true,
            confidence: 0.87,
            needsConfirmation: false,
            reasoning: "Dr.Jart+ identified from red cross logo and Korean-style packaging.",
            dataSource: "web",
            sourceUrl: "https://incidecoder.com/products/dr-jart-dermaclear-micro-foam-cleanser",
            ocrText: "",
            aiRawDescription: ""
        ),
        image: nil,
        onConfirmed: {}
    )
}

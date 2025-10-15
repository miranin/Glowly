//
//  ProductStore.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import Foundation
import SwiftUI

struct CosmeticBagExport: Codable {
    let version: String
    let appName: String
    let exportDate: Date
    let products: [Product]
    let metadata: ExportMetadata
}

struct ExportMetadata: Codable {
    let totalProducts: Int
    let categories: [ProductCategory]
    let exportType: String
}

class ProductStore: ObservableObject {
    @Published var products: [Product] = []
    
    private let userDefaults = UserDefaults.standard
    private let productsKey = "SavedProducts"
    private let notificationService = NotificationService.shared
    
    init() {
        // TEMPORARY: Clear products to load corrected ones matching actual images
        userDefaults.removeObject(forKey: productsKey)
        
        loadProducts()
        setupNotifications()
        
        // Add sample products for demo if empty
        if products.isEmpty {
            addSampleProducts()
        }
    }
    
    func addProduct(_ product: Product) {
        products.append(product)
        saveProducts()
        updateNotifications()
    }
    
    func updateProduct(_ product: Product) {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
            saveProducts()
            updateNotifications()
        }
    }
    
    func deleteProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
        saveProducts()
        updateNotifications()
    }

    func markProductUsed(_ product: Product) {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index].isActive = false
            saveProducts()
            updateNotifications()
        }
    }
    
    func getExpiringProducts() -> [Product] {
        return [] // No expiry functionality
    }
    
    func getExpiredProducts() -> [Product] {
        return [] // No expiry functionality
    }
    
    func getProductsByCategory(_ category: ProductCategory) -> [Product] {
        return products.filter { $0.category == category && $0.isActive }
    }
    
    private func saveProducts() {
        if let encoded = try? JSONEncoder().encode(products) {
            userDefaults.set(encoded, forKey: productsKey)
        }
    }
    
    private func loadProducts() {
        if let data = userDefaults.data(forKey: productsKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            products = decoded
        }
    }
    
    private func setupNotifications() {
        notificationService.requestPermission()
        notificationService.scheduleDailyRoutineReminder()
        notificationService.scheduleEveningRoutineReminder()
    }
    
    private func updateNotifications() {
        notificationService.scheduleExpiryReminders(for: products)
    }

    // Export cosmetic bag as JSON to a temporary file URL for sharing
    func shareExportURL() -> URL {
        let exportData = CosmeticBagExport(
            version: "1.0",
            appName: "Glowly",
            exportDate: Date(),
            products: products.filter({ $0.isActive }),
            metadata: ExportMetadata(
                totalProducts: products.filter({ $0.isActive }).count,
                categories: Array(Set(products.filter({ $0.isActive }).map { $0.category })),
                exportType: "cosmetic_bag"
            )
        )
        
        let jsonData = (try? JSONEncoder().encode(exportData)) ?? Data()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Glowly_CosmeticBag.json")
        try? jsonData.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    func createShareableLink() -> String {
        // In a real app, this would create a shareable link that:
        // 1. Opens the app if user has it installed
        // 2. Redirects to App Store if user doesn't have it
        // 3. Shows a web preview with product list
        return "https://glowly.app/share/\(UUID().uuidString)"
    }
    
    private func addSampleProducts() {
        let calendar = Calendar.current
        let today = Date()
        
        // IMPORTANT: Reset data flag - delete app and reinstall to see new products
        // Detailed product data with ingredients, usage, benefits, and warnings
        // All products matched to actual images in Assets
        let detailedProducts: [(
            name: String, brand: String, category: ProductCategory, applicationZone: ApplicationZone,
            daysOffset: Int, expiryDays: Int, imageName: String, notes: String,
            ingredients: String, howToUse: String, benefits: [String], warnings: [String]
        )] = [
            (
                "Тональный крем True Match", "L'Oréal", .foundation, .face, -60, 15, "L'Oréal True Match Foundation", "Любимый оттенок W3",
                "Aqua/Water, Cyclopentasiloxane, Nylon-12, Isododecane, Alcohol Denat., Cyclohexasiloxane, PEG-10 Dimethicone, Cetyl PEG/PPG-10/1 Dimethicone, Perlite, Synthetic Fluorphlogopite, Niacinamide",
                "Нанесите небольшое количество на кожу лица и равномерно распределите спонжем, кистью или пальцами. Начинайте от центра лица и двигайтесь к контуру.",
                ["Выравнивает тон кожи", "Скрывает несовершенства", "Придает естественное сияние", "Увлажняет кожу"],
                ["Может закупорить поры при жирной коже", "Проверьте на аллергию перед использованием"]
            ),
            (
                "Помада Ruby Woo", "MAC", .lipstick, .lips, -30, -5, "MAC Ruby Woo Lipstick", "Классический красный",
                "Ricinus Communis Seed Oil, Silica, Pentaerythrityl Tetraethylhexanoate, Beeswax, Polyethylene, Phenyl Trimethicone, CI 15850 (Red 7), CI 77891 (Titanium Dioxide)",
                "Подготовьте губы: удалите омертвевшую кожу скрабом. Нанесите помаду, начиная от центра губ к уголкам. Для более четкого контура используйте карандаш для губ.",
                ["Насыщенный стойкий цвет", "Матовый финиш", "Долгое ношение до 8 часов", "Классический красный оттенок"],
                ["Может сушить губы - используйте бальзам", "Содержит пигменты - может окрашивать кожу"]
            ),
            (
                "Тушь для ресниц Lash Sensational", "Maybelline", .mascara, .eyes, -90, 7, "Maybelline Lash Sensational Mascara", "Водостойкая формула",
                "Aqua/Water, Paraffin, Potassium Cetyl Phosphate, Copernicia Cerifera Cera/Wax, Ethylene/Acrylic Acid Copolymer, Styrene/Acrylates/Ammonium Methacrylate Copolymer",
                "Поднесите щеточку к основанию ресниц и зигзагообразными движениями ведите к кончикам. Нанесите 2-3 слоя для максимального объема.",
                ["Создает веерный эффект", "Разделяет каждую ресничку", "Добавляет объем и длину", "Водостойкая формула"],
                ["Срок годности 3 месяца после вскрытия", "Не делить с другими", "Может вызвать раздражение глаз"]
            ),
            (
                "Увлажняющий крем", "CeraVe", .moisturizer, .face, -14, 180, "CeraVe Moisturizing Cream", "Для сухой кожи",
                "Aqua/Water, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Dimethicone, Hyaluronic Acid",
                "Наносите на чистую кожу лица и шеи дважды в день - утром и вечером. Мягко массируйте до полного впитывания.",
                ["Глубоко увлажняет кожу", "Восстанавливает защитный барьер", "Подходит для чувствительной кожи", "Некомедогенный"],
                ["При попадании в глаза промыть водой", "Хранить в прохладном месте"]
            ),
            (
                "Тени для век Naked", "Urban Decay", .eyeshadow, .eyes, -180, 365, "Urban Decay Naked Eyeshadow Palette", "Палетка нейтральных оттенков",
                "Mica, Talc, Zinc Stearate, Dimethicone, Octyldodecyl Stearoyl Stearate, Pentaerythrityl Tetraisostearate, Caprylyl Glycol, Phenoxyethanol, CI 77491, CI 77492, CI 77499, CI 77891",
                "Наносите тени кистью или аппликатором на веко. Растушуйте переходы. Используйте базу под тени для стойкости.",
                ["Универсальные нейтральные оттенки", "Легко растушевываются", "Стойкие до 12 часов", "Подходят для любого макияжа"],
                ["Избегайте попадания в глаза", "Может содержать следы орехов"]
            ),
            (
                "Консилер Fit Me", "Maybelline", .concealer, .face, -45, 60, "Maybelline Fit Me Concealer", "Светлый оттенок",
                "Aqua/Water, Cyclopentasiloxane, Hydrogenated Polyisobutene, Glycerin, Nylon-12, Isododecane, Cetyl PEG/PPG-10/1 Dimethicone, Sodium Chloride",
                "Наносите точечно на проблемные зоны: под глаза, на покраснения, прыщики. Растушуйте границы пальцами или спонжем.",
                ["Маскирует темные круги", "Скрывает покраснения", "Легкая текстура", "Не скатывается в складках"],
                ["Может подчеркивать сухость кожи", "Выбирайте оттенок светлее тонального средства"]
            ),
            (
                "Румяна Orgasm", "NARS", .blush, .cheeks, -120, 300, "NARS Orgasm Blush", "Персиковый с золотым шиммером",
                "Mica, Talc, Isononyl Isononanoate, Dimethicone, Polyethylene, Magnesium Stearate, Caprylyl Glycol, CI 77491, CI 77492, CI 15850",
                "Наберите румяна на кисть, стряхните излишки. Наносите на яблочки щек круговыми движениями, растушевывая к вискам.",
                ["Придает свежесть лицу", "Естественный румянец", "Сияющий финиш", "Подходит многим оттенкам кожи"],
                ["Содержит шиммер", "Наносите понемногу - легко переборщить"]
            ),
            (
                "Бронзер Chocolate Soleil", "Too Faced", .bronzer, .face, -90, 400, "Too Faced Chocolate Soleil Bronzer", "Матовый финиш",
                "Mica, Zinc Stearate, Boron Nitride, Nylon-12, Dimethicone, Silica, Theobroma Cacao (Cocoa) Extract, CI 77491, CI 77492, CI 77499, CI 77891",
                "Наносите на зоны, где естественно ложится загар: скулы, виски, контур лица, нос. Используйте пушистую кисть.",
                ["Создает эффект загара", "Скульптурирует лицо", "Матовый финиш", "Аромат какао"],
                ["Наносите постепенно", "Хорошо растушевывайте"]
            ),
            (
                "Хайлайтер Champagne Pop", "Becca", .highlighter, .face, -60, 450, "Becca Champagne Pop Highlighter", "Сияющий золотистый",
                "Mica, Zinc Stearate, Dimethicone, Caprylic/Capric Triglyceride, Polyethylene, Calcium Sodium Borosilicate, CI 77891, CI 77491, CI 77163",
                "Наносите на выступающие части лица: скулы, спинку носа, галочку над губой, внутренний уголок глаз. Растушуйте для естественного свечения.",
                ["Придает сияние коже", "Освежает макияж", "Деликатный золотистый блеск", "Можно использовать влажным способом"],
                ["Не наносите на проблемные зоны", "Может подчеркнуть текстуру кожи"]
            ),
            (
                "Подводка для глаз", "Stila", .eyeliner, .eyes, -75, 20, "Stila Stay All Day Eyeliner", "Стойкая жидкая подводка",
                "Aqua/Water, Styrene/Acrylates Copolymer, Propylene Glycol, Triethanolamine, Phenoxyethanol, Methylparaben, CI 77266 (Black 2)",
                "Начинайте линию от внутреннего уголка глаза. Ведите тонкую линию вдоль роста ресниц. Для стрелки выводите кончик к виску.",
                ["Насыщенный черный цвет", "Стойкость до 16 часов", "Не размазывается", "Точная тонкая кисть"],
                ["Снимать только средством для демакияжа", "Срок годности 6 месяцев после вскрытия"]
            ),
            (
                "Блеск для губ", "Fenty Beauty", .lipGloss, .lips, -30, 100, "Fenty Beauty Gloss Bomb", "Прозрачный с блестками",
                "Polybutene, Octyldodecanol, Pentaerythrityl Tetraisostearate, Silica Dimethyl Silylate, Synthetic Fluorphlogopite, Calcium Sodium Borosilicate, CI 77891",
                "Нанесите на губы аппликатором. Можно использовать отдельно или поверх помады для дополнительного блеска.",
                ["Увлажняет губы", "Придает объем", "Деликатное сияние", "Комфортная текстура"],
                ["Липкая текстура", "Волосы могут прилипать"]
            ),
            (
                "Праймер для лица", "Benefit", .primer, .face, -50, 150, "Benefit Porefessional Primer", "Сужает поры",
                "Cyclopentasiloxane, Dimethicone, Dimethicone/Vinyl Dimethicone Crosspolymer, Polymethyl Methacrylate, Silica, Phenoxyethanol",
                "Нанесите на чистую увлажненную кожу перед макияжем. Распределите тонким слоем, уделяя внимание порам и неровностям.",
                ["Визуально сужает поры", "Выравнивает текстуру кожи", "Продлевает стойкость макияжа", "Матирует"],
                ["Используйте немного продукта", "Может скатываться при избытке"]
            ),
            (
                "Очищающий гель", "La Roche-Posay", .cleanser, .face, -20, 200, "La Roche-Posay Effaclar Cleanser", "Для чувствительной кожи",
                "Aqua/Water, Glycerin, Sodium Laureth Sulfate, PEG-8, Coco-Betaine, Niacinamide, Acrylates Copolymer, Zinc PCA, Sodium Chloride, Sodium Hydroxide",
                "Нанесите на влажную кожу лица, вспеньте массирующими движениями. Смойте теплой водой. Использовать утром и вечером.",
                ["Глубоко очищает поры", "Не сушит кожу", "Подходит для чувствительной кожи", "Удаляет излишки себума"],
                ["Избегайте попадания в глаза", "При раздражении прекратите использование"]
            ),
            (
                "Сыворотка с витамином C", "The Ordinary", .serum, .face, -40, 90, "The Ordinary Vitamin C Serum", "Осветляющая",
                "Aqua/Water, Ascorbic Acid, Propanediol, Pentylene Glycol, Alpha-Arbutin, Sodium Hyaluronate, Salicylic Acid, Trisodium Ethylenediamine Disuccinate, Xanthan Gum",
                "Наносите 2-4 капли на чистую кожу утром перед кремом. Следом обязательно используйте SPF. Начните с 2-3 раз в неделю.",
                ["Осветляет пигментацию", "Выравнивает тон кожи", "Антиоксидантная защита", "Стимулирует выработку коллагена"],
                ["Может вызывать пощипывание", "Используйте SPF днем", "Хранить в холодильнике", "Избегайте с ретинолом"]
            ),
            (
                "Солнцезащитный крем SPF 50", "Bioré", .sunscreen, .face, -10, 250, "Bioré UV Aqua Rich Sunscreen", "Невидимый финиш",
                "Water, Ethylhexyl Methoxycinnamate, Homosalate, Octocrylene, Butyl Methoxydibenzoylmethane, Glycerin, Dimethicone, Titanium Dioxide",
                "Наносите щедро на лицо за 15-20 минут до выхода на солнце. Обновляйте каждые 2 часа и после купания.",
                ["Защита от UVA и UVB лучей", "Предотвращает фотостарение", "Легкая текстура", "Не оставляет белых следов"],
                ["Обязательно наносить ежедневно", "Может вызывать аллергию", "Смывать перед сном"]
            ),
            (
                "Пудра компактная Fit Me", "Maybelline", .powder, .face, -35, 120, "Maybelline Fit Me Powder", "Матирующая",
                "Talc, Mica, Magnesium Stearate, Kaolin, Silica, Dimethicone, Zinc Oxide, CI 77891, CI 77491, CI 77492, CI 77499",
                "Наносите кистью или спонжем на Т-зону и другие жирные участки лица. Можно использовать для освежения макияжа в течение дня.",
                ["Матирует кожу", "Закрепляет макияж", "Выравнивает тон", "Легкая текстура"],
                ["Может подчеркивать сухость", "Не наносите толстым слоем"]
            ),
            (
                "Тональная основа Studio Fix", "MAC", .foundation, .face, -70, 25, "MAC Studio Fix Foundation", "Средний тон",
                "Water, Cyclopentasiloxane, Trimethylsiloxysilicate, Butylene Glycol, PEG-10 Dimethicone, Glycerin, Dimethicone, CI 77891, CI 77491, CI 77492, CI 77499",
                "Нанесите на кожу лица кистью, спонжем или пальцами. Растушуйте от центра к краям лица для безупречного покрытия.",
                ["Среднее-полное покрытие", "Естественный финиш", "Стойкость до 10 часов", "Выравнивает текстуру"],
                ["Может окисляться на жирной коже", "Требуется праймер для лучшего результата"]
            )
        ]
        
        for (name, brand, category, applicationZone, purchaseOffset, _, imageName, notes, ingredients, howToUse, benefits, warnings) in detailedProducts {
            // Load image from Assets and convert to JPEG data for better storage
            var imageData: Data?
            if let image = UIImage(named: imageName) {
                imageData = image.jpegData(compressionQuality: 0.8)
            }
            
            var product = Product(
                name: name,
                brand: brand,
                category: category,
                applicationZone: applicationZone,
                purchaseDate: calendar.date(byAdding: .day, value: purchaseOffset, to: today)!,
                barcode: nil,
                imageData: imageData,
                notes: notes
            )
            
            // Add detailed information
            product.ingredients = ingredients
            product.howToUse = howToUse
            product.benefits = benefits
            product.warnings = warnings
            
            products.append(product)
        }
        
        saveProducts()
        updateNotifications()
    }
}

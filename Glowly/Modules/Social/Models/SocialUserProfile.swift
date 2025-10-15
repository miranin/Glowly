//
//  SocialUserProfile.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation
import SwiftUI

struct SocialUserProfile: Identifiable, Codable {
    let id: String
    let userName: String
    let bio: String?
    let avatar: String?
    let isPremium: Bool
    let userType: Post.UserType
    var followersCount: Int
    var followingCount: Int
    let postsCount: Int
    var isFollowing: Bool
    
    // Косметичка пользователя (краткая версия)
    let cosmeticBagPreview: [ProductPreview]
    
    struct ProductPreview: Identifiable, Codable {
        let id: String
        let name: String
        let brand: String
        let category: CosmeticCategory
        let imageUrl: String?

        // Detailed Product Information
        let ingredients: String
        let howToUse: String
        let benefits: [String]
        let warnings: [String]
        let notes: String

        // Personalization tags
        let isSensitiveSafe: Bool
        let isAcneSafe: Bool
    }
    
    enum CosmeticCategory: String, Codable, CaseIterable {
        case facialSkincare = "Facial Skincare"
        case makeup = "Makeup"
        case bodyCare = "Body Care"
        case hairCare = "Hair Care"
        
        var icon: String {
            switch self {
            case .facialSkincare: return "face.smiling"
            case .makeup: return "paintbrush.pointed"
            case .bodyCare: return "figure.walk"
            case .hairCare: return "comb"
            }
        }
        
        var color: Color {
            switch self {
            case .facialSkincare: return Color(red: 0.85, green: 0.33, blue: 0.52)
            case .makeup: return Color(red: 0.95, green: 0.62, blue: 0.10)
            case .bodyCare: return Color(red: 0.14, green: 0.66, blue: 0.40)
            case .hairCare: return Color(red: 0.40, green: 0.30, blue: 0.45)
            }
        }
    }
}

// MARK: - Mock Data
extension SocialUserProfile {
    static let mockProfile = SocialUserProfile(
        id: "user1",
        userName: "Анна Иванова",
        bio: "Бьюти-блогер 💄✨\nДелюсь секретами красоты",
        avatar: nil,
        isPremium: true,
        userType: .premium,
        followersCount: 1234,
        followingCount: 567,
        postsCount: 89,
        isFollowing: false,
        cosmeticBagPreview: [
            ProductPreview(
                id: "1",
                name: "Forever Skin Glow Foundation",
                brand: "Dior",
                category: .makeup,
                imageUrl: nil,
                ingredients: "Aqua, Cyclopentasiloxane, Isododecane, Glycerin, PEG-10 Dimethicone, Phenoxyethanol, Sodium Chloride, Titanium Dioxide, Mica",
                howToUse: "Нанесите небольшое количество на кожу лица с помощью кисти или спонжа. Растушуйте от центра к периферии лица для равномерного покрытия.",
                benefits: ["Придает сияние коже", "Стойкое покрытие до 24 часов", "Увлажняет кожу", "Выравнивает тон лица"],
                warnings: ["Избегайте попадания в глаза", "Может вызывать аллергию у чувствительной кожи"],
                notes: "Мой любимый тональный крем! Использую оттенок 2N для идеального совпадения с тоном кожи.",
                isSensitiveSafe: true,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "2",
                name: "Moisturizing Cream",
                brand: "CeraVe",
                category: .facialSkincare,
                imageUrl: nil,
                ingredients: "Aqua/Water, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Dimethicone",
                howToUse: "Наносите на очищенную кожу лица и шеи утром и вечером. Мягко массируйте до полного впитывания.",
                benefits: ["Глубокое увлажнение 24 часа", "Восстанавливает защитный барьер кожи", "Подходит для чувствительной кожи", "Некомедогенный"],
                warnings: ["При попадании в глаза промыть водой", "Хранить в прохладном месте"],
                notes: "Отличный крем для сухой кожи! Использую каждое утро и вечер.",
                isSensitiveSafe: true,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "3",
                name: "Intensive Body Lotion",
                brand: "Nivea",
                category: .bodyCare,
                imageUrl: nil,
                ingredients: "Aqua, Glycerin, Paraffinum Liquidum, Myristyl Alcohol, Dimethicone, Lanolin Alcohol, Panthenol, Tocopheryl Acetate",
                howToUse: "Наносите на чистую кожу тела массирующими движениями. Для лучшего эффекта используйте после душа на влажную кожу.",
                benefits: ["Интенсивное увлажнение", "Быстро впитывается", "Подходит для сухой кожи", "Придает мягкость"],
                warnings: ["Только для наружного применения", "Избегайте попадания в глаза"],
                notes: "Супер увлажняющий! Помогает при сухости кожи, особенно зимой.",
                isSensitiveSafe: false,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "4",
                name: "Pro-V Shampoo",
                brand: "Pantene",
                category: .hairCare,
                imageUrl: nil,
                ingredients: "Aqua, Sodium Laureth Sulfate, Sodium Citrate, Cocamidopropyl Betaine, Sodium Xylenesulfonate, Sodium Chloride, Parfum, Panthenol",
                howToUse: "Нанесите на влажные волосы, вспеньте массирующими движениями. Тщательно смойте водой. При необходимости повторите.",
                benefits: ["Укрепляет волосы", "Придает блеск", "Питает от корней до кончиков", "Защита от повреждений"],
                warnings: ["Избегайте попадания в глаза", "При попадании промыть водой"],
                notes: "Отличный шампунь для ежедневного использования. Волосы блестят!",
                isSensitiveSafe: false,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "5",
                name: "Ruby Woo Lipstick",
                brand: "MAC",
                category: .makeup,
                imageUrl: nil,
                ingredients: "Ricinus Communis Seed Oil, Silica, Pentaerythrityl Tetraethylhexanoate, Beeswax, Polyethylene, Phenyl Trimethicone, CI 15850, CI 77891",
                howToUse: "Нанесите помаду от центра губ к краям. Для более четкого контура используйте карандаш для губ в тон.",
                benefits: ["Насыщенный цвет", "Матовый финиш", "Стойкость до 8 часов", "Культовый красный оттенок"],
                warnings: ["Может сушить губы", "Используйте бальзам перед нанесением"],
                notes: "Мой любимый красный оттенок! Идеален для вечерних выходов.",
                isSensitiveSafe: false,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "6",
                name: "Niacinamide 10% + Zinc 1%",
                brand: "The Ordinary",
                category: .facialSkincare,
                imageUrl: nil,
                ingredients: "Aqua, Niacinamide, Pentylene Glycol, Zinc PCA, Tamarindus Indica Seed Gum, Xanthan Gum, Isoceteth-20, Ethoxydiglycol, Phenoxyethanol, Chlorphenesin",
                howToUse: "Наносите несколько капель на лицо утром и вечером перед кремом. Избегайте области вокруг глаз.",
                benefits: ["Сужает поры", "Регулирует выработку себума", "Осветляет пигментацию", "Улучшает текстуру кожи"],
                warnings: ["Может вызывать покраснение при первом применении", "Начните с 2-3 раз в неделю", "Не смешивать с витамином C"],
                notes: "Отлично работает на жирной коже! Поры стали меньше за месяц использования.",
                isSensitiveSafe: false,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "7",
                name: "Lash Sensational Mascara",
                brand: "Maybelline",
                category: .makeup,
                imageUrl: nil,
                ingredients: "Aqua/Water, Paraffin, Potassium Cetyl Phosphate, Copernicia Cerifera Cera/Wax, Ethylene/Acrylic Acid Copolymer, Styrene/Acrylates/Ammonium Methacrylate Copolymer",
                howToUse: "Поднесите щеточку к основанию ресниц и зигзагообразными движениями ведите к кончикам. Нанесите 2-3 слоя для максимального объема.",
                benefits: ["Создает веерный эффект", "Разделяет каждую ресничку", "Придает объем и длину", "Водостойкая формула"],
                warnings: ["Срок годности 3 месяца после вскрытия", "Не делить с другими", "Может вызвать раздражение глаз"],
                notes: "Лучшая тушь за свою цену! Реснички как накладные.",
                isSensitiveSafe: false,
                isAcneSafe: true
            ),
            ProductPreview(
                id: "8",
                name: "UV Aqua Rich Watery Essence SPF50+",
                brand: "Bioré",
                category: .facialSkincare,
                imageUrl: nil,
                ingredients: "Water, Ethylhexyl Methoxycinnamate, Homosalate, Octocrylene, Butyl Methoxydibenzoylmethane, Glycerin, Dimethicone, Titanium Dioxide",
                howToUse: "Наносите щедро на лицо за 15-20 минут до выхода на солнце. Обновляйте каждые 2 часа и после купания.",
                benefits: ["Защита SPF 50+ PA++++", "Легкая водная текстура", "Не оставляет белых следов", "Подходит под макияж"],
                warnings: ["Обязательно наносить ежедневно", "Может вызывать аллергию", "Смывать перед сном"],
                notes: "Моя любимая санскрин! Не оставляет жирного блеска и отлично подходит под макияж.",
                isSensitiveSafe: true,
                isAcneSafe: true
            )
        ]
    )
}

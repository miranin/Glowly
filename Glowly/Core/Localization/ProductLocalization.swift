//
//  ProductLocalization.swift
//  Glowly
//
//  Provides localized product names, descriptions, benefits, and warnings
//  for mock/sample products
//

import Foundation

struct LocalizedProductData {
    let name: String
    let notes: String
    let howToUse: String
    let benefits: [String]
    let warnings: [String]
}

class ProductLocalization {

    static func getLocalizedData(for productKey: String, language: AppLanguage) -> LocalizedProductData? {
        switch productKey {
        // MARK: - Foundation Products
        case "mac_studio_fix":
            return getMacStudioFixData(language: language)

        // MARK: - Lip Products
        case "mac_ruby_woo":
            return getMacRubyWooData(language: language)
        case "fenty_gloss":
            return getFentyGlossData(language: language)

        // MARK: - Eye Products
        case "maybelline_mascara":
            return getMaybellineMascaraData(language: language)
        case "urban_decay_naked":
            return getUrbanDecayNakedData(language: language)
        case "stila_eyeliner":
            return getStilaEyelinerData(language: language)

        // MARK: - Skincare
        case "cerave_moisturizer":
            return getCeraveMoisturizerData(language: language)
        case "ordinary_serum":
            return getOrdinarySerumData(language: language)
        case "laroche_cleanser":
            return getLaRocheCleanserData(language: language)
        case "biore_sunscreen":
            return getBioreSunscreenData(language: language)

        // MARK: - Makeup Products
        case "maybelline_concealer":
            return getMaybellineConcealerData(language: language)
        case "nars_blush":
            return getNarsBlushData(language: language)
        case "toofaced_bronzer":
            return getTooFacedBronzerData(language: language)
        case "becca_highlighter":
            return getBeccaHighlighterData(language: language)
        case "benefit_primer":
            return getBenefitPrimerData(language: language)
        case "maybelline_powder":
            return getMaybellinePowderData(language: language)

        default:
            return nil
        }
    }

    // MARK: - Product Localization Methods

    private static func getLorealTrueMatchData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english:
            return LocalizedProductData(
                name: "True Match Foundation",
                notes: "Favorite shade W3",
                howToUse: "Apply a small amount to facial skin using a brush or sponge. Blend from the center of the face outward to the edges.",
                benefits: ["Evens skin tone", "Covers imperfections", "Natural radiance", "Moisturizes skin"],
                warnings: ["May clog pores on oily skin", "Test for allergies before use"]
            )
        case .russian:
            return LocalizedProductData(
                name: "Тональный крем True Match",
                notes: "Любимый оттенок W3",
                howToUse: "Нанесите небольшое количество на кожу лица и равномерно распределите спонжем, кистью или пальцами. Начинайте от центра лица и двигайтесь к контуру.",
                benefits: ["Выравнивает тон кожи", "Скрывает несовершенства", "Придает естественное сияние", "Увлажняет кожу"],
                warnings: ["Может закупорить поры при жирной коже", "Проверьте на аллергию перед использованием"]
            )
        case .kazakh:
            return LocalizedProductData(
                name: "True Match тональды кремі",
                notes: "Сүйікті реңкім W3",
                howToUse: "Бетке аз мөлшерде жағып, спонж, қылқалам немесе саусақтармен біркелкі таратыңыз. Бет ортасынан бастап шеттеріне қарай жүргізіңіз.",
                benefits: ["Тері реңін теңестіреді", "Кемшіліктерді жасырады", "Табиғи жарқырау береді", "Теріні ылғалдандырады"],
                warnings: ["Майлы терідегі кеуектерді бітеуі мүмкін", "Қолданар алдында аллергияға тексеріңіз"]
            )
        }
    }

    private static func getMacRubyWooData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english:
            return LocalizedProductData(
                name: "Ruby Woo Lipstick",
                notes: "Classic red shade",
                howToUse: "Apply lipstick from the center of lips outward. For a more defined contour, use a lip liner in a matching shade.",
                benefits: ["Rich lasting color", "Matte finish", "Long-wear up to 8 hours", "Cult classic red shade"],
                warnings: ["May dry lips - use balm", "Contains pigments - may stain skin"]
            )
        case .russian:
            return LocalizedProductData(
                name: "Помада Ruby Woo",
                notes: "Классический красный",
                howToUse: "Нанесите помаду от центра губ к краям. Для более четкого контура используйте карандаш для губ в тон.",
                benefits: ["Насыщенный стойкий цвет", "Матовый финиш", "Долгое ношение до 8 часов", "Культовый красный оттенок"],
                warnings: ["Может сушить губы - используйте бальзам", "Содержит пигменты - может окрашивать кожу"]
            )
        case .kazakh:
            return LocalizedProductData(
                name: "Ruby Woo ерін бояуы",
                notes: "Классикалық қызыл",
                howToUse: "Ерін бояуын ерін ортасынан шеттеріне жағыңыз. Нақты контур үшін дәл реңктегі ерін қаламын пайдаланыңыз.",
                benefits: ["Қанық ұзаққа созылатын түс", "Мат финиш", "8 сағатқа дейін ұзақ", "Культтық қызыл реңк"],
                warnings: ["Ерінді кепетуі мүмкін - бальзам пайдаланыңыз", "Пигменттер бар - тері бояуы мүмкін"]
            )
        }
    }

    private static func getCeraveMoisturizerData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english:
            return LocalizedProductData(
                name: "Moisturizing Cream",
                notes: "Perfect for dry skin",
                howToUse: "Apply to clean face and neck skin twice daily - morning and evening. Gently massage until fully absorbed.",
                benefits: ["Deep 24-hour hydration", "Restores protective barrier", "Suitable for sensitive skin", "Non-comedogenic"],
                warnings: ["Rinse with water if contacts eyes", "Store in cool place"]
            )
        case .russian:
            return LocalizedProductData(
                name: "Увлажняющий крем",
                notes: "Отлично для сухой кожи",
                howToUse: "Наносите на чистую кожу лица и шеи дважды в день - утром и вечером. Мягко массируйте до полного впитывания.",
                benefits: ["Глубокое увлажнение 24 часа", "Восстанавливает защитный барьер", "Подходит для чувствительной кожи", "Некомедогенный"],
                warnings: ["При попадании в глаза промыть водой", "Хранить в прохладном месте"]
            )
        case .kazakh:
            return LocalizedProductData(
                name: "Ылғалдандырғыш крем",
                notes: "Құрғақ тері үшін тамаша",
                howToUse: "Таза бет пен мойын теріне күніне екі рет жағыңыз - таңертең және кешке. Толық сіңгенше жұмсақ массаж жасаңыз.",
                benefits: ["24 сағат терең ылғалдандыру", "Қорғаныс тосқауылын қалпына келтіреді", "Сезімтал тері үшін жарайды", "Комедогендік емес"],
                warnings: ["Көзге түскен жағдайда сумен шайыңыз", "Салқын жерде сақтаңыз"]
            )
        }
    }

    private static func getMaybellineMascaraData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english:
            return LocalizedProductData(
                name: "Lash Sensational Mascara",
                notes: "Waterproof formula",
                howToUse: "Bring the brush to the base of lashes and move in zigzag motions to the tips. Apply 2-3 coats for maximum volume.",
                benefits: ["Creates fan effect", "Separates each lash", "Adds volume and length", "Waterproof formula"],
                warnings: ["Shelf life 3 months after opening", "Do not share with others", "May cause eye irritation"]
            )
        case .russian:
            return LocalizedProductData(
                name: "Тушь для ресниц Lash Sensational",
                notes: "Водостойкая формула",
                howToUse: "Поднесите щеточку к основанию ресниц и зигзагообразными движениями ведите к кончикам. Нанесите 2-3 слоя для максимального объема.",
                benefits: ["Создает веерный эффект", "Разделяет каждую ресничку", "Добавляет объем и длину", "Водостойкая формула"],
                warnings: ["Срок годности 3 месяца после вскрытия", "Не делить с другими", "Может вызвать раздражение глаз"]
            )
        case .kazakh:
            return LocalizedProductData(
                name: "Lash Sensational кірпік түсі",
                notes: "Суға төзімді формула",
                howToUse: "Щеткасын кірпік түбіне жақындатып, зигзаг қозғалыстармен ұшына дейін апарыңыз. Максималды көлем үшін 2-3 қабат жағыңыз.",
                benefits: ["Желпуіш эффект жасайды", "Әр кірпікті бөледі", "Көлем мен ұзындық береді", "Суға төзімді формула"],
                warnings: ["Ашқаннан кейін 3 ай сақталады", "Басқалармен бөліспеңіз", "Көз тітіркенуін тудыруы мүмкін"]
            )
        }
    }

    // MARK: - Additional products (abbreviated for space)

    private static func getMacStudioFixData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english:
            return LocalizedProductData(
                name: "Studio Fix Foundation",
                notes: "Medium tone",
                howToUse: "Apply to facial skin with brush, sponge or fingers. Blend from center to edges for flawless coverage.",
                benefits: ["Medium-full coverage", "Natural finish", "Lasts up to 10 hours", "Evens texture"],
                warnings: ["May oxidize on oily skin", "Requires primer for best results"]
            )
        case .russian:
            return LocalizedProductData(
                name: "Тональная основа Studio Fix",
                notes: "Средний тон",
                howToUse: "Нанесите на кожу лица кистью, спонжем или пальцами. Растушуйте от центра к краям лица для безупречного покрытия.",
                benefits: ["Среднее-полное покрытие", "Естественный финиш", "Стойкость до 10 часов", "Выравнивает текстуру"],
                warnings: ["Может окисляться на жирной коже", "Требуется праймер для лучшего результата"]
            )
        case .kazakh:
            return LocalizedProductData(
                name: "Studio Fix тональды негізі",
                notes: "Орташа тон",
                howToUse: "Бет теріне қылқалам, спонж немесе саусақпен жағыңыз. Мінсіз жабу үшін ортадан шеттеріне таратыңыз.",
                benefits: ["Орташа-толық жабу", "Табиғи финиш", "10 сағатқа дейін тұрақты", "Құрылымды теңестіреді"],
                warnings: ["Майлы теріде тотығуы мүмкін", "Жақсы нәтиже үшін праймер керек"]
            )
        }
    }

    // Simplified implementations for remaining products
    private static func getFentyGlossData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Gloss Bomb", notes: "Clear with sparkles", howToUse: "Apply to lips with applicator. Can be used alone or over lipstick for extra shine.", benefits: ["Moisturizes lips", "Adds volume", "Subtle shine", "Comfortable texture"], warnings: ["Sticky texture", "Hair may stick"])
        case .russian: return LocalizedProductData(name: "Блеск для губ", notes: "Прозрачный с блестками", howToUse: "Нанесите на губы аппликатором. Можно использовать отдельно или поверх помады для дополнительного блеска.", benefits: ["Увлажняет губы", "Придает объем", "Деликатное сияние", "Комфортная текстура"], warnings: ["Липкая текстура", "Волосы могут прилипать"])
        case .kazakh: return LocalizedProductData(name: "Ерін жылтыртқышы", notes: "Мөлдір жылтыратқышпен", howToUse: "Ерінге аппликатормен жағыңыз. Жеке немесе ерін бояуының үстінен қосымша жарқырау үшін пайдалануға болады.", benefits: ["Ерінді ылғалдандырады", "Көлем береді", "Нәзік жарқырау", "Ыңғайлы құрылым"], warnings: ["Желімді құрылым", "Шаш жабысуы мүмкін"])
        }
    }

    private static func getUrbanDecayNakedData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Naked Eyeshadow", notes: "Neutral shades palette", howToUse: "Apply eyeshadow with brush or applicator to eyelid. Blend transitions. Use primer for longevity.", benefits: ["Universal neutral shades", "Easy to blend", "Lasts up to 12 hours", "Suitable for any makeup"], warnings: ["Avoid eye contact", "May contain traces of nuts"])
        case .russian: return LocalizedProductData(name: "Тени для век Naked", notes: "Палетка нейтральных оттенков", howToUse: "Наносите тени кистью или аппликатором на веко. Растушуйте переходы. Используйте базу под тени для стойкости.", benefits: ["Универсальные нейтральные оттенки", "Легко растушевываются", "Стойкие до 12 часов", "Подходят для любого макияжа"], warnings: ["Избегайте попадания в глаза", "Может содержать следы орехов"])
        case .kazakh: return LocalizedProductData(name: "Naked көз көлеңкесі", notes: "Бейтарап реңктер палитрасы", howToUse: "Көз қабағына қылқалам немесе аппликатормен көлеңке жағыңыз. Өтулерді араластырыңыз. Тұрақтылық үшін праймер пайдаланыңыз.", benefits: ["Әмбебап бейтарап реңктер", "Оңай араластырылады", "12 сағатқа дейін тұрақты", "Кез келген макияжға жарайды"], warnings: ["Көзге түсуден аулақ болыңыз", "Жаңғақ іздері болуы мүмкін"])
        }
    }

    // Continuing with remaining products...
    private static func getStilaEyelinerData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Stay All Day Eyeliner", notes: "Long-lasting liquid liner", howToUse: "Start line from inner eye corner. Draw thin line along lash line. For wing, extend tip toward temple.", benefits: ["Rich black color", "Lasts up to 16 hours", "Smudge-proof", "Precise thin brush"], warnings: ["Remove only with makeup remover", "6 months shelf life after opening"])
        case .russian: return LocalizedProductData(name: "Подводка для глаз", notes: "Стойкая жидкая подводка", howToUse: "Начинайте линию от внутреннего уголка глаза. Ведите тонкую линию вдоль роста ресниц. Для стрелки выводите кончик к виску.", benefits: ["Насыщенный черный цвет", "Стойкость до 16 часов", "Не размазывается", "Точная тонкая кисть"], warnings: ["Снимать только средством для демакияжа", "Срок годности 6 месяцев после вскрытия"])
        case .kazakh: return LocalizedProductData(name: "Көз сызығы", notes: "Ұзаққа созылатын сұйық сызғыш", howToUse: "Көздің ішкі бұрышынан бастаңыз. Кірпік өсу сызығымен жұқа сызық жүргізіңіз. Құс қанаты үшін ұшын шекеге қарай шығарыңыз.", benefits: ["Қаныққан қара түс", "16 сағатқа дейін тұрақты", "Жақпайды", "Дәл жұқа қылқалам"], warnings: ["Тек макияж кетіргішпен алыңыз", "Ашқаннан кейін 6 ай сақталады"])
        }
    }

    private static func getMaybellineConcealerData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Fit Me Concealer", notes: "Light shade", howToUse: "Apply pointwise to problem areas: under eyes, on redness, blemishes. Blend edges with fingers or sponge.", benefits: ["Masks dark circles", "Covers redness", "Light texture", "Doesn't crease"], warnings: ["May emphasize dry skin", "Choose shade lighter than foundation"])
        case .russian: return LocalizedProductData(name: "Консилер Fit Me", notes: "Светлый оттенок", howToUse: "Наносите точечно на проблемные зоны: под глаза, на покраснения, прыщики. Растушуйте границы пальцами или спонжем.", benefits: ["Маскирует темные круги", "Скрывает покраснения", "Легкая текстура", "Не скатывается в складках"], warnings: ["Может подчеркивать сухость кожи", "Выбирайте оттенок светлее тонального средства"])
        case .kazakh: return LocalizedProductData(name: "Fit Me консилер", notes: "Ашық реңк", howToUse: "Проблемалық аймақтарға нүктелі түрде жағыңыз: көз астына, қызаруларға, безеулерге. Шекараларды саусақпен немесе спонжмен араластырыңыз.", benefits: ["Қараңғы дөңгелектерді жасырады", "Қызаруларды жабады", "Жеңіл құрылым", "Қатпарларда домаланбайды"], warnings: ["Құрғақ теріні атап көрсетуі мүмкін", "Тональдыдан ашық реңк таңдаңыз"])
        }
    }

    private static func getNarsBlushData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Orgasm Blush", notes: "Peachy with golden shimmer", howToUse: "Pick up blush on brush, shake off excess. Apply to apples of cheeks in circular motions, blending towards temples.", benefits: ["Adds freshness to face", "Natural flush", "Glowing finish", "Suits many skin tones"], warnings: ["Contains shimmer", "Apply little by little - easy to overdo"])
        case .russian: return LocalizedProductData(name: "Румяна Orgasm", notes: "Персиковый с золотым шиммером", howToUse: "Наберите румяна на кисть, стряхните излишки. Наносите на яблочки щек круговыми движениями, растушевывая к вискам.", benefits: ["Придает свежесть лицу", "Естественный румянец", "Сияющий финиш", "Подходит многим оттенкам кожи"], warnings: ["Содержит шиммер", "Наносите понемногу - легко переборщить"])
        case .kazakh: return LocalizedProductData(name: "Orgasm румяналары", notes: "Алтын жылтырлы шабдалы", howToUse: "Румянаны қылқаламға алып, артығын сілкіңіз. Бет алмалары на дөңгелек қозғалыстармен жағып, шекеге қарай таратыңыз.", benefits: ["Бетке сергектік береді", "Табиғи қызару", "Жарқыраған финиш", "Көп тері реңктеріне жарайды"], warnings: ["Жылтыр бар", "Аздап жағыңыз - асыра пайдалану оңай"])
        }
    }

    private static func getTooFacedBronzerData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Chocolate Soleil Bronzer", notes: "Matte finish", howToUse: "Apply to areas where tan naturally falls: cheekbones, temples, face contour, nose. Use fluffy brush.", benefits: ["Creates tan effect", "Sculpts face", "Matte finish", "Cocoa scent"], warnings: ["Apply gradually", "Blend well"])
        case .russian: return LocalizedProductData(name: "Бронзер Chocolate Soleil", notes: "Матовый финиш", howToUse: "Наносите на зоны, где естественно ложится загар: скулы, виски, контур лица, нос. Используйте пушистую кисть.", benefits: ["Создает эффект загара", "Скульптурирует лицо", "Матовый финиш", "Аромат какао"], warnings: ["Наносите постепенно", "Хорошо растушевывайте"])
        case .kazakh: return LocalizedProductData(name: "Chocolate Soleil бронзері", notes: "Мат финиш", howToUse: "Күйік табиғи түрде түсетін аймақтарға жағыңыз: бет сүйектері, шекелер, бет контуры, мұрын. Үлпілдек қылқалам пайдаланыңыз.", benefits: ["Күйік эффектін жасайды", "Бетті мүсіндейді", "Мат финиш", "Какао иісі"], warnings: ["Біртіндеп жағыңыз", "Жақсы араластырыңыз"])
        }
    }

    private static func getBeccaHighlighterData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Champagne Pop Highlighter", notes: "Glowing golden", howToUse: "Apply to protruding parts of face: cheekbones, nose bridge, cupid's bow, inner eye corner. Blend for natural glow.", benefits: ["Adds glow to skin", "Refreshes makeup", "Delicate golden shine", "Can be used wet"], warnings: ["Don't apply to problem areas", "May emphasize skin texture"])
        case .russian: return LocalizedProductData(name: "Хайлайтер Champagne Pop", notes: "Сияющий золотистый", howToUse: "Наносите на выступающие части лица: скулы, спинку носа, галочку над губой, внутренний уголок глаз. Растушуйте для естественного свечения.", benefits: ["Придает сияние коже", "Освежает макияж", "Деликатный золотистый блеск", "Можно использовать влажным способом"], warnings: ["Не наносите на проблемные зоны", "Может подчеркнуть текстуру кожи"])
        case .kazakh: return LocalizedProductData(name: "Champagne Pop хайлайтері", notes: "Жарқыраған алтын", howToUse: "Беттің шығыңқы бөліктеріне жағыңыз: бет сүйектері, мұрын жотасы, ерін үстіндегі белгі, көз ішкі бұрышы. Табиғи жарқырау үшін араластырыңыз.", benefits: ["Теріге жарқырау береді", "Макияжды жаңартады", "Нәзік алтын жылтыр", "Дымқыл түрде пайдалануға болады"], warnings: ["Проблемалық аймақтарға жағбаңыз", "Тері құрылымын атап көрсетуі мүмкін"])
        }
    }

    private static func getBenefitPrimerData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Porefessional Primer", notes: "Minimizes pores", howToUse: "Apply to clean moisturized skin before makeup. Spread in thin layer, paying attention to pores and unevenness.", benefits: ["Visually minimizes pores", "Evens skin texture", "Extends makeup wear", "Mattifies"], warnings: ["Use small amount", "May pill with excess"])
        case .russian: return LocalizedProductData(name: "Праймер Porefessional", notes: "Сужает поры", howToUse: "Нанесите на чистую увлажненную кожу перед макияжем. Распределите тонким слоем, уделяя внимание порам и неровностям.", benefits: ["Визуально сужает поры", "Выравнивает текстуру кожи", "Продлевает стойкость макияжа", "Матирует"], warnings: ["Используйте немного продукта", "Может скатываться при избытке"])
        case .kazakh: return LocalizedProductData(name: "Porefessional праймері", notes: "Кеуектерді тарылтады", howToUse: "Макияждан бұрын таза ылғалдандырылған теріге жағыңыз. Жұқа қабатпен таратып, кеуектер мен теңсіздіктерге назар аударыңыз.", benefits: ["Кеуектерді визуалды түрде тарылтады", "Тері құрылымын теңестіреді", "Макияж тұрақтылығын ұзартады", "Матты етеді"], warnings: ["Аз мөлшерде пайдаланыңыз", "Артық мөлшерде домаланУы мүмкін"])
        }
    }

    private static func getMaybellinePowderData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Fit Me Powder", notes: "Mattifying", howToUse: "Apply with brush or sponge to T-zone and other oily areas of face. Can be used to refresh makeup during the day.", benefits: ["Mattifies skin", "Sets makeup", "Evens tone", "Light texture"], warnings: ["May emphasize dryness", "Don't apply thick layer"])
        case .russian: return LocalizedProductData(name: "Пудра компактная Fit Me", notes: "Матирующая", howToUse: "Наносите кистью или спонжем на Т-зону и другие жирные участки лица. Можно использовать для освежения макияжа в течение дня.", benefits: ["Матирует кожу", "Закрепляет макияж", "Выравнивает тон", "Легкая текстура"], warnings: ["Может подчеркивать сухость", "Не наносите толстым слоем"])
        case .kazakh: return LocalizedProductData(name: "Fit Me ұнтағы", notes: "Матты етеді", howToUse: "Т-аймағына және беттің басқа майлы учаскелеріне қылқалам немесе спонжмен жағыңыз. Күні бойы макияжды жаңарту үшін пайдалануға болады.", benefits: ["Теріні матты етеді", "Макияжды бекітеді", "Реңді теңестіреді", "Жеңіл құрылым"], warnings: ["Құрғақтықты атап көрсетуі мүмкін", "Қалың қабатпен жағбаңыз"])
        }
    }

    private static func getOrdinarySerumData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Vitamin C Serum", notes: "Brightening", howToUse: "Apply 2-4 drops to clean skin in morning before cream. Follow with SPF. Start with 2-3 times per week.", benefits: ["Brightens pigmentation", "Evens skin tone", "Antioxidant protection", "Stimulates collagen production"], warnings: ["May cause tingling", "Use SPF during day", "Store in refrigerator", "Avoid with retinol"])
        case .russian: return LocalizedProductData(name: "Сыворотка с витамином C", notes: "Осветляющая", howToUse: "Наносите 2-4 капли на чистую кожу утром перед кремом. Следом обязательно используйте SPF. Начните с 2-3 раз в неделю.", benefits: ["Осветляет пигментацию", "Выравнивает тон кожи", "Антиоксидантная защита", "Стимулирует выработку коллагена"], warnings: ["Может вызывать пощипывание", "Используйте SPF днем", "Хранить в холодильнике", "Избегайте с ретинолом"])
        case .kazakh: return LocalizedProductData(name: "C витаминді сыворотка", notes: "Ашытуы", howToUse: "Таңертең кремнен бұрын таза теріге 2-4 тамшы жағыңыз. Одан кейін SPF міндетті пайдаланыңыз. Аптасына 2-3 рет бастаңыз.", benefits: ["Пигментацияны ашытады", "Тері реңін теңестіреді", "Антиоксиданттық қорғау", "Коллаген өндірісін ынталандырады"], warnings: ["Шаншуды тудыруы мүмкін", "Күндіз SPF пайдаланыңыз", "Тоңазытқышта сақтаңыз", "Ретинолмен қоспаңыз"])
        }
    }

    private static func getLaRocheCleanserData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "Effaclar Cleanser", notes: "For sensitive skin", howToUse: "Apply to damp facial skin, lather with massaging motions. Rinse with warm water. Use morning and evening.", benefits: ["Deeply cleanses pores", "Doesn't dry skin", "Suitable for sensitive skin", "Removes excess sebum"], warnings: ["Avoid eye contact", "Discontinue if irritation occurs"])
        case .russian: return LocalizedProductData(name: "Очищающий гель", notes: "Для чувствительной кожи", howToUse: "Нанесите на влажную кожу лица, вспеньте массирующими движениями. Смойте теплой водой. Использовать утром и вечером.", benefits: ["Глубоко очищает поры", "Не сушит кожу", "Подходит для чувствительной кожи", "Удаляет излишки себума"], warnings: ["Избегайте попадания в глаза", "При раздражении прекратите использование"])
        case .kazakh: return LocalizedProductData(name: "Effaclar тазартғыш", notes: "Сезімтал тері үшін", howToUse: "Дымқыл бет теріне жағып, массаж қозғалыстарымен көбіктендіріңіз. Жылы сумен шайыңыз. Таңертең және кешке пайдаланыңыз.", benefits: ["Кеуектерді терең тазартады", "Теріні кептірмейді", "Сезімтал тері үшін жарайды", "Артық себумды кетіреді"], warnings: ["Көзге түсуден аулақ болыңыз", "Тітіркену болса пайдалануды тоқтатыңыз"])
        }
    }

    private static func getBioreSunscreenData(language: AppLanguage) -> LocalizedProductData {
        switch language {
        case .english: return LocalizedProductData(name: "UV Aqua Rich Watery Essence SPF50+", notes: "Invisible finish", howToUse: "Apply generously to face 15-20 minutes before sun exposure. Reapply every 2 hours and after swimming.", benefits: ["UVA and UVB protection", "Prevents photoaging", "Light texture", "No white cast"], warnings: ["Must apply daily", "May cause allergies", "Remove before bed"])
        case .russian: return LocalizedProductData(name: "Солнцезащитный крем SPF 50", notes: "Невидимый финиш", howToUse: "Наносите щедро на лицо за 15-20 минут до выхода на солнце. Обновляйте каждые 2 часа и после купания.", benefits: ["Защита от UVA и UVB лучей", "Предотвращает фотостарение", "Легкая текстура", "Не оставляет белых следов"], warnings: ["Обязательно наносить ежедневно", "Может вызывать аллергию", "Смывать перед сном"])
        case .kazakh: return LocalizedProductData(name: "UV Aqua Rich Watery Essence SPF50+", notes: "Көрінбейтін финиш", howToUse: "Күнге шығар алдында 15-20 минут бұрын бетке мол мөлшерде жағыңыз. Әр 2 сағат сайын және жүзгеннен кейін жаңартыңыз.", benefits: ["UVA және UVB қорғау", "Фотокәріліктің алдын алады", "Жеңіл құрылым", "Ақ іздер қалдырмайды"], warnings: ["Күнделікті жағу керек", "Аллергия тудыруы мүмкін", "Ұйықтар алдында алыңыз"])
        }
    }
}

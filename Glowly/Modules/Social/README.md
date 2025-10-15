# Social Module

> **Модульная архитектура для социальной ленты**  
> **Версия:** 1.0  
> **Статус:** ✅ Готов к миграции в SPM Package

---

## 📁 Структура модуля

```
Social/
├── Models/
│   ├── Post.swift              # Модель поста
│   ├── Comment.swift           # Модель комментария
│   └── SocialUserProfile.swift # Модель профиля пользователя
│
├── Services/
│   ├── FeedService.swift         # Управление лентой постов
│   ├── CommentService.swift      # Управление комментариями
│   └── UserProfileService.swift  # Управление профилями
│
└── Views/
    ├── CommentsView.swift        # Просмотр и добавление комментариев
    └── UserProfileView.swift     # Просмотр профиля пользователя
```

---

## ✨ Основные функции

### 1. **Лента постов** (`FeedService`)
- Загрузка постов от премиум пользователей и магазинов
- Лайки постов
- Pull-to-refresh
- Mock данные для разработки

### 2. **Комментарии** (`CommentService`)
- Просмотр комментариев к постам
- Добавление новых комментариев
- Лайки комментариев
- Ответы на комментарии (TODO)

### 3. **Профили пользователей** (`UserProfileService`)
- Просмотр профиля пользователя
- Статистика (посты, подписчики, подписки)
- Подписка/отписка
- Краткий просмотр косметички пользователя

---

## 🔗 Минимальная связанность

### Принципы модульности:
- ✅ **Независимые сервисы**: каждый сервис работает автономно
- ✅ **Протокол-ориентированный**: легко заменить реализацию
- ✅ **ObservableObject**: стандартный SwiftUI подход
- ✅ **Mock данные**: не зависит от backend
- ✅ **Готов к SPM**: можно вынести в отдельный package

### Зависимости:
- `Theme` - система цветов (можно инжектить)
- `Product.UserType` - enum типов пользователей (можно скопировать)

---

## 🚀 Готовность к SPM Package

### Шаги для миграции:

1. **Создать Package.swift**:
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SocialModule",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SocialModule", targets: ["SocialModule"])
    ],
    targets: [
        .target(name: "SocialModule", dependencies: [])
    ]
)
```

2. **Переместить файлы**:
   - Скопировать все файлы из `Social/` в package
   - Сделать все типы `public`
   - Убрать зависимость от `Theme` (инжектить через protocol)

3. **Импортировать в проект**:
```swift
import SocialModule
```

---

## 📝 API Usage

### FeedView:
```swift
@StateObject private var feedService = FeedService()
@StateObject private var commentService = CommentService()
@StateObject private var userProfileService = UserProfileService()
```

### Открыть комментарии:
```swift
.sheet(isPresented: $showComments) {
    CommentsView(post: post, commentService: commentService)
}
```

### Открыть профиль:
```swift
.sheet(isPresented: $showUserProfile) {
    UserProfileView(userId: userId, userProfileService: userProfileService)
}
```

---

## 🎯 TODO (для полной независимости)

- [ ] Вынести `Theme` в protocol (dependency injection)
- [ ] Создать `SocialTheme` для цветов
- [ ] Перевести все `internal` → `public`
- [ ] Добавить тесты
- [ ] Создать SPM Package
- [ ] Документация API
- [ ] Примеры использования

---

**Модуль готов к использованию и легко расширяется! 🎉**


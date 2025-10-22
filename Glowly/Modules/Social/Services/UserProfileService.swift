//
//  UserProfileService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

final class UserProfileService: ObservableObject {
    @Published var userProfiles: [String: SocialUserProfile] = [:] // userId: SocialUserProfile
    @Published var isLoading = false
    private var loadingUserIds: Set<String> = []

    func loadUserProfile(userId: String) {
        // Skip if already loaded or currently loading this specific user
        if userProfiles[userId] != nil || loadingUserIds.contains(userId) {
            return
        }

        loadingUserIds.insert(userId)
        isLoading = true

        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Mock data - в реальности загружаем с API
            self.userProfiles[userId] = self.getMockProfile(for: userId)
            self.loadingUserIds.remove(userId)
            self.isLoading = self.loadingUserIds.isEmpty
        }
    }

    // Generate mock profile based on userId
    private func getMockProfile(for userId: String) -> SocialUserProfile {
        switch userId {
        case "user1":
            return SocialUserProfile.mockProfile // Beauty by Anna
        case "store1":
            return self.createMockProfile(
                id: "store1",
                userName: "Sephora Russia",
                bio: "Официальный магазин Sephora 💄\nКрасота мирового уровня",
                isPremium: true,
                userType: .store,
                followers: 45230,
                following: 120,
                posts: 342
            )
        case "user2":
            return self.createMockProfile(
                id: "user2",
                userName: "Skincare with Maria",
                bio: "Бьюти-эксперт 🌸\nПомогу подобрать уход",
                isPremium: true,
                userType: .premium,
                followers: 8920,
                following: 450,
                posts: 156
            )
        case "user3":
            return self.createMockProfile(
                id: "user3",
                userName: "Makeup Artist Pro",
                bio: "Professional MUA 💋\nСвадебный и вечерний макияж",
                isPremium: false,
                userType: .regular,
                followers: 2340,
                following: 890,
                posts: 78
            )
        case "store2":
            return self.createMockProfile(
                id: "store2",
                userName: "MAC Cosmetics",
                bio: "Official MAC store 💄\nProfessional makeup for everyone",
                isPremium: true,
                userType: .store,
                followers: 67800,
                following: 50,
                posts: 567
            )
        default:
            // Fallback for any other userId
            return SocialUserProfile.mockProfile
        }
    }

    private func createMockProfile(id: String, userName: String, bio: String, isPremium: Bool, userType: Post.UserType, followers: Int, following: Int, posts: Int) -> SocialUserProfile {
        SocialUserProfile(
            id: id,
            userName: userName,
            bio: bio,
            avatar: nil,
            isPremium: isPremium,
            userType: userType,
            followersCount: followers,
            followingCount: following,
            postsCount: posts,
            isFollowing: false,
            cosmeticBagPreview: SocialUserProfile.mockProfile.cosmeticBagPreview // Reuse the same products for simplicity
        )
    }
    
    func toggleFollow(userId: String) {
        guard var profile = userProfiles[userId] else { return }
        profile.isFollowing.toggle()
        
        // Обновляем счетчик подписчиков
        if profile.isFollowing {
            profile.followersCount += 1
        } else {
            profile.followersCount = max(0, profile.followersCount - 1)
        }
        
        userProfiles[userId] = profile
    }
    
    func getUserProfile(userId: String) -> SocialUserProfile? {
        userProfiles[userId]
    }
}


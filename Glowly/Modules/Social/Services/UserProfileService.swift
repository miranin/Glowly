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
    
    func loadUserProfile(userId: String) {
        isLoading = true
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Mock data - в реальности загружаем с API
            self.userProfiles[userId] = SocialUserProfile.mockProfile
            self.isLoading = false
        }
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


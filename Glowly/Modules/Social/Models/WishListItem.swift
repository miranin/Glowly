//
//  WishListItem.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

struct WishListItem: Identifiable, Codable {
    let id: String
    let productId: String
    let productName: String
    let productBrand: String
    let category: SocialUserProfile.CosmeticCategory
    let imageUrl: String?
    let addedAt: Date
    let fromUserId: String
    let fromUserName: String
    
    init(
        id: String = UUID().uuidString,
        productId: String,
        productName: String,
        productBrand: String,
        category: SocialUserProfile.CosmeticCategory,
        imageUrl: String? = nil,
        addedAt: Date = Date(),
        fromUserId: String,
        fromUserName: String
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productBrand = productBrand
        self.category = category
        self.imageUrl = imageUrl
        self.addedAt = addedAt
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
    }
}


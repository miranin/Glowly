//
//  WishListService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

final class WishListService: ObservableObject {
    @Published var wishListItems: [WishListItem] = []
    
    func addToWishList(product: SocialUserProfile.ProductPreview, fromUser: SocialUserProfile) {
        // Проверяем, не добавлен ли уже
        if wishListItems.contains(where: { $0.productId == product.id }) {
            return
        }
        
        let item = WishListItem(
            productId: product.id,
            productName: product.name,
            productBrand: product.brand,
            category: product.category,
            imageUrl: product.imageUrl,
            fromUserId: fromUser.id,
            fromUserName: fromUser.userName
        )
        
        wishListItems.insert(item, at: 0)
    }
    
    func removeFromWishList(itemId: String) {
        wishListItems.removeAll { $0.id == itemId }
    }
    
    func isInWishList(productId: String) -> Bool {
        wishListItems.contains { $0.productId == productId }
    }
}


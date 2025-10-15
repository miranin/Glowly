//
//  AddEntryChooserView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

struct AddEntryChooserView: View {
    @ObservedObject var productStore: ProductStore
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingActionSheet = false
    @State private var presentManual = false
    @State private var presentCamera = false
    @State private var presentGallery = false
    @State private var pickedImage: UIImage?
    @State private var analyzed: AnalyzedProduct?
    private let recognition = ImageRecognitionService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.accent)
                Text(languageManager.translate("add_product_subtitle"))
                    .font(.title2).fontWeight(.bold)
                Text(languageManager.translate("add_product_description"))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingActionSheet = true }) {
                    Text(languageManager.currentLanguage == .russian ? "Выбрать способ" :
                         languageManager.currentLanguage == .english ? "Choose Method" :
                         "Әдісті таңдау")
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Theme.accentGradient)
                        .cornerRadius(22)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle(languageManager.translate("add_product_title"))
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text(languageManager.translate("add_product_title")),
                    buttons: [
                        .default(Text(languageManager.currentLanguage == .russian ? "Ввести вручную" :
                                     languageManager.currentLanguage == .english ? "Manual Entry" :
                                     "Қолмен енгізу")) { presentManual = true },
                        .default(Text(languageManager.translate("add_product_take_photo"))) { presentCamera = true },
                        .default(Text(languageManager.translate("add_product_choose_gallery"))) { presentGallery = true },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $presentManual) {
                AddProductSimpleView(productStore: productStore)
            }
            .sheet(isPresented: $presentCamera) {
                ImagePicker(selectedImage: $pickedImage, sourceType: .camera)
            }
            .sheet(isPresented: $presentGallery) {
                PhotoPicker(selectedImage: $pickedImage)
            }
            .onChange(of: pickedImage) { _ in
                guard let image = pickedImage else { return }
                // Ensure previous sheets are dismissed to avoid blank overlays
                presentGallery = false
                presentCamera = false
                recognition.recognizeText(from: image) { text in
                    recognition.analyzeProduct(from: image, recognizedText: text) { result in
                        DispatchQueue.main.async {
                            self.analyzed = AnalyzedProduct(analysis: result, image: image)
                        }
                    }
                }
            }
            .sheet(item: $analyzed) { item in
                ProductConfirmationView(
                    productStore: productStore,
                    analysis: item.analysis,
                    image: item.image,
                    onConfirmed: { analyzed = nil; pickedImage = nil }
                )
            }
        }
    }
}

private struct AnalyzedProduct: Identifiable {
    let id = UUID()
    let analysis: ProductAnalysis
    let image: UIImage?
}

#Preview { AddEntryChooserView(productStore: ProductStore()) }



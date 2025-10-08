//
//  AddEntryChooserView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

struct AddEntryChooserView: View {
    @ObservedObject var productStore: ProductStore
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
                Text("Как добавить продукт?")
                    .font(.title2).fontWeight(.bold)
                Text("Выберите способ добавления")
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingActionSheet = true }) {
                    Text("Выбрать способ")
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Theme.accentGradient)
                        .cornerRadius(22)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Добавить")
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Добавить"),
                    buttons: [
                        .default(Text("Ввести вручную")) { presentManual = true },
                        .default(Text("Сделать фото")) { presentCamera = true },
                        .default(Text("Выбрать из галереи")) { presentGallery = true },
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



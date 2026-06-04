//
//  AddEntryChooserView.swift
//  Glowly
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
    @State private var isAnalyzing = false
    @State private var pendingAnalysis: PendingAnalysis?
    @State private var analysisError: String?
    @State private var lastImage: UIImage?

    private let networkService = NetworkService()

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

                if isAnalyzing {
                    VStack(spacing: 10) {
                        ProgressView().tint(Theme.accent)
                        Text("AI анализирует фото...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 32)
                } else {
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
            .onChange(of: pickedImage) { _, newImage in
                guard let image = newImage else { return }
                presentGallery = false
                presentCamera = false
                Task { await analyzeWithBackend(image: image) }
            }
            .sheet(item: $pendingAnalysis) { pending in
                ProductConfirmationView(
                    productStore: productStore,
                    analysisResult: pending.result,
                    image: pending.image,
                    onConfirmed: {
                        pendingAnalysis = nil
                        pickedImage = nil
                    }
                )
            }
            .alert("AI-сервер недоступен", isPresented: .constant(analysisError != nil)) {
                Button("Повторить") {
                    if let img = lastImage {
                        analysisError = nil
                        Task { await analyzeWithBackend(image: img) }
                    }
                }
                Button("Ввести вручную") {
                    analysisError = nil
                    pendingAnalysis = PendingAnalysis(result: emptyResult(), image: lastImage)
                }
                Button("Отмена", role: .cancel) {
                    analysisError = nil
                    pickedImage = nil
                }
            } message: {
                Text(analysisError ?? "")
            }
        }
    }

    @MainActor
    private func analyzeWithBackend(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        isAnalyzing = true
        do {
            let result: AnalyzedProductResult = try await networkService.upload(
                AIEndpoints.analyzePublic,
                data: imageData,
                fileName: "product.jpg"
            )
            pendingAnalysis = PendingAnalysis(result: result, image: image)
        } catch {
            lastImage = image
            analysisError = "Не удалось связаться с AI-сервером.\nПроверьте, что телефон в той же Wi-Fi сети, что и сервер."
        }
        isAnalyzing = false
    }

    private func emptyResult() -> AnalyzedProductResult {
        AnalyzedProductResult(
            brand: "", productName: "", category: "other", applicationZone: "face",
            productDescription: "", keyIngredients: [], ingredients: [], ingredientsRaw: "",
            skinTypes: [], detectedConcerns: [], usageTime: "both",
            howToUse: "", benefits: [], warnings: [],
            isSensitiveSafe: false, isAcneSafe: true,
            confidence: 0.1, needsConfirmation: true, reasoning: "",
            dataSource: "vision", sourceUrl: "",
            ocrText: "", aiRawDescription: ""
        )
    }
}

private struct PendingAnalysis: Identifiable {
    let id = UUID()
    let result: AnalyzedProductResult
    let image: UIImage?
}

#Preview { AddEntryChooserView(productStore: ProductStore()) }

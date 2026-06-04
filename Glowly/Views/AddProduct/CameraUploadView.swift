//
//  CameraUploadView.swift
//  Glowly
//

import SwiftUI

struct CameraUploadView: View {
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) var dismiss

    @State private var presentCamera = false
    @State private var presentGallery = false
    @State private var pickedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var pendingAnalysis: PendingUploadAnalysis?
    @State private var analysisError: String?

    private let networkService = NetworkService()

    var body: some View {
        NavigationView {
            Group {
                if isAnalyzing {
                    ProductAnalyzingView(image: pickedImage)
                } else if let error = analysisError {
                    errorState(error)
                } else {
                    chooserState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Добавить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(.primary)
                    }
                }
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
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Chooser state

    private var chooserState: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 54, weight: .light))
                    .foregroundColor(Theme.accent)
            }

            VStack(spacing: 10) {
                Text("Добавить продукт")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Сфотографируйте упаковку — AI определит\nбренд, категорию и состав")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    presentCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Сделать фото")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    presentGallery = true
                } label: {
                    HStack {
                        Image(systemName: "photo")
                        Text("Выбрать из галереи")
                    }
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    // MARK: - Error state

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Не удалось распознать")
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    analysisError = nil
                    pickedImage = nil
                    presentCamera = true
                } label: {
                    Text("Сделать новое фото")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    analysisError = nil
                    pendingAnalysis = PendingUploadAnalysis(result: emptyResult(), image: pickedImage)
                } label: {
                    Text("Ввести вручную")
                        .font(.headline)
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private func emptyResult() -> AnalyzedProductResult {
        AnalyzedProductResult(
            brand: "", productName: "", category: "other", applicationZone: "face",
            productDescription: "", keyIngredients: [], ingredients: [], ingredientsRaw: "",
            skinTypes: [], detectedConcerns: [], usageTime: "both",
            howToUse: "", benefits: [], warnings: [],
            isSensitiveSafe: false, isAcneSafe: true,
            confidence: 0.0, needsConfirmation: true, reasoning: "",
            dataSource: "vision", sourceUrl: "",
            ocrText: "", aiRawDescription: ""
        )
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
            pendingAnalysis = PendingUploadAnalysis(result: result, image: image)
        } catch {
            analysisError = "AI-сервер недоступен.\nПроверьте подключение к сети или запустите локальный сервер."
        }
        isAnalyzing = false
    }
}

private struct PendingUploadAnalysis: Identifiable {
    let id = UUID()
    let result: AnalyzedProductResult
    let image: UIImage?
}

#Preview {
    CameraUploadView(productStore: ProductStore())
}

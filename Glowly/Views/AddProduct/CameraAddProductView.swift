//
//  CameraAddProductView.swift
//  Glowly
//

import SwiftUI

struct CameraAddProductView: View {
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var showingActionSheet = false
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingConfirmation = false
    @State private var backendResult: AnalyzedProductResult?
    @State private var isAnalyzing = false
    @State private var analysisError: String?

    private let networkService = NetworkService()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if selectedImage == nil {
                    placeholderView
                } else {
                    imageAnalysisView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(title: Text("Выберите источник"), buttons: [
                    .default(Text("Камера"))  { showingImagePicker = true },
                    .default(Text("Галерея")) { showingPhotoPicker = true },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingConfirmation) {
                if let result = backendResult {
                    ProductConfirmationView(
                        productStore: productStore,
                        analysisResult: result,
                        image: selectedImage,
                        onConfirmed: {
                            showingConfirmation = false
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(Theme.accent)

                VStack(spacing: 8) {
                    Text("Сфотографируй продукт")
                        .font(.title2.weight(.semibold))

                    Text("AI распознает бренд, состав и категорию")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "textformat.size", text: "Убедись, что название на этикетке четко видно")
                tipRow(icon: "sun.max", text: "Используй хорошее освещение")
                tipRow(icon: "camera.on.rectangle", text: "Держи камеру прямо перед продуктом")
            }
            .padding(20)
            .background(Color(.systemGray6).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { showingActionSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Сфотографировать")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Analysis view

    private var imageAnalysisView: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }

            if isAnalyzing {
                analyzingView
            } else if let result = backendResult {
                resultView(result)
            } else if let error = analysisError {
                errorView(error)
            }

            Spacer()
        }
        .onAppear {
            if selectedImage != nil && backendResult == nil && !isAnalyzing {
                Task { await analyzeWithBackend() }
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Theme.accent)

            VStack(spacing: 4) {
                Text("AI анализирует фото...")
                    .font(.headline)
                Text("Claude читает упаковку и определяет состав")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func resultView(_ result: AnalyzedProductResult) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                resultRow("Бренд",    result.brand.isEmpty ? "Не определён" : result.brand,      result.confidence)
                resultRow("Продукт",  result.productName.isEmpty ? "Не определён" : result.productName, result.confidence)
                resultRow("Категория", result.mappedCategory.rawValue, result.confidence)
                if !result.skinTypes.isEmpty {
                    resultRow("Тип кожи", result.skinTypes.joined(separator: ", "), result.confidence)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

            // Confidence bar
            confidenceBar(result.confidence)

            HStack(spacing: 12) {
                Button("Переснять") {
                    backendResult = nil
                    selectedImage = nil
                    analysisError = nil
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Подтвердить") {
                    showingConfirmation = true
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    private func resultRow(_ title: String, _ value: String, _ confidence: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func confidenceBar(_ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Уверенность AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(confidenceColor(value))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor(value))
                        .frame(width: geo.size.width * value, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func confidenceColor(_ v: Double) -> Color {
        if v >= 0.8 { return .green }
        if v >= 0.6 { return .orange }
        return .red
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Попробовать снова") {
                analysisError = nil
                selectedImage = nil
            }
            .foregroundColor(Theme.accent)
        }
        .padding(24)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Backend call

    @MainActor
    private func analyzeWithBackend() async {
        guard let image = selectedImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }

        isAnalyzing = true
        analysisError = nil

        do {
            let result: AnalyzedProductResult = try await networkService.upload(
                AIEndpoints.analyzePublic,
                data: imageData,
                fileName: "product.jpg"
            )
            backendResult = result
        } catch {
            analysisError = "Не удалось связаться с сервером.\nПроверьте подключение к сети."
        }

        isAnalyzing = false
    }
}

#Preview {
    CameraAddProductView(productStore: ProductStore())
}

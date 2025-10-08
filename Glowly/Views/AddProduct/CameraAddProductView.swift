//
//  CameraAddProductView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct CameraAddProductView: View {
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingActionSheet = false
    @State private var showingConfirmation = false
    @State private var recognizedText = ""
    @State private var productAnalysis: ProductAnalysis?
    @State private var isAnalyzing = false
    
    private let imageRecognitionService = ImageRecognitionService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if selectedImage == nil {
                    cameraPlaceholderView
                } else {
                    imageAnalysisView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Выберите источник"),
                    buttons: [
                        .default(Text("Камера")) {
                            showingImagePicker = true
                        },
                        .default(Text("Галерея")) {
                            showingPhotoPicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingConfirmation) {
                if let analysis = productAnalysis {
                    ProductConfirmationView(
                        productStore: productStore,
                        analysis: analysis,
                        image: selectedImage,
                        onConfirmed: {
                            // Dismiss confirmation then close camera flow
                            showingConfirmation = false
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    private var cameraPlaceholderView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                Text("Сфотографируй продукт")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("AI распознает название, бренд и категорию\nавтоматически")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Советы для лучшего распознавания:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "textformat", text: "Убедись, что текст на упаковке четко виден")
                    TipRow(icon: "lightbulb", text: "Используй хорошее освещение")
                    TipRow(icon: "camera", text: "Держи камеру прямо над продуктом")
                    TipRow(icon: "doc.text", text: "Сфотографируй этикетку с названием")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Camera Button
            Button(action: { showingActionSheet = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Сфотографировать")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.bottom, 40)
        }
    }
    
    private var imageAnalysisView: some View {
        VStack(spacing: 20) {
            // Image Preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            }
            
            if isAnalyzing {
                analyzingView
            } else if let analysis = productAnalysis {
                analysisResultView(analysis)
            } else {
                analyzeButtonView
            }
            
            Spacer()
        }
        .onAppear {
            if selectedImage != nil && productAnalysis == nil {
                analyzeImage()
            }
        }
    }
    
    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.pink)
            
            Text("AI анализирует фото...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Распознаем текст и определяем категорию")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
    
    private func analysisResultView(_ analysis: ProductAnalysis) -> some View {
        VStack(spacing: 16) {
            Text("AI нашел продукт!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    title: "Бренд",
                    value: analysis.brand.isEmpty ? "Не определен" : analysis.brand,
                    confidence: analysis.brand.isEmpty ? 0 : analysis.confidence
                )
                
                AnalysisRow(
                    title: "Название",
                    value: analysis.productName.isEmpty ? "Не определено" : analysis.productName,
                    confidence: analysis.productName.isEmpty ? 0 : analysis.confidence
                )
                
                AnalysisRow(
                    title: "Категория",
                    value: analysis.category.rawValue,
                    confidence: analysis.confidence
                )
                
                if !analysis.shade.isEmpty {
                    AnalysisRow(
                        title: "Оттенок",
                        value: analysis.shade,
                        confidence: 0.6
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            
            HStack(spacing: 12) {
                Button("Исправить") {
                    // Reset analysis to allow re-analysis
                    productAnalysis = nil
                    selectedImage = nil
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                
                Button("Подтвердить") {
                    showingConfirmation = true
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var analyzeButtonView: some View {
        VStack(spacing: 16) {
            Text("Готово к анализу")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button("Анализировать фото") {
                analyzeImage()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .disabled(isAnalyzing)
        }
        .padding(20)
    }
    
    private func analyzeImage() {
        guard let image = selectedImage, !isAnalyzing else { return }
        
        isAnalyzing = true
        
        imageRecognitionService.recognizeText(from: image) { text in
            self.recognizedText = text
            self.imageRecognitionService.analyzeProduct(from: image, recognizedText: text) { analysis in
                self.productAnalysis = analysis
                self.isAnalyzing = false
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let confidence: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if confidence > 0 {
                Text("\(Int(confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(confidenceColor)
                    )
            }
        }
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

#Preview {
    CameraAddProductView(productStore: ProductStore())
}

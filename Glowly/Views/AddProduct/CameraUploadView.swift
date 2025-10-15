//
//  CameraUploadView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct CameraUploadView: View {
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) var dismiss
    @State private var presentCamera = false
    @State private var presentGallery = false
    @State private var pickedImage: UIImage?
    @State private var analyzed: AnalyzedProduct?
    private let recognition = ImageRecognitionService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.accent)
                
                VStack(spacing: 12) {
                    Text("Добавить продукт")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Сфотографируйте или выберите из галереи")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        presentCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Сделать фото")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        presentGallery = true
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                            Text("Выбрать из галереи")
                        }
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Добавить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $presentCamera) {
                ImagePicker(selectedImage: $pickedImage, sourceType: .camera)
            }
            .sheet(isPresented: $presentGallery) {
                PhotoPicker(selectedImage: $pickedImage)
            }
            .onChange(of: pickedImage) { oldValue, newValue in
                guard let image = newValue else { return }
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
                    onConfirmed: {
                        analyzed = nil
                        pickedImage = nil
                        dismiss()
                    }
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

#Preview {
    CameraUploadView(productStore: ProductStore())
}


//
//  BarcodeScannerView.swift
//  Felyro
//
//  Created by Martin Horáček on 28.05.2025.
//

import SwiftUI
import AVFoundation
import PhotosUI
import Vision
import Photos

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String? = nil
    @State private var isTorchOn = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCameraPermissionAlert = false
    @State private var showPhotoPermissionAlert = false
    @State private var cameraPermissionGranted = false
    @State private var presentPhotosPicker = false

    var completion: (String) -> Void

    var body: some View {
        ZStack {
            if cameraPermissionGranted {
                CameraPreview(isTorchOn: $isTorchOn, onCodeScanned: { code in
                    scannedCode = code
                    completion(code)
                    dismiss()
                })
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding([.leading, .top])

                    Spacer()
                }

                Spacer()

                if cameraPermissionGranted {
                    HStack(spacing: 20) {
                        Button(action: { isTorchOn.toggle() }) {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Button {
                            checkPhotoPermission { granted in
                                if granted {
                                    presentPhotosPicker = true
                                } else {
                                    showPhotoPermissionAlert = true
                                }
                            }
                        } label: {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            checkCameraPermission { granted in
                cameraPermissionGranted = granted
                if !granted {
                    showCameraPermissionAlert = true
                }
            }
        }
        .photosPicker(isPresented: $presentPhotosPicker, selection: $selectedItem, matching: .images)
        .task(id: selectedItem) {
            guard let item = selectedItem else { return }

            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    detectBarcode(in: uiImage)
                }
            } catch {
                print("Chyba při načítání fotky: \(error)")
            }
        }
        .alert(String(localized: "camera_permission"), isPresented: $showCameraPermissionAlert) {
            Button(String(localized: "open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "close"), role: .cancel) {
                dismiss()
            }
        } message: {
            Text(String(localized: "need_access_to_camera"))
        }
        .alert(String(localized: "photo_permission"), isPresented: $showPhotoPermissionAlert) {
            Button(String(localized: "open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "close"), role: .cancel) {
                dismiss()
            }
        } message: {
            Text(String(localized: "need_access_to_photos"))
        }
    }

    private func detectBarcode(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation],
               let payload = results.first?.payloadStringValue {
                scannedCode = payload
                completion(payload)
                dismiss()
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func checkPhotoPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var isTorchOn: Bool
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.setTorch(isTorchOn)
    }
}

// MARK: - UIKit Scanner

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private let session = AVCaptureSession()
    private let preview = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        if device.isFocusModeSupported(.continuousAutoFocus) {
            try? device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .code128, .qr]
        }

        preview.session = session
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadata.stringValue {
            session.stopRunning()
            onCodeScanned?(code)
        }
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

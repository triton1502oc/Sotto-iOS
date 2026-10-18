import SwiftUI
import AVFoundation
import PhotosUI

public struct QRScannerModal: View {
    public let onScan: (_ dataString: String) -> Void
    public let onDismiss: () -> Void
    
    @State private var manualInput: String = ""
    @State private var hasCameraPermission: Bool = true
    @State private var cameraUnavailable: Bool = false
    @State private var detectedClipboardDeck: String? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var qrImageDecodeError: String? = nil
    
    public init(
        onScan: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onScan = onScan
        self.onDismiss = onDismiss
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle")
                Text(LocaleHelper.getPickQRImageLabel(appLanguage: UserDefaultsVoiceSettingsRepository().getVoiceSettings().appLanguage))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SottoTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(SottoTheme.surfaceVariant)
            .cornerRadius(10)
        }
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let clipDeck = detectedClipboardDeck {
                        Button(action: {
                            onScan(clipDeck)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .foregroundColor(SottoTheme.successText)
                                Text("Import Deck from Clipboard")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(SottoTheme.successText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SottoTheme.successText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(SottoTheme.successContainer)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }
                    }
                    
                    if let decodeErr = qrImageDecodeError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(SottoTheme.warningAmber)
                            Text(decodeErr)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SottoTheme.textPrimary)
                            Spacer()
                            Button(action: { qrImageDecodeError = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SottoTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                    
                    if cameraUnavailable || !hasCameraPermission {
                        // Fallback: Manual / Paste Input
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(SottoTheme.textSecondary)
                                .padding(.top, 24)
                            
                            Text("Camera Unavailable")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            Text("Camera access is not supported on this device/simulator, or permission was denied. You can paste deck data directly:")
                                .font(.system(size: 14))
                                .foregroundColor(SottoTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                TextEditor(text: $manualInput)
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(SottoTheme.surfaceVariant)
                                    .cornerRadius(10)
                                    .foregroundColor(SottoTheme.textPrimary)
                                
                                HStack(spacing: 10) {
                                    photoPickerButton
                                    
                                    Button(action: {
                                        if let clip = UIPasteboard.general.string {
                                            manualInput = clip
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "doc.on.clipboard")
                                            Text("Paste")
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SottoTheme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .frame(height: 44)
                                        .background(SottoTheme.surfaceVariant)
                                        .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        let clean = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !clean.isEmpty {
                                            onScan(clean)
                                        }
                                    }) {
                                        Text("Import Deck")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(SottoTheme.onPrimary)
                                            .padding(.horizontal, 18)
                                            .frame(height: 44)
                                            .background(!manualInput.isEmpty ? SottoTheme.primary : SottoTheme.surfaceVariant)
                                            .cornerRadius(10)
                                    }
                                    .disabled(manualInput.isEmpty)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        // Live Camera Scanner
                        VStack(spacing: 16) {
                            Text("Point camera at a Sotto deck QR code")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                                .padding(.top, 12)
                            
                            CameraScannerPreview(onCodeFound: { code in
                                #if canImport(UIKit)
                                let feedback = UINotificationFeedbackGenerator()
                                feedback.notificationOccurred(.success)
                                #endif
                                onScan(code)
                            })
                            .frame(maxWidth: .infinity)
                            .frame(height: 320)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(SottoTheme.primary.opacity(0.4), lineWidth: 2)
                            )
                            .padding(.horizontal, 20)
                            
                            // Photo Picker & Paste Options Below Camera
                            HStack(spacing: 12) {
                                photoPickerButton
                                
                                Button(action: {
                                    if let clip = UIPasteboard.general.string, !clip.isEmpty {
                                        onScan(clip)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Paste from Clipboard")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .frame(height: 44)
                                    .background(SottoTheme.surfaceVariant)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Scan QR Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(SottoTheme.textSecondary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let item = newItem else { return }
            qrImageDecodeError = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let decoded = QRCodeImageHelper.decodeQRFromImage(uiImage),
                   !decoded.isEmpty {
                    await MainActor.run {
                        let settings = UserDefaultsVoiceSettingsRepository().getVoiceSettings()
                        UsabilityTracker.shared.recordActivation(key: "qr_image_imported", voiceSettings: settings)
                        onScan(decoded)
                    }
                } else {
                    await MainActor.run {
                        let settings = UserDefaultsVoiceSettingsRepository().getVoiceSettings()
                        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: settings.appLanguage) == LocaleHelper.langIndonesian
                        qrImageDecodeError = isId
                            ? "Tidak ditemukan kode QR Sotto yang valid pada gambar yang dipilih."
                            : "No valid Sotto QR code found in the selected image."
                    }
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
        .onAppear {
            checkCameraAvailability()
            if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
               clip.hasPrefix("SOTTO:v1:") {
                detectedClipboardDeck = clip
            }
        }
    }
    
    private func checkCameraAvailability() {
        #if targetEnvironment(simulator)
        cameraUnavailable = true
        #else
        guard AVCaptureDevice.default(for: .video) != nil else {
            cameraUnavailable = true
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.hasCameraPermission = granted
                }
            }
        default:
            hasCameraPermission = false
        }
        #endif
    }
}

// MARK: - Camera Scanner View

private struct CameraScannerPreview: UIViewControllerRepresentable {
    let onCodeFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeFound: onCodeFound)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeFound: (String) -> Void
        private var hasScanned = false
        
        init(onCodeFound: @escaping (String) -> Void) {
            self.onCodeFound = onCodeFound
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = metadataObject.stringValue else {
                return
            }
            hasScanned = true
            DispatchQueue.main.async {
                self.onCodeFound(stringValue)
            }
        }
    }
}

private class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        
        let session = AVCaptureSession()
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        
        self.previewLayer = preview
        self.captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }
}

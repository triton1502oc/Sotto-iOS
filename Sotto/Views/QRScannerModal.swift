import SwiftUI
import AVFoundation

public struct QRScannerModal: View {
    public let onScan: (_ dataString: String) -> Void
    public let onDismiss: () -> Void
    
    @State private var manualInput: String = ""
    @State private var hasCameraPermission: Bool = true
    @State private var cameraUnavailable: Bool = false
    
    public init(
        onScan: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onScan = onScan
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
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
                                
                                HStack(spacing: 12) {
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
                                            .padding(.horizontal, 20)
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
                            
                            // Paste Option Below Camera
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
        .onAppear {
            checkCameraAvailability()
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

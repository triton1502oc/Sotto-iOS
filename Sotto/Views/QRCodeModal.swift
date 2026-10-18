import SwiftUI
import CoreImage.CIFilterBuiltins

public struct QRCodeModal: View {
    public let title: String
    public let subtitle: String
    public let dataString: String
    public let onDismiss: () -> Void
    
    @State private var qrImage: UIImage?
    @State private var generationFailed: Bool = false
    @State private var copied: Bool = false
    
    public init(
        title: String,
        subtitle: String = "",
        dataString: String,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.dataString = dataString
        self.onDismiss = onDismiss
    }
    
    private var dataByteSizeString: String {
        let count = dataString.utf8.count
        if count >= 1024 {
            return String(format: "%.1f KB", Double(count) / 1024.0)
        }
        return "\(count) bytes"
    }
    
    private func generateQRCode(from text: String) -> UIImage? {
        let data = Data(text.utf8)
        guard data.count <= 2800 else { return nil }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(SottoTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(SottoTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 16)
                    
                    // QR Code Card
                    VStack {
                        if let image = qrImage {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        } else if generationFailed {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(SottoTheme.warningAmber)
                                Text("Data Exceeds QR Capacity")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                Text("This deck contains \(dataByteSizeString), which exceeds the optical QR camera limit (~2.5 KB). Please use 'Copy Deck Data' or export as a .sotto file via AirDrop / Files.")
                                    .font(.system(size: 12))
                                    .foregroundColor(SottoTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 14)
                            }
                            .frame(width: 240, height: 240)
                            .background(SottoTheme.surfaceVariant)
                            .cornerRadius(16)
                        } else {
                            ProgressView()
                                .frame(width: 220, height: 220)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(16)
                        }
                    }
                    
                    Text("Scan with another device camera or Sotto app to instantly import.")
                        .font(.system(size: 13))
                        .foregroundColor(SottoTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Share & Copy Buttons
                    HStack(spacing: 12) {
                        if let image = qrImage {
                            Button(action: {
                                let settings = UserDefaultsVoiceSettingsRepository().getVoiceSettings()
                                QRCodeImageHelper.shareQRImage(
                                    qrImage: image,
                                    title: title,
                                    subtitle: subtitle,
                                    dataString: dataString,
                                    appLanguage: settings.appLanguage,
                                    voiceSettings: settings
                                )
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(LocaleHelper.getShareQRImageLabel(appLanguage: UserDefaultsVoiceSettingsRepository().getVoiceSettings().appLanguage))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(SottoTheme.onPrimary)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(SottoTheme.primary)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            UIPasteboard.general.string = dataString
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 15, weight: .semibold))
                                Text(copied ? "Copied to Clipboard" : "Copy Deck Data")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(SottoTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(SottoTheme.surfaceVariant)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(SottoTheme.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if let image = generateQRCode(from: dataString) {
                qrImage = image
            } else {
                generationFailed = true
            }
        }
    }
}

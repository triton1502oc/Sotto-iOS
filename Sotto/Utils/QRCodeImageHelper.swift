import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

public enum QRCodeImageHelper {
    public static let canvasSizePx: CGFloat = 1080
    private static let outerMarginPx: CGFloat = 48
    private static let cardCornerRadiusPx: CGFloat = 48

    public static func generateRawQRImage(from payload: String, scale: CGFloat = 12) -> UIImage? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let data = Data(trimmed.utf8)
        guard data.count <= 2800 else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    public static func renderBrandedQRCardImage(
        qrImage: UIImage,
        title: String,
        subtitle: String = "",
        payloadByteCount: Int,
        footerBrandText: String = "Sotto • Assistive Communication"
    ) -> UIImage {
        let size = CGSize(width: canvasSizePx, height: canvasSizePx)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext

            let outerBgColor = UIColor(red: 0x0D / 255.0, green: 0x0F / 255.0, blue: 0x12 / 255.0, alpha: 1.0)
            let cardBgColor = UIColor(red: 0x16 / 255.0, green: 0x19 / 255.0, blue: 0x20 / 255.0, alpha: 1.0)
            let borderColor = UIColor(red: 0x2A / 255.0, green: 0x30 / 255.0, blue: 0x3C / 255.0, alpha: 1.0)
            let titleColor = UIColor(red: 0xF3 / 255.0, green: 0xF6 / 255.0, blue: 0xFA / 255.0, alpha: 1.0)
            let subtitleColor = UIColor(red: 0x90 / 255.0, green: 0xCA / 255.0, blue: 0xF9 / 255.0, alpha: 1.0)
            let footerColor = UIColor(red: 0x8B / 255.0, green: 0x95 / 255.0, blue: 0xA5 / 255.0, alpha: 1.0)

            outerBgColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            let cardRect = CGRect(
                x: outerMarginPx,
                y: outerMarginPx,
                width: canvasSizePx - outerMarginPx * 2,
                height: canvasSizePx - outerMarginPx * 2
            )
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadiusPx)
            cardBgColor.setFill()
            cardPath.fill()

            borderColor.setStroke()
            cardPath.lineWidth = 3.0
            cardPath.stroke()

            let contentLeft = cardRect.minX + 64
            let contentWidth = cardRect.width - 128
            var currentY = cardRect.minY + 64

            let centerStyle = NSMutableParagraphStyle()
            centerStyle.alignment = .center

            // Title
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sotto QR Deck" : title.trimmingCharacters(in: .whitespacesAndNewlines)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                .foregroundColor: titleColor,
                .paragraphStyle: centerStyle
            ]
            let titleSize = (cleanTitle as NSString).size(withAttributes: titleAttrs)
            let titleRect = CGRect(x: contentLeft, y: currentY, width: contentWidth, height: titleSize.height + 6)
            (cleanTitle as NSString).draw(in: titleRect, withAttributes: titleAttrs)
            currentY = titleRect.maxY + 12

            // Optional Subtitle
            let cleanSub = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanSub.isEmpty {
                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 26, weight: .medium),
                    .foregroundColor: subtitleColor,
                    .paragraphStyle: centerStyle
                ]
                let subBounds = (cleanSub as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: 80),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: subAttrs,
                    context: nil
                )
                let subRect = CGRect(x: contentLeft, y: currentY, width: contentWidth, height: ceil(subBounds.height) + 4)
                (cleanSub as NSString).draw(in: subRect, withAttributes: subAttrs)
                currentY = subRect.maxY + 24
            } else {
                currentY += 16
            }

            // Footer with Sotto icon + brand text
            let iconSize: CGFloat = 44
            let footerTopY = cardRect.maxY - 40 - iconSize
            CardShareHelper.drawSottoBrandFooter(
                in: cgContext,
                centerX: canvasSizePx / 2.0,
                topY: footerTopY,
                iconSize: iconSize,
                brandText: footerBrandText
            )

            // Payload size label above footer
            let sizeStr: String
            if payloadByteCount >= 1024 {
                sizeStr = String(format: "%.1f KB payload", Double(payloadByteCount) / 1024.0)
            } else {
                sizeStr = "\(payloadByteCount) bytes payload"
            }
            let sizeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                .foregroundColor: footerColor,
                .paragraphStyle: centerStyle
            ]
            let sizeLabelDim = (sizeStr as NSString).size(withAttributes: sizeAttrs)
            let sizeRect = CGRect(
                x: contentLeft,
                y: footerTopY - sizeLabelDim.height - 14,
                width: contentWidth,
                height: sizeLabelDim.height
            )
            (sizeStr as NSString).draw(in: sizeRect, withAttributes: sizeAttrs)

            // White QR Squircle in center
            let bottomLimit = sizeRect.minY - 24
            let availableSquareSpace = max(min(bottomLimit - currentY, 640), 480)
            let qrBoxSize = min(availableSquareSpace, 600)
            let qrBoxX = (canvasSizePx - qrBoxSize) / 2.0
            let qrBoxY = currentY + max((bottomLimit - currentY - qrBoxSize) / 2.0, 0)
            let qrBoxRect = CGRect(x: qrBoxX, y: qrBoxY, width: qrBoxSize, height: qrBoxSize)

            let qrBoxPath = UIBezierPath(roundedRect: qrBoxRect, cornerRadius: 32)
            UIColor.white.setFill()
            qrBoxPath.fill()

            let inset: CGFloat = 28
            let qrDrawRect = qrBoxRect.insetBy(dx: inset, dy: inset)
            cgContext.interpolationQuality = .none
            qrImage.draw(in: qrDrawRect)
        }
    }

    public static func decodeQRFromImage(_ image: UIImage) -> String? {
        if let ciImage = CIImage(image: image) ?? image.cgImage.map({ CIImage(cgImage: $0) }) {
            let context = CIContext()
            if let detector = CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: context,
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            ) {
                let features = detector.features(in: ciImage)
                for case let qrFeature as CIQRCodeFeature in features {
                    if let msg = qrFeature.messageString?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !msg.isEmpty {
                        return msg
                    }
                }
            }
        }

        guard let cgImage = image.cgImage else { return nil }
        var detectedPayload: String?
        let request = VNDetectBarcodesRequest { req, _ in
            guard let results = req.results as? [VNBarcodeObservation] else { return }
            for obs in results where obs.symbology == .qr {
                if let payload = obs.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !payload.isEmpty {
                    detectedPayload = payload
                    break
                }
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return detectedPayload
    }

    @MainActor
    public static func shareQRImage(
        qrImage: UIImage,
        title: String,
        subtitle: String,
        dataString: String,
        appLanguage: String,
        voiceSettings: VoiceSettings
    ) {
        UsabilityTracker.shared.startIntent("share_qr_image")
        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
        let footerText = isId ? "Sotto • Komunikasi Asistif" : "Sotto • Assistive Communication"
        let caption = isId
            ? "QR Dek Frasa Sotto — Buka Sotto → Pengaturan → Impor via Kode QR → Pilih Gambar QR (atau bagikan gambar ini langsung ke Sotto)."
            : "Sotto Phrase Deck QR — Open Sotto → Settings → Import via QR Code → Pick QR Image (or share this image directly to Sotto)."

        let branded = renderBrandedQRCardImage(
            qrImage: qrImage,
            title: title,
            subtitle: subtitle,
            payloadByteCount: dataString.utf8.count,
            footerBrandText: footerText
        )

        guard let pngData = branded.pngData() else {
            UsabilityTracker.shared.endIntent(
                "share_qr_image",
                outcome: "aborted",
                frictionTag: "share_error",
                contextTag: "qr_dialog",
                voiceSettings: voiceSettings
            )
            return
        }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("shared_cards", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("sotto_qr_deck.png")

        do {
            try pngData.write(to: fileURL, options: .atomic)
            CardShareHelper.presentActivitySheet(items: [fileURL, caption])
            UsabilityTracker.shared.recordActivation(key: "qr_image_shared", voiceSettings: voiceSettings)
            UsabilityTracker.shared.endIntent(
                "share_qr_image",
                outcome: "shared",
                contextTag: "qr_dialog",
                voiceSettings: voiceSettings
            )
        } catch {
            UsabilityTracker.shared.endIntent(
                "share_qr_image",
                outcome: "aborted",
                frictionTag: "share_error",
                contextTag: "qr_dialog",
                voiceSettings: voiceSettings
            )
        }
    }
}

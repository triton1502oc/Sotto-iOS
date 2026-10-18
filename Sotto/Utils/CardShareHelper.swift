import Foundation
import UIKit

public struct ShareableCardSpec: Equatable {
    public let primaryText: String
    public let secondaryText: String?
    public let badgeLabel: String?
    public let isEmergency: Bool
    public let footerBrandText: String

    public init(
        primaryText: String,
        secondaryText: String? = nil,
        badgeLabel: String? = nil,
        isEmergency: Bool = false,
        footerBrandText: String = "Sotto • Assistive Communication"
    ) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.badgeLabel = badgeLabel
        self.isEmergency = isEmergency
        self.footerBrandText = footerBrandText
    }
}

public enum CardShareHelper {
    public static let canvasSizePx: CGFloat = 1080
    private static let outerMarginPx: CGFloat = 48
    private static let cardCornerRadiusPx: CGFloat = 48
    private static let innerPaddingHorizontalPx: CGFloat = 80
    private static let innerPaddingTopPx: CGFloat = 72
    private static let innerPaddingBottomPx: CGFloat = 68

    public static func buildShareCaption(_ spec: ShareableCardSpec) -> String {
        let primary = spec.primaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let secondary = spec.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let badge = spec.badgeLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var lines: [String] = []
        if !badge.isEmpty {
            let prefix = spec.isEmergency ? "🛡️ " : ""
            lines.append("[\(prefix)\(badge)]")
        }
        lines.append(primary)
        if !secondary.isEmpty {
            lines.append("")
            lines.append(secondary)
        }
        return lines.joined(separator: "\n")
    }

    public static func primaryFontSizePx(for length: Int, hasSecondary: Bool) -> CGFloat {
        let base: CGFloat
        if length <= 25 {
            base = 68
        } else if length <= 60 {
            base = 56
        } else if length <= 120 {
            base = 46
        } else if length <= 200 {
            base = 38
        } else {
            base = 32
        }
        return hasSecondary ? max(base * 0.9, 30) : base
    }

    public static func renderCardImage(_ spec: ShareableCardSpec) -> UIImage {
        let size = CGSize(width: canvasSizePx, height: canvasSizePx)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext

            let outerBgColor = UIColor(red: 0x0D / 255.0, green: 0x0F / 255.0, blue: 0x12 / 255.0, alpha: 1.0)
            let cardBgColor = spec.isEmergency
                ? UIColor(red: 0x2A / 255.0, green: 0x12 / 255.0, blue: 0x15 / 255.0, alpha: 1.0)
                : UIColor(red: 0x16 / 255.0, green: 0x19 / 255.0, blue: 0x20 / 255.0, alpha: 1.0)
            let borderColor = spec.isEmergency
                ? UIColor(red: 0xFF / 255.0, green: 0x52 / 255.0, blue: 0x52 / 255.0, alpha: 1.0)
                : UIColor(red: 0x2A / 255.0, green: 0x30 / 255.0, blue: 0x3C / 255.0, alpha: 1.0)
            let primaryColor = spec.isEmergency
                ? UIColor(red: 0xFF / 255.0, green: 0xEB / 255.0, blue: 0xEE / 255.0, alpha: 1.0)
                : UIColor(red: 0xF3 / 255.0, green: 0xF6 / 255.0, blue: 0xFA / 255.0, alpha: 1.0)
            let secondaryColor = UIColor(red: 0x90 / 255.0, green: 0xCA / 255.0, blue: 0xF9 / 255.0, alpha: 1.0)
            let dividerColor = UIColor(red: 0x26 / 255.0, green: 0x2C / 255.0, blue: 0x36 / 255.0, alpha: 1.0)

            // Outer background
            outerBgColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Card container
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
            cardPath.lineWidth = spec.isEmergency ? 5.0 : 3.0
            cardPath.stroke()

            let contentLeft = cardRect.minX + innerPaddingHorizontalPx
            let contentRight = cardRect.maxX - innerPaddingHorizontalPx
            let contentWidth = contentRight - contentLeft
            var topBound = cardRect.minY + innerPaddingTopPx

            // Optional top badge pill
            if let rawBadge = spec.badgeLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !rawBadge.isEmpty {
                let badgeText = spec.isEmergency ? "🛡️ \(rawBadge.uppercased())" : rawBadge.uppercased()
                let badgeFont = UIFont.systemFont(ofSize: 24, weight: .bold)
                let badgeFgColor = spec.isEmergency
                    ? UIColor(red: 0xFF / 255.0, green: 0x8A / 255.0, blue: 0x80 / 255.0, alpha: 1.0)
                    : UIColor(red: 0x90 / 255.0, green: 0xCA / 255.0, blue: 0xF9 / 255.0, alpha: 1.0)
                let badgeBgColor = spec.isEmergency
                    ? UIColor(red: 0x4A / 255.0, green: 0x1A / 255.0, blue: 0x1F / 255.0, alpha: 1.0)
                    : UIColor(red: 0x22 / 255.0, green: 0x2A / 255.0, blue: 0x38 / 255.0, alpha: 1.0)

                let badgeAttrs: [NSAttributedString.Key: Any] = [
                    .font: badgeFont,
                    .foregroundColor: badgeFgColor
                ]
                let textSize = (badgeText as NSString).size(withAttributes: badgeAttrs)
                let pillPadH: CGFloat = 28
                let pillHeight: CGFloat = 54
                let pillWidth = min(textSize.width + pillPadH * 2, contentWidth)
                let pillRect = CGRect(
                    x: (canvasSizePx - pillWidth) / 2.0,
                    y: topBound,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: pillHeight / 2.0)
                badgeBgColor.setFill()
                pillPath.fill()

                let textRect = CGRect(
                    x: pillRect.minX + (pillWidth - textSize.width) / 2.0,
                    y: pillRect.minY + (pillHeight - textSize.height) / 2.0,
                    width: textSize.width,
                    height: textSize.height
                )
                (badgeText as NSString).draw(in: textRect, withAttributes: badgeAttrs)
                topBound = pillRect.maxY + 36
            }

            // Footer branding + divider
            let footerBottom = cardRect.maxY - innerPaddingBottomPx
            let iconSize: CGFloat = 44
            let footerTopY = footerBottom - iconSize
            drawSottoBrandFooter(
                in: cgContext,
                centerX: canvasSizePx / 2.0,
                topY: footerTopY,
                iconSize: iconSize,
                brandText: spec.footerBrandText
            )

            let dividerY = footerTopY - 28
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: contentLeft, y: dividerY))
            dividerPath.addLine(to: CGPoint(x: contentRight, y: dividerY))
            dividerColor.setStroke()
            dividerPath.lineWidth = 2.0
            dividerPath.stroke()

            let bottomBound = dividerY - 36
            let availableHeight = max(bottomBound - topBound, 200)

            let cleanPrimary = spec.primaryText.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanSecondary = spec.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let hasSecondary = !cleanSecondary.isEmpty

            let primaryFont = UIFont.systemFont(
                ofSize: primaryFontSizePx(for: cleanPrimary.count, hasSecondary: hasSecondary),
                weight: .bold
            )
            let primaryStyle = NSMutableParagraphStyle()
            primaryStyle.alignment = .center
            primaryStyle.lineSpacing = 8
            let primaryAttrs: [NSAttributedString.Key: Any] = [
                .font: primaryFont,
                .foregroundColor: primaryColor,
                .paragraphStyle: primaryStyle
            ]

            let primaryBounds = (cleanPrimary as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: availableHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: primaryAttrs,
                context: nil
            )

            var secondaryBounds = CGRect.zero
            var secondaryAttrs: [NSAttributedString.Key: Any] = [:]
            let gapBetween: CGFloat = hasSecondary ? 36 : 0

            if hasSecondary {
                let secondaryFont = UIFont.systemFont(
                    ofSize: cleanSecondary.count > 80 ? 30 : 36,
                    weight: .medium
                )
                let secondaryStyle = NSMutableParagraphStyle()
                secondaryStyle.alignment = .center
                secondaryStyle.lineSpacing = 6
                secondaryAttrs = [
                    .font: secondaryFont,
                    .foregroundColor: secondaryColor,
                    .paragraphStyle: secondaryStyle
                ]
                secondaryBounds = (cleanSecondary as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: availableHeight * 0.45),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: secondaryAttrs,
                    context: nil
                )
            }

            let totalTextHeight = ceil(primaryBounds.height) + gapBetween + ceil(secondaryBounds.height)
            let startY = topBound + max((availableHeight - totalTextHeight) / 2.0, 0)

            let primaryDrawRect = CGRect(
                x: contentLeft,
                y: startY,
                width: contentWidth,
                height: min(ceil(primaryBounds.height) + 8, availableHeight)
            )
            (cleanPrimary as NSString).draw(
                with: primaryDrawRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: primaryAttrs,
                context: nil
            )

            if hasSecondary {
                let secondaryStartY = startY + ceil(primaryBounds.height) + gapBetween
                let secondaryDrawRect = CGRect(
                    x: contentLeft,
                    y: secondaryStartY,
                    width: contentWidth,
                    height: min(ceil(secondaryBounds.height) + 8, max(bottomBound - secondaryStartY, 40))
                )
                (cleanSecondary as NSString).draw(
                    with: secondaryDrawRect,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: secondaryAttrs,
                    context: nil
                )
            }
        }
    }

    public static func loadAppIconImage() -> UIImage? {
        // 1. Direct dedicated asset catalog image
        if let image = UIImage(named: "SottoBrandIcon") {
            return image
        }
        // 2. Query CFBundleIcons~ipad or CFBundleIcons from Info.plist
        let info = Bundle.main.infoDictionary
        let iconsDict = (info?["CFBundleIcons~ipad"] as? [String: Any]) ?? (info?["CFBundleIcons"] as? [String: Any])
        if let primary = iconsDict?["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] {
            for fileName in files.reversed() {
                if let image = UIImage(named: fileName) {
                    return image
                }
                if let path = Bundle.main.path(forResource: fileName, ofType: "png"),
                   let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
        }
        // 3. Fallback standard icon names
        if let image = UIImage(named: "AppIcon") ?? UIImage(named: "AppIcon76x76") ?? UIImage(named: "AppIcon60x60") {
            return image
        }
        // 4. Scan bundle root for compiled AppIcon pngs
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let items = try? fm.contentsOfDirectory(atPath: resourcePath) {
                let iconFiles = items.filter { $0.hasPrefix("AppIcon") && $0.hasSuffix(".png") }.sorted()
                if let last = iconFiles.last,
                   let image = UIImage(contentsOfFile: (resourcePath as NSString).appendingPathComponent(last)) {
                    return image
                }
            }
        }
        return nil
    }

    public static func drawSottoBrandFooter(
        in cgContext: CGContext,
        centerX: CGFloat,
        topY: CGFloat,
        iconSize: CGFloat,
        brandText: String
    ) {
        let footerColor = UIColor(red: 0x8B / 255.0, green: 0x95 / 255.0, blue: 0xA5 / 255.0, alpha: 1.0)
        let footerFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: footerColor,
            .kern: 0.48
        ]
        let nsBrand = brandText as NSString
        let textSize = nsBrand.size(withAttributes: footerAttrs)
        let gap: CGFloat = 14.0
        let totalWidth = iconSize + gap + textSize.width
        let startX = centerX - (totalWidth / 2.0)
        let badgeRect = CGRect(x: startX, y: topY, width: iconSize, height: iconSize)

        if let appIcon = loadAppIconImage() {
            cgContext.saveGState()
            let clipPath = UIBezierPath(roundedRect: badgeRect, cornerRadius: iconSize * 0.22)
            clipPath.addClip()
            appIcon.draw(in: badgeRect)
            cgContext.restoreGState()
        } else {
            // Authentic Sotto launcher icon fallback (sage-green squircle with speech bubble & equalizer bars)
            let sageBg = UIColor(red: 136 / 255.0, green: 169 / 255.0, blue: 142 / 255.0, alpha: 1.0)
            let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: iconSize * 0.22)
            sageBg.setFill()
            badgePath.fill()

            // White speech bubble with pointer tail
            let bubbleCenter = CGPoint(x: badgeRect.midX - (iconSize * 0.02), y: badgeRect.midY - (iconSize * 0.02))
            let bubbleRadius = iconSize * 0.28
            let bubblePath = UIBezierPath()
            bubblePath.addArc(withCenter: bubbleCenter, radius: bubbleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            bubblePath.move(to: CGPoint(x: bubbleCenter.x + bubbleRadius * 0.45, y: bubbleCenter.y + bubbleRadius * 0.7))
            bubblePath.addLine(to: CGPoint(x: bubbleCenter.x + bubbleRadius * 0.95, y: bubbleCenter.y + bubbleRadius * 1.1))
            bubblePath.addLine(to: CGPoint(x: bubbleCenter.x + bubbleRadius * 0.05, y: bubbleCenter.y + bubbleRadius * 0.95))
            bubblePath.close()
            UIColor.white.setFill()
            bubblePath.fill()

            // 5 voice equalizer bars in dark sage (#1A271E)
            let barColor = UIColor(red: 26 / 255.0, green: 39 / 255.0, blue: 30 / 255.0, alpha: 1.0)
            cgContext.saveGState()
            cgContext.setStrokeColor(barColor.cgColor)
            cgContext.setLineWidth(1.8)
            cgContext.setLineCap(.round)

            let barHalfHeights: [CGFloat] = [2.2, 4.0, 5.8, 4.0, 2.2]
            let barSpacing: CGFloat = 2.6
            let barOffsets: [CGFloat] = [-2, -1, 0, 1, 2]
            for idx in 0..<5 {
                let bx = bubbleCenter.x + (barOffsets[idx] * barSpacing)
                let bh = barHalfHeights[idx]
                cgContext.move(to: CGPoint(x: bx, y: bubbleCenter.y - bh))
                cgContext.addLine(to: CGPoint(x: bx, y: bubbleCenter.y + bh))
            }
            cgContext.strokePath()
            cgContext.restoreGState()
        }

        let textRect = CGRect(
            x: startX + iconSize + gap,
            y: badgeRect.midY - (textSize.height / 2.0),
            width: textSize.width + 4,
            height: textSize.height
        )
        nsBrand.draw(in: textRect, withAttributes: footerAttrs)
    }

    @MainActor
    public static func shareCard(
        _ spec: ShareableCardSpec,
        sourceTag: String,
        voiceSettings: VoiceSettings
    ) {
        UsabilityTracker.shared.startIntent("share_card")
        let image = renderCardImage(spec)
        let caption = buildShareCaption(spec)

        guard let pngData = image.pngData() else {
            UsabilityTracker.shared.endIntent(
                "share_card",
                outcome: "aborted",
                frictionTag: "share_error",
                contextTag: sourceTag,
                voiceSettings: voiceSettings
            )
            return
        }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("shared_cards", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("sotto_card.png")

        do {
            try pngData.write(to: fileURL, options: .atomic)
            presentActivitySheet(items: [fileURL, caption])
            UsabilityTracker.shared.recordActivation(key: "card_shared", voiceSettings: voiceSettings)
            UsabilityTracker.shared.endIntent(
                "share_card",
                outcome: "shared",
                contextTag: sourceTag,
                voiceSettings: voiceSettings
            )
        } catch {
            UsabilityTracker.shared.endIntent(
                "share_card",
                outcome: "aborted",
                frictionTag: "share_error",
                contextTag: sourceTag,
                voiceSettings: voiceSettings
            )
        }
    }

    @MainActor
    public static func presentActivitySheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        topVC.present(activityVC, animated: true)
    }
}

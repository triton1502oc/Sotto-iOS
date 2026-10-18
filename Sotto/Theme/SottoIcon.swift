import SwiftUI

/// Centralized SF Symbol iconography for Sotto-iOS.
/// Maps 1:1 with Android Material Symbols (triton1502oc/Sotto#61).
/// All symbols verified available on iOS 16.0+ (deployment target).
public enum SottoIcon: String, CaseIterable {
    // MARK: - Common
    case close = "xmark"
    case check = "checkmark"
    case add = "plus"
    case edit = "pencil"
    case delete = "trash"
    case refresh = "arrow.clockwise"
    case replay = "arrow.counterclockwise"
    case volumeUp = "speaker.wave.2.fill"
    case chevronRight = "chevron.right"
    case arrowDown = "chevron.down"
    case arrowUp = "chevron.up"

    // MARK: - Partner Mode
    case noteAlt = "square.and.pencil"
    case flipPartner = "arrow.triangle.2.circlepath"
    case cards = "rectangle.stack"
    case mic = "mic.fill"
    case stop = "stop.fill"
    case keyboard = "keyboard"
    case branch = "arrow.triangle.branch"
    case chat = "bubble.left.and.bubble.right.fill"

    // MARK: - Main Screen
    case partnerMode = "person.2.fill"
    case tune = "slider.horizontal.3"
    case dragHandle = "line.3.horizontal"
    case qrCodeScanner = "qrcode.viewfinder"
    case analytics = "chart.bar.fill"
    case backup = "square.and.arrow.up"
    case restore = "square.and.arrow.down"
    case shield = "shield.fill"
    case explore = "compass"
    case listAlt = "list.bullet.rectangle"
    case fullscreen = "arrow.up.left.and.arrow.down.right"

    // MARK: - Settings
    case recordVoiceOver = "waveform"
    case palette = "paintpalette.fill"
    case language = "globe"
    case hourglass = "hourglass"
    case info = "info.circle"

    // MARK: - Triggers & Secondary
    case questionmark = "questionmark"
    case crossCase = "cross.case.fill"
    case speakerWave3 = "speaker.wave.3.fill"
    case checklist = "checklist"
    case heart = "heart.fill"
    case ellipsisCircle = "ellipsis.circle"
    case docTextMagnifyingglass = "doc.text.magnifyingglass"
    case warning = "exclamationmark.triangle.fill"
    case pause = "pause.fill"
    case search = "magnifyingglass"
    case target = "checkmark.circle.fill"

    public var systemName: String { rawValue }

    /// Localized accessibility label for VoiceOver screen reader (EN & ID).
    public func accessibilityLabel(appLanguage: String = "system") -> String {
        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
        switch self {
        case .close:
            return isId ? "Tutup" : "Close"
        case .check:
            return isId ? "Centang" : "Check"
        case .add:
            return isId ? "Tambah" : "Add"
        case .edit:
            return isId ? "Ubah" : "Edit"
        case .delete:
            return isId ? "Hapus" : "Delete"
        case .refresh:
            return isId ? "Segarkan" : "Refresh"
        case .replay:
            return isId ? "Ulangi" : "Replay"
        case .volumeUp:
            return isId ? "Bicara" : "Speak"
        case .chevronRight:
            return isId ? "Berikutnya" : "Next"
        case .arrowDown:
            return isId ? "Turun" : "Down"
        case .arrowUp:
            return isId ? "Naik" : "Up"
        case .noteAlt:
            return isId ? "Catat pemicu" : "Log trigger"
        case .flipPartner:
            return isId ? "Putar tampilan" : "Flip display"
        case .cards:
            return isId ? "Pilihan kartu" : "Cards"
        case .mic:
            return isId ? "Mikrofon" : "Microphone"
        case .stop:
            return isId ? "Berhenti" : "Stop"
        case .keyboard:
            return isId ? "Papan ketik" : "Keyboard"
        case .branch:
            return isId ? "Mode panduan" : "Guided mode"
        case .chat:
            return isId ? "Mode bicara" : "Talk mode"
        case .partnerMode:
            return isId ? "Mode mitra" : "Partner mode"
        case .tune:
            return isId ? "Pengaturan" : "Settings"
        case .dragHandle:
            return isId ? "Pindahkan" : "Reorder"
        case .qrCodeScanner:
            return isId ? "Pindai kode QR" : "Scan QR code"
        case .analytics:
            return isId ? "Catatan tren" : "Trends log"
        case .backup:
            return isId ? "Ekspor cadangan" : "Export backup"
        case .restore:
            return isId ? "Impor cadangan" : "Import backup"
        case .shield:
            return isId ? "Kartu keselamatan" : "Safety card"
        case .explore:
            return isId ? "Pencari penyebab" : "Why finder"
        case .listAlt:
            return isId ? "Daftar" : "List"
        case .fullscreen:
            return isId ? "Layar penuh" : "Fullscreen"
        case .recordVoiceOver:
            return isId ? "Pengaturan suara" : "Voice settings"
        case .palette:
            return isId ? "Tema warna" : "Color theme"
        case .language:
            return isId ? "Bahasa" : "Language"
        case .hourglass:
            return isId ? "Waktu tunggu" : "Timeout"
        case .info:
            return isId ? "Informasi" : "Information"
        case .questionmark:
            return isId ? "Ragu" : "Not sure"
        case .crossCase:
            return isId ? "Nyeri" : "Pain"
        case .speakerWave3:
            return isId ? "Kebisingan" : "Noise"
        case .checklist:
            return isId ? "Tugas" : "Task"
        case .heart:
            return isId ? "Emosi" : "Emotion"
        case .ellipsisCircle:
            return isId ? "Lainnya" : "Other"
        case .docTextMagnifyingglass:
            return isId ? "Dokumen log" : "Log documents"
        case .warning:
            return isId ? "Peringatan" : "Warning"
        case .pause:
            return isId ? "Jeda" : "Pause"
        case .search:
            return isId ? "Cari" : "Search"
        case .target:
            return isId ? "Tercapai" : "Resolved"
        }
    }
}

/// Helper view for rendering SottoIcon with consistent sizing and optional palette tint.
public struct SottoIconView: View {
    public let icon: SottoIcon
    public var size: CGFloat
    public var tint: Color?

    public init(_ icon: SottoIcon, size: CGFloat = 18, tint: Color? = nil) {
        self.icon = icon
        self.size = size
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: size))
            .foregroundColor(tint)
    }
}

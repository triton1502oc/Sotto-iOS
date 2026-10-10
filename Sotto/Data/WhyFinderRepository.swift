import Foundation

public protocol WhyFinderRepositoryProtocol {
    func getTree() -> WhyTree
    func saveTree(_ tree: WhyTree)
    func resetTreeToDefault(forLanguage: String) -> WhyTree
    func getLogs() -> [WhyLogEntry]
    func addLog(_ entry: WhyLogEntry)
    func deleteLog(id: String) -> Bool
    func clearLogs()
}

public extension WhyFinderRepositoryProtocol {
    func resetTreeToDefault() -> WhyTree {
        return resetTreeToDefault(forLanguage: Locale.current.language.languageCode?.identifier ?? "en")
    }
    
    func resetToDefault() {
        _ = resetTreeToDefault()
    }
}

public final class UserDefaultsWhyFinderRepository: WhyFinderRepositoryProtocol {
    public static let shared = UserDefaultsWhyFinderRepository()
    private let userDefaults: UserDefaults
    public static let keyTree = "why_tree"
    public static let keyLogs = "why_logs"
    public static let maxLogEntries = 500
    
    public static let areaBody = "body"
    public static let areaSenses = "senses"
    public static let areaFeelings = "feelings"
    public static let areaPerson = "person"
    public static let areaHappened = "happened"
    public static let areaComingUp = "coming_up"
    
    public static let builtInAreas: [String] = [
        areaBody, areaSenses, areaFeelings, areaPerson, areaHappened, areaComingUp
    ]
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public static func defaultTree(forLanguage language: String = Locale.current.language.languageCode?.identifier ?? "en") -> WhyTree {
        let isIndonesian = (language == "id" || language == "in")
        if isIndonesian {
            return WhyTree(areas: [
                WhyArea(
                    id: areaBody,
                    question: "Apakah terkait kondisi fisik atau kenyamanan tubuh?",
                    questions: [
                        WhyQuestion(id: "body_0", text: "Apakah merasa sakit di suatu bagian tubuh?", type: .bodyMap),
                        WhyQuestion(id: "body_1", text: "Apakah merasa lapar atau haus?"),
                        WhyQuestion(id: "body_2", text: "Apakah merasa sangat lelah atau mengantuk?"),
                        WhyQuestion(id: "body_3", text: "Apakah merasa terlalu dingin atau terlalu panas?"),
                        WhyQuestion(id: "body_4", text: "Apakah perlu ke kamar mandi?")
                    ]
                ),
                WhyArea(
                    id: areaSenses,
                    question: "Apakah ada sesuatu di sekitar yang mengganggu pancaindra?",
                    questions: [
                        WhyQuestion(id: "senses_0", text: "Apakah suaranya terlalu keras atau bising?"),
                        WhyQuestion(id: "senses_1", text: "Apakah cahayanya terlalu terang atau menyilaukan?"),
                        WhyQuestion(id: "senses_2", text: "Apakah terlalu ramai atau terlalu banyak orang?"),
                        WhyQuestion(id: "senses_3", text: "Apakah ada bau yang tidak menyenangkan?"),
                        WhyQuestion(id: "senses_4", text: "Apakah pakaian atau sentuhan terasa tidak nyaman?")
                    ]
                ),
                WhyArea(
                    id: areaFeelings,
                    question: "Apakah merasakan emosi atau perasaan yang kuat di dalam hati?",
                    questions: [
                        WhyQuestion(id: "feelings_0", text: "Apakah merasa takut atau cemas?"),
                        WhyQuestion(id: "feelings_1", text: "Apakah merasa marah atau kesal?"),
                        WhyQuestion(id: "feelings_2", text: "Apakah merasa sedih atau kesepian?"),
                        WhyQuestion(id: "feelings_3", text: "Apakah merasa kewalahan atau pikiran terlalu penuh?"),
                        WhyQuestion(id: "feelings_4", text: "Apakah merasa malu atau salah dipahami?")
                    ]
                ),
                WhyArea(
                    id: areaPerson,
                    question: "Apakah mengenai seseorang atau perilaku orang lain?",
                    questions: [
                        WhyQuestion(id: "person_0", text: "Apakah mengenai seseorang di rumah atau keluarga?"),
                        WhyQuestion(id: "person_1", text: "Apakah mengenai teman atau orang dari sekolah/tempat kerja?"),
                        WhyQuestion(id: "person_2", text: "Apakah ada kejadian online atau lewat pesan?"),
                        WhyQuestion(id: "person_3", text: "Apakah ada orang asing yang melakukan atau mengatakan sesuatu?")
                    ]
                ),
                WhyArea(
                    id: areaHappened,
                    question: "Apakah terjadi sesuatu yang mendadak atau mengecewakan tadi?",
                    questions: [
                        WhyQuestion(id: "happened_0", text: "Apakah ada rencana, jadwal, atau rutinitas yang berubah?"),
                        WhyQuestion(id: "happened_1", text: "Apakah ada barang yang hilang, rusak, atau tidak berfungsi?"),
                        WhyQuestion(id: "happened_2", text: "Apakah ada yang berbicara ketus, memarahi, atau mengoreksi?"),
                        WhyQuestion(id: "happened_3", text: "Apakah terhalang menyelesaikan hal yang ingin dilakukan?")
                    ]
                ),
                WhyArea(
                    id: areaComingUp,
                    question: "Apakah khawatir tentang sesuatu yang akan terjadi nanti?",
                    questions: [
                        WhyQuestion(id: "coming_up_0", text: "Apakah akan pergi ke tempat yang tidak diinginkan?"),
                        WhyQuestion(id: "coming_up_1", text: "Apakah mengenai berangkat ke sekolah, kerja, atau aktivitas sebentar lagi?"),
                        WhyQuestion(id: "coming_up_2", text: "Apakah mengenai janji temu atau perpindahan kegiatan nanti?"),
                        WhyQuestion(id: "coming_up_3", text: "Apakah ada perubahan rutinitas besok atau yang akan datang?")
                    ]
                )
            ])
        } else {
            return WhyTree(areas: [
                WhyArea(
                    id: areaBody,
                    question: "Is it something with your body or physical comfort?",
                    questions: [
                        WhyQuestion(id: "body_0", text: "Are you in pain or hurting somewhere?", type: .bodyMap),
                        WhyQuestion(id: "body_1", text: "Are you hungry or thirsty?"),
                        WhyQuestion(id: "body_2", text: "Are you feeling very tired or exhausted?"),
                        WhyQuestion(id: "body_3", text: "Are you feeling too cold or too hot?"),
                        WhyQuestion(id: "body_4", text: "Do you need the restroom?")
                    ]
                ),
                WhyArea(
                    id: areaSenses,
                    question: "Is it something around you overwhelming your senses?",
                    questions: [
                        WhyQuestion(id: "senses_0", text: "Is it too loud or noisy?"),
                        WhyQuestion(id: "senses_1", text: "Is it too bright or glaring?"),
                        WhyQuestion(id: "senses_2", text: "Is it too crowded or too many people around?"),
                        WhyQuestion(id: "senses_3", text: "Is there an unpleasant smell?"),
                        WhyQuestion(id: "senses_4", text: "Are your clothes or something touching you uncomfortable?")
                    ]
                ),
                WhyArea(
                    id: areaFeelings,
                    question: "Is it a strong feeling or emotion inside?",
                    questions: [
                        WhyQuestion(id: "feelings_0", text: "Are you feeling scared or anxious?"),
                        WhyQuestion(id: "feelings_1", text: "Are you feeling angry or frustrated?"),
                        WhyQuestion(id: "feelings_2", text: "Are you feeling sad or lonely?"),
                        WhyQuestion(id: "feelings_3", text: "Are you feeling overwhelmed or overloaded?"),
                        WhyQuestion(id: "feelings_4", text: "Are you feeling embarrassed or misunderstood?")
                    ]
                ),
                WhyArea(
                    id: areaPerson,
                    question: "Is it about a person or someone's behavior?",
                    questions: [
                        WhyQuestion(id: "person_0", text: "Is it about someone here at home or family?"),
                        WhyQuestion(id: "person_1", text: "Is it about someone from school, work, or day program?"),
                        WhyQuestion(id: "person_2", text: "Did something happen online or in a message?"),
                        WhyQuestion(id: "person_3", text: "Did a stranger or bystander do or say something?")
                    ]
                ),
                WhyArea(
                    id: areaHappened,
                    question: "Did something unexpected or frustrating happen earlier?",
                    questions: [
                        WhyQuestion(id: "happened_0", text: "Did a plan, schedule, or routine change?"),
                        WhyQuestion(id: "happened_1", text: "Did something get lost, broken, or not work?"),
                        WhyQuestion(id: "happened_2", text: "Did someone say something sharp, reprimand, or correct you?"),
                        WhyQuestion(id: "happened_3", text: "Were you stopped from finishing something you wanted to do?")
                    ]
                ),
                WhyArea(
                    id: areaComingUp,
                    question: "Is it worry about something that is going to happen next?",
                    questions: [
                        WhyQuestion(id: "coming_up_0", text: "Are we going somewhere you don't want to go?"),
                        WhyQuestion(id: "coming_up_1", text: "Is it about going to school, work, or an activity soon?"),
                        WhyQuestion(id: "coming_up_2", text: "Is it about an upcoming appointment or transition?"),
                        WhyQuestion(id: "coming_up_3", text: "Is there a change in tomorrow or upcoming routine?")
                    ]
                )
            ])
        }
    }
    
    public func getTree() -> WhyTree {
        guard let data = userDefaults.data(forKey: Self.keyTree) else {
            let def = Self.defaultTree()
            saveTree(def)
            return def
        }
        do {
            let tree = try JSONDecoder().decode(WhyTree.self, from: data)
            return tree.areas.isEmpty ? Self.defaultTree() : tree
        } catch {
            return Self.defaultTree()
        }
    }
    
    public func saveTree(_ tree: WhyTree) {
        do {
            let data = try JSONEncoder().encode(tree)
            userDefaults.set(data, forKey: Self.keyTree)
        } catch {
            // Ignore encoding errors
        }
    }
    
    public func resetTreeToDefault(forLanguage language: String) -> WhyTree {
        let def = Self.defaultTree(forLanguage: language)
        saveTree(def)
        return def
    }
    
    private var logsFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("Sotto", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("why_logs.json")
    }
    
    public func getLogs() -> [WhyLogEntry] {
        var diskLogs: [WhyLogEntry] = []
        if let fileURL = logsFileURL,
           FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let list = try? JSONDecoder().decode([WhyLogEntry].self, from: data) {
            diskLogs = list
        }
        
        // Backward compatibility migration from legacy UserDefaults
        if let data = userDefaults.data(forKey: Self.keyLogs),
           let legacyList = try? JSONDecoder().decode([WhyLogEntry].self, from: data) {
            let existingIds = Set(diskLogs.map { $0.id })
            let newLegacy = legacyList.filter { !existingIds.contains($0.id) }
            diskLogs.append(contentsOf: newLegacy)
            diskLogs.sort(by: { $0.startedAt > $1.startedAt })
            saveLogsInternal(diskLogs)
            userDefaults.removeObject(forKey: Self.keyLogs)
        }
        
        return diskLogs.sorted(by: { $0.startedAt > $1.startedAt })
    }
    
    public func addLog(_ entry: WhyLogEntry) {
        var current = getLogs()
        current.insert(entry, at: 0)
        if current.count > Self.maxLogEntries {
            current = Array(current.prefix(Self.maxLogEntries))
        }
        saveLogsInternal(current)
    }
    
    public func deleteLog(id: String) -> Bool {
        var current = getLogs()
        let countBefore = current.count
        current.removeAll(where: { $0.id == id })
        let removed = current.count < countBefore
        if removed {
            saveLogsInternal(current)
        }
        return removed
    }
    
    public func clearLogs() {
        if let fileURL = logsFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        userDefaults.removeObject(forKey: Self.keyLogs)
    }
    
    private func saveLogsInternal(_ entries: [WhyLogEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            if let fileURL = logsFileURL {
                try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            }
        } catch {
            // Ignore encoding errors
        }
    }
}

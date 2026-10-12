import SwiftUI

public struct WhyTreeEditorModal: View {
    public let repository: WhyFinderRepositoryProtocol
    public let onDismiss: () -> Void
    
    @State private var tree: WhyTree
    @State private var selectedAreaId: String = ""
    @State private var showResetConfirm: Bool = false
    @State private var editingAreaQuestion: WhyArea? = nil
    @State private var areaQuestionText: String = ""
    @State private var questionToEdit: (index: Int, question: WhyQuestion)? = nil
    @State private var showAddQuestion: Bool = false
    @State private var newQuestionText: String = ""
    @State private var newQuestionType: WhyQuestionType = .plain
    @StateObject private var speechService = SpeechRecognizerService()
    
    public init(
        repository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        onDismiss: @escaping () -> Void
    ) {
        self.repository = repository
        self.onDismiss = onDismiss
        let initialTree = repository.getTree()
        _tree = State(initialValue: initialTree)
        _selectedAreaId = State(initialValue: initialTree.areas.first?.id ?? "")
    }
    
    private var currentArea: WhyArea? {
        tree.areas.first(where: { $0.id == selectedAreaId }) ?? tree.areas.first
    }
    
    private var currentAreaIndex: Int? {
        tree.areas.firstIndex(where: { $0.id == selectedAreaId })
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Area Selection Chips
                    areaChipsRow
                    
                    if let area = currentArea, let aIndex = currentAreaIndex {
                        // Opening Question Card
                        areaOpeningQuestionCard(area: area, areaIndex: aIndex)
                        
                        // Questions Section Header
                        HStack {
                            Text("Questions (\(area.questions.count))")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                newQuestionText = ""
                                newQuestionType = .plain
                                showAddQuestion = true
                            }) {
                                HStack(spacing: 6) {
                                    SottoIconView(.add, size: 14, tint: SottoTheme.primary)
                                    Text("Add Question")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(SottoTheme.primary)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(12)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        
                        // Questions List
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(area.questions.enumerated()), id: \.element.id) { qIndex, question in
                                    questionRow(areaIndex: aIndex, qIndex: qIndex, question: question)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Question Tree Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive, action: {
                            showResetConfirm = true
                        }) {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17))
                            .foregroundColor(SottoTheme.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(SottoTheme.confirm)
                            .frame(minHeight: 44)
                    }
                }
            }
            // Edit Area Question Sheet
            .sheet(item: $editingAreaQuestion) { area in
                NavigationView {
                    ZStack {
                        SottoTheme.surface.ignoresSafeArea()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Edit Opening Question")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            HStack(spacing: 8) {
                                TextField("Enter question...", text: $areaQuestionText)
                                    .font(.system(size: 16))
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .padding(12)
                                    .background(SottoTheme.background)
                                    .cornerRadius(10)
                                    .onSubmit {
                                        if speechService.isRecording { speechService.stopRecording() }
                                    }
                                
                                Button(action: {
                                    toggleDictation(forAreaQuestion: true)
                                }) {
                                    SottoIconView(
                                        .mic,
                                        size: 18,
                                        tint: speechService.isRecording ? SottoTheme.destructiveRed : SottoTheme.primary
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(SottoTheme.background)
                                    .cornerRadius(10)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                    }
                    .navigationTitle("Area Opening Question")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                if speechService.isRecording { speechService.stopRecording() }
                                editingAreaQuestion = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if speechService.isRecording { speechService.stopRecording() }
                                let trimmed = areaQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty, let aIndex = currentAreaIndex {
                                    var areas = tree.areas
                                    let existing = areas[aIndex]
                                    areas[aIndex] = WhyArea(id: existing.id, question: trimmed, questions: existing.questions)
                                    updateTree(WhyTree(areas: areas))
                                }
                                editingAreaQuestion = nil
                            }
                            .bold()
                            .foregroundColor(SottoTheme.confirm)
                        }
                    }
                }
                .navigationViewStyle(.stack)
            }
            // Add Question Sheet
            .sheet(isPresented: $showAddQuestion) {
                questionEditSheet(
                    title: "Add Question",
                    textBinding: $newQuestionText,
                    typeBinding: $newQuestionType,
                    onSave: {
                        guard let aIndex = currentAreaIndex else { return }
                        let trimmed = newQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        var areas = tree.areas
                        let existing = areas[aIndex]
                        var qList = existing.questions
                        qList.append(WhyQuestion(id: UUID().uuidString, text: trimmed, type: newQuestionType))
                        areas[aIndex] = WhyArea(id: existing.id, question: existing.question, questions: qList)
                        updateTree(WhyTree(areas: areas))
                        showAddQuestion = false
                    },
                    onCancel: { showAddQuestion = false }
                )
            }
            // Edit Question Sheet
            .sheet(isPresented: Binding(
                get: { questionToEdit != nil },
                set: { if !$0 { questionToEdit = nil } }
            )) {
                if let target = questionToEdit {
                    questionEditSheet(
                        title: "Edit Question",
                        textBinding: Binding(
                            get: { target.question.text },
                            set: { questionToEdit = (target.index, WhyQuestion(id: target.question.id, text: $0, type: target.question.type)) }
                        ),
                        typeBinding: Binding(
                            get: { target.question.type },
                            set: { questionToEdit = (target.index, WhyQuestion(id: target.question.id, text: target.question.text, type: $0)) }
                        ),
                        onSave: {
                            guard let aIndex = currentAreaIndex else { return }
                            let trimmed = target.question.text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            var areas = tree.areas
                            let existing = areas[aIndex]
                            var qList = existing.questions
                            qList[target.index] = WhyQuestion(id: target.question.id, text: trimmed, type: target.question.type)
                            areas[aIndex] = WhyArea(id: existing.id, question: existing.question, questions: qList)
                            updateTree(WhyTree(areas: areas))
                            questionToEdit = nil
                        },
                        onCancel: { questionToEdit = nil }
                    )
                }
            }
            // Reset confirmation
            .alert("Reset to Defaults?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    repository.resetToDefault()
                    tree = repository.getTree()
                    if let first = tree.areas.first {
                        selectedAreaId = first.id
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore the default Why Finder questions.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Subviews
    
    private var areaChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tree.areas, id: \.id) { area in
                    let isSelected = area.id == selectedAreaId
                    Button(action: { selectedAreaId = area.id }) {
                        Text(LocaleHelper.getAreaDisplayName(area.id))
                            .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(isSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(isSelected ? SottoTheme.primary.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func areaOpeningQuestionCard(area: WhyArea, areaIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AREA OPENING QUESTION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SottoTheme.primary)
                
                Spacer()
                
                Button(action: {
                    areaQuestionText = area.question
                    editingAreaQuestion = area
                }) {
                    HStack(spacing: 4) {
                        SottoIconView(.edit, size: 13, tint: SottoTheme.primary)
                        Text("Edit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SottoTheme.primary)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            }
            
            Text(area.question)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(SottoTheme.textPrimary)
        }
        .padding(14)
        .background(SottoTheme.surfaceVariant.opacity(0.45))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func questionRow(areaIndex: Int, qIndex: Int, question: WhyQuestion) -> some View {
        HStack(spacing: 8) {
            // Reorder ▲ / ▼ (enforcing 44pt touch targets)
            VStack(spacing: 0) {
                Button(action: {
                    moveQuestion(areaIndex: areaIndex, from: qIndex, to: qIndex - 1)
                }) {
                    SottoIconView(
                        .arrowUp,
                        size: 13,
                        tint: qIndex > 0 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25)
                    )
                    .frame(width: 36, height: 22)
                    .contentShape(Rectangle())
                }
                .disabled(qIndex == 0)
                
                Button(action: {
                    moveQuestion(areaIndex: areaIndex, from: qIndex, to: qIndex + 1)
                }) {
                    SottoIconView(
                        .arrowDown,
                        size: 13,
                        tint: qIndex < currentArea!.questions.count - 1 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25)
                    )
                    .frame(width: 36, height: 22)
                    .contentShape(Rectangle())
                }
                .disabled(qIndex >= currentArea!.questions.count - 1)
            }
            .frame(width: 36)
            
            // Question text & Type Badge
            VStack(alignment: .leading, spacing: 4) {
                Text(question.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SottoTheme.textPrimary)
                
                if question.type == .bodyPart {
                    HStack(spacing: 4) {
                        SottoIconView(.target, size: 11, tint: SottoTheme.primary)
                        Text("Body Part Grid")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SottoTheme.primary)
                    }
                } else if question.type == .intensity {
                    HStack(spacing: 4) {
                        SottoIconView(.analytics, size: 11, tint: SottoTheme.warning)
                        Text("Intensity Scale (1-5)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SottoTheme.warning)
                    }
                }
            }
            
            Spacer()
            
            // Edit Button (44pt target)
            Button(action: {
                questionToEdit = (qIndex, question)
            }) {
                SottoIconView(.edit, size: 15, tint: SottoTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Edit question")
            
            // Delete Button (44pt target)
            Button(action: {
                deleteQuestion(areaIndex: areaIndex, qIndex: qIndex)
            }) {
                SottoIconView(.delete, size: 15, tint: SottoTheme.destructiveRed.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Delete question")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(SottoTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func questionEditSheet(
        title: String,
        textBinding: Binding<String>,
        typeBinding: Binding<WhyQuestionType>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("Question Text")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SottoTheme.textSecondary)
                    
                    HStack(spacing: 8) {
                        TextField("Enter question...", text: textBinding)
                            .font(.system(size: 16))
                            .foregroundColor(SottoTheme.textPrimary)
                            .padding(12)
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                            .onSubmit {
                                if speechService.isRecording {
                                    speechService.stopRecording()
                                }
                            }
                        
                        Button(action: {
                            toggleDictation(forAreaQuestion: false)
                        }) {
                            SottoIconView(
                                .mic,
                                size: 18,
                                tint: speechService.isRecording ? SottoTheme.destructiveRed : SottoTheme.primary
                            )
                            .frame(width: 44, height: 44)
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                        }
                    }
                    
                    Text("Response Type")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SottoTheme.textSecondary)
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        let types: [(WhyQuestionType, String, String)] = [
                            (.plain, "Yes / No / Wait", "Standard binary crisis response dock"),
                            (.bodyPart, "Body Part Map", "Interactive anatomy selection grid"),
                            (.intensity, "Intensity Scale", "1 to 5 numeric severity rating")
                        ]
                        
                        ForEach(types, id: \.0) { t, name, desc in
                            let isSelected = typeBinding.wrappedValue == t
                            Button(action: { typeBinding.wrappedValue = t }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(SottoTheme.textPrimary)
                                        Text(desc)
                                            .font(.system(size: 12))
                                            .foregroundColor(SottoTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(SottoTheme.primary)
                                    }
                                }
                                .padding(12)
                                .background(isSelected ? SottoTheme.primary.opacity(0.12) : SottoTheme.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? SottoTheme.primary : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if speechService.isRecording { speechService.stopRecording() }
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if speechService.isRecording { speechService.stopRecording() }
                        onSave()
                    }
                    .bold()
                    .foregroundColor(SottoTheme.confirm)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Mutators
    
    private func updateTree(_ newTree: WhyTree) {
        tree = newTree
        repository.saveTree(newTree)
    }
    
    private func moveQuestion(areaIndex: Int, from: Int, to: Int) {
        guard to >= 0 && to < currentArea!.questions.count else { return }
        var areas = tree.areas
        var qList = areas[areaIndex].questions
        let item = qList.remove(at: from)
        qList.insert(item, at: to)
        areas[areaIndex] = WhyArea(id: areas[areaIndex].id, question: areas[areaIndex].question, questions: qList)
        updateTree(WhyTree(areas: areas))
    }
    
    private func deleteQuestion(areaIndex: Int, qIndex: Int) {
        var areas = tree.areas
        var qList = areas[areaIndex].questions
        qList.remove(at: qIndex)
        areas[areaIndex] = WhyArea(id: areas[areaIndex].id, question: areas[areaIndex].question, questions: qList)
        updateTree(WhyTree(areas: areas))
    }
    
    private func toggleDictation(forAreaQuestion: Bool) {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            speechService.requestPermissions { granted in
                if granted {
                    speechService.startRecording { text in
                        if forAreaQuestion {
                            areaQuestionText = text
                        } else if questionToEdit != nil {
                            questionToEdit!.question.text = text
                        } else {
                            newQuestionText = text
                        }
                    }
                }
            }
        }
    }
}

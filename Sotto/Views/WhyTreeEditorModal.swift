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
    @State private var speechService = SpeechRecognizerService()
    @State private var isDictating: Bool = false
    
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
                                HStack(spacing: 4) {
                                    Text("+")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Add Question")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(SottoTheme.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(12)
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
                        Button(role: .destructive, action: { showResetConfirm = true }) {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(SottoTheme.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SottoTheme.confirm)
                }
            }
            // Edit Opening Question Alert
            .alert("Edit Area Question", isPresented: Binding(
                get: { editingAreaQuestion != nil },
                set: { if !$0 { editingAreaQuestion = nil } }
            )) {
                TextField("Question text", text: $areaQuestionText)
                Button("Save") {
                    if let aIndex = currentAreaIndex {
                        var areas = tree.areas
                        let existing = areas[aIndex]
                        areas[aIndex] = WhyArea(
                            id: existing.id,
                            question: areaQuestionText.trimmingCharacters(in: .whitespacesAndNewlines),
                            questions: existing.questions
                        )
                        updateTree(WhyTree(areas: areas))
                    }
                    editingAreaQuestion = nil
                }
                Button("Cancel", role: .cancel) {
                    editingAreaQuestion = nil
                }
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
                            .padding(.vertical, 8)
                            .background(isSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(isSelected ? SottoTheme.primary.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                            )
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
                    Text("✏️ Edit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SottoTheme.primary)
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
        HStack(spacing: 10) {
            // Fine-motor reorder ▲ / ▼
            VStack(spacing: 2) {
                Button(action: {
                    moveQuestion(areaIndex: areaIndex, from: qIndex, to: qIndex - 1)
                }) {
                    Text("▲")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(qIndex > 0 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25))
                        .frame(width: 26, height: 18)
                }
                .disabled(qIndex == 0)
                
                Button(action: {
                    moveQuestion(areaIndex: areaIndex, from: qIndex, to: qIndex + 1)
                }) {
                    Text("▼")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(qIndex < currentArea!.questions.count - 1 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25))
                        .frame(width: 26, height: 18)
                }
                .disabled(qIndex >= currentArea!.questions.count - 1)
            }
            
            // Question text & Type Badge
            VStack(alignment: .leading, spacing: 4) {
                Text(question.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SottoTheme.textPrimary)
                
                if question.type == .bodyPart {
                    Text("🎯 Body Part Grid")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SottoTheme.primary)
                } else if question.type == .intensity {
                    Text("📊 Intensity Scale (1-5)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SottoTheme.warning)
                }
            }
            
            Spacer()
            
            // Edit
            Button(action: {
                questionToEdit = (qIndex, question)
            }) {
                Text("✏️")
                    .font(.system(size: 13))
                    .frame(width: 30, height: 30)
            }
            
            // Delete
            Button(action: {
                deleteQuestion(areaIndex: areaIndex, qIndex: qIndex)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(SottoTheme.destructiveRed)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
                    
                    HStack {
                        TextField("Enter question...", text: textBinding)
                            .font(.system(size: 16))
                            .foregroundColor(SottoTheme.textPrimary)
                            .padding(12)
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                        
                        Button(action: {
                            if isDictating {
                                speechService.stopRecording()
                                isDictating = false
                            } else {
                                speechService.startRecording()
                                isDictating = true
                            }
                        }) {
                            Image(systemName: isDictating ? "stop.fill" : "mic.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isDictating ? .white : SottoTheme.primary)
                                .frame(width: 44, height: 44)
                                .background(isDictating ? SottoTheme.destructiveRed : SottoTheme.surfaceVariant)
                                .clipShape(Circle())
                        }
                    }
                    .onChange(of: speechService.transcribedText) { newText in
                        if !newText.isEmpty {
                            textBinding.wrappedValue = newText
                        }
                    }
                    
                    Text("Interaction Type")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SottoTheme.textSecondary)
                    
                    Picker("Interaction Type", selection: typeBinding) {
                        Text("Yes / No").tag(WhyQuestionType.plain)
                        Text("Body Part Grid").tag(WhyQuestionType.bodyPart)
                        Text("Intensity Scale (1-5)").tag(WhyQuestionType.intensity)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .bold()
                        .foregroundColor(SottoTheme.confirm)
                }
            }
        }
    }
    
    // MARK: - Mutators
    
    private func updateTree(_ newTree: WhyTree) {
        repository.saveTree(newTree)
        tree = newTree
    }
    
    private func moveQuestion(areaIndex: Int, from: Int, to: Int) {
        var areas = tree.areas
        var qList = areas[areaIndex].questions
        guard from >= 0 && from < qList.count, to >= 0 && to < qList.count else { return }
        let item = qList.remove(at: from)
        qList.insert(item, at: to)
        areas[areaIndex] = WhyArea(id: areas[areaIndex].id, question: areas[areaIndex].question, questions: qList)
        updateTree(WhyTree(areas: areas))
    }
    
    private func deleteQuestion(areaIndex: Int, qIndex: Int) {
        var areas = tree.areas
        var qList = areas[areaIndex].questions
        guard qIndex >= 0 && qIndex < qList.count else { return }
        qList.remove(at: qIndex)
        areas[areaIndex] = WhyArea(id: areas[areaIndex].id, question: areas[areaIndex].question, questions: qList)
        updateTree(WhyTree(areas: areas))
    }
}

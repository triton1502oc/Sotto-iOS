import SwiftUI

public struct ManageCategoriesModal: View {
    @ObservedObject public var viewModel: MainViewModel
    public let onDismiss: () -> Void
    
    @State private var showAddDialog: Bool = false
    @State private var newCategoryName: String = ""
    @State private var addErrorMessage: String? = nil
    
    @State private var categoryToRename: String? = nil
    @State private var renameValue: String = ""
    @State private var renameErrorMessage: String? = nil
    
    @State private var categoryToDeleteConfirm: String? = nil
    
    public init(viewModel: MainViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(viewModel.categories.enumerated()), id: \.element) { index, catName in
                                categoryRow(index: index, catName: catName)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    
                    Button(action: {
                        newCategoryName = ""
                        addErrorMessage = nil
                        showAddDialog = true
                    }) {
                        HStack(spacing: 6) {
                            Text("+")
                                .font(.system(size: 16, weight: .bold))
                            Text("Add Category")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(SottoTheme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(SottoTheme.surfaceVariant.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SottoTheme.primary.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SottoTheme.confirm)
                }
            }
            // Add Category Alert / Sheet
            .alert("Add Category", isPresented: $showAddDialog) {
                TextField("Category name", text: $newCategoryName)
                Button("Add") {
                    let success = viewModel.addCategory(newCategoryName)
                    if !success {
                        // show error
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            // Rename Category Alert
            .alert("Rename Category", isPresented: Binding(
                get: { categoryToRename != nil },
                set: { if !$0 { categoryToRename = nil } }
            )) {
                TextField("Category name", text: $renameValue)
                Button("Save") {
                    if let oldName = categoryToRename {
                        viewModel.renameCategory(oldName: oldName, newName: renameValue)
                    }
                    categoryToRename = nil
                }
                Button("Cancel", role: .cancel) {
                    categoryToRename = nil
                }
            }
            // Delete Confirmation Alert
            .alert("Delete Category?", isPresented: Binding(
                get: { categoryToDeleteConfirm != nil },
                set: { if !$0 { categoryToDeleteConfirm = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let cat = categoryToDeleteConfirm {
                        viewModel.deleteCategory(cat)
                    }
                    categoryToDeleteConfirm = nil
                }
                Button("Cancel", role: .cancel) {
                    categoryToDeleteConfirm = nil
                }
            } message: {
                if let cat = categoryToDeleteConfirm {
                    Text("Phrases in \"\(cat)\" will be moved to General.")
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryRow(index: Int, catName: String) -> some View {
        let isEmergency = catName.caseInsensitiveCompare(PhraseCategory.emergency.rawValue) == .orderedSame
        let isGeneral = catName.caseInsensitiveCompare(PhraseCategory.general.rawValue) == .orderedSame
        let isProtectedFromDelete = Phrase.isUndeletableCategory(catName)
        let isProtectedFromRename = Phrase.isUnrenamableCategory(catName)
        
        HStack(spacing: 8) {
            // Fine-motor single-step up / down buttons
            VStack(spacing: 2) {
                Button(action: {
                    if index > 0 {
                        viewModel.reorderCategories(fromIndex: index, toIndex: index - 1)
                    }
                }) {
                    Text("▲")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(index > 0 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25))
                        .frame(width: 28, height: 20)
                }
                .disabled(index == 0)
                
                Button(action: {
                    if index < viewModel.categories.count - 1 {
                        viewModel.reorderCategories(fromIndex: index, toIndex: index + 1)
                    }
                }) {
                    Text("▼")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(index < viewModel.categories.count - 1 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25))
                        .frame(width: 28, height: 20)
                }
                .disabled(index >= viewModel.categories.count - 1)
            }
            
            // Category Name & Badges
            VStack(alignment: .leading, spacing: 2) {
                Text(LocaleHelper.getCategoryDisplayName(catName))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEmergency ? SottoTheme.emergencyAccent : SottoTheme.textPrimary)
                
                if isEmergency {
                    Text("Emergency (Locked)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SottoTheme.emergencyAccent.opacity(0.8))
                } else if isGeneral {
                    Text("General (Default)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SottoTheme.textSecondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Rename button
            if !isProtectedFromRename {
                Button(action: {
                    renameValue = catName
                    categoryToRename = catName
                }) {
                    Text("✏️")
                        .font(.system(size: 14))
                        .frame(width: 32, height: 32)
                }
            }
            
            // Delete button
            if !isProtectedFromDelete {
                Button(action: {
                    categoryToDeleteConfirm = catName
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(SottoTheme.destructiveRed)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isEmergency
                ? SottoTheme.emergencyChipBg
                : SottoTheme.surfaceVariant.opacity(0.5)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isEmergency
                        ? SottoTheme.emergencyBorder.opacity(0.4)
                        : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}

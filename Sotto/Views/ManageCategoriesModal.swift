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
                        HStack(spacing: 8) {
                            SottoIconView(.add, size: 16, tint: SottoTheme.primary)
                            Text("Add Category")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(SottoTheme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
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
            // Add Category Alert / Sheet
            .alert("Add Category", isPresented: $showAddDialog) {
                TextField("Category name", text: $newCategoryName)
                Button("Add") {
                    _ = viewModel.addCategory(newCategoryName)
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
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private func categoryRow(index: Int, catName: String) -> some View {
        let isEmergency = catName.caseInsensitiveCompare(PhraseCategory.emergency.rawValue) == .orderedSame
        let isGeneral = catName.caseInsensitiveCompare(PhraseCategory.general.rawValue) == .orderedSame
        let isProtectedFromDelete = Phrase.isUndeletableCategory(catName)
        let isProtectedFromRename = Phrase.isUnrenamableCategory(catName)
        
        HStack(spacing: 8) {
            // Fine-motor single-step up / down buttons (44pt touch targets)
            VStack(spacing: 0) {
                Button(action: {
                    if index > 0 {
                        viewModel.reorderCategories(fromIndex: index, toIndex: index - 1)
                    }
                }) {
                    SottoIconView(
                        .arrowUp,
                        size: 13,
                        tint: index > 0 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25)
                    )
                    .frame(width: 36, height: 22)
                    .contentShape(Rectangle())
                }
                .disabled(index == 0)
                
                Button(action: {
                    if index < viewModel.categories.count - 1 {
                        viewModel.reorderCategories(fromIndex: index, toIndex: index + 1)
                    }
                }) {
                    SottoIconView(
                        .arrowDown,
                        size: 13,
                        tint: index < viewModel.categories.count - 1 ? SottoTheme.primary : SottoTheme.textSecondary.opacity(0.25)
                    )
                    .frame(width: 36, height: 22)
                    .contentShape(Rectangle())
                }
                .disabled(index >= viewModel.categories.count - 1)
            }
            .frame(width: 36)
            
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
            
            // Rename button (44pt target)
            if !isProtectedFromRename {
                Button(action: {
                    renameValue = catName
                    categoryToRename = catName
                }) {
                    SottoIconView(.edit, size: 16, tint: SottoTheme.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Rename category \(catName)")
            }
            
            // Delete button (44pt target)
            if !isProtectedFromDelete {
                Button(action: {
                    categoryToDeleteConfirm = catName
                }) {
                    SottoIconView(.delete, size: 16, tint: SottoTheme.destructiveRed)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Delete category \(catName)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

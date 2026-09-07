import SwiftUI

struct ManageCategoriesSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.categories) { cat in
                        row(cat).listRowBackground(Theme.surface)
                    }
                    .onMove(perform: store.moveCategories)
                    .onDelete { idx in
                        idx.map { store.categories[$0].id }.forEach(store.deleteCategory)
                    }
                } footer: {
                    Text("Drag the handles to reorder · swipe a row to delete. Tap a category on the Home screen to rename it or change its budget.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.faint)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .environment(\.editMode, .constant(.active))   // handles always visible
            .navigationTitle("Manage categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func row(_ cat: BudgetCategory) -> some View {
        HStack(spacing: 12) {
            Text(cat.icon).font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(cat.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(cat.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.ink)
                Text("\(Money.aud(cat.budget)) / month").font(.system(size: 12)).foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

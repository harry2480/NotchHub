import SwiftUI

/// The Shelf tab: search field, item list and "delete all" (要件定義.md §8).
struct ShelfListView: View {
    @Bindable var viewModel: ShelfViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .onAppear { viewModel.onAppear() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchText) { _, _ in viewModel.refresh() }
            if !viewModel.items.isEmpty {
                Button("Clear all", role: .destructive) { viewModel.deleteAll() }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
        }
        .padding(.horizontal, NotchStyle.contentPadding)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.items.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 26))
                    .foregroundStyle(.secondary)
                Text(viewModel.searchText.isEmpty ? "Shelf is empty" : "No matches")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.items) { item in
                        ShelfItemRow(
                            item: item,
                            onOpen: { viewModel.open(item) },
                            onTogglePin: { viewModel.togglePin(item) },
                            onReveal: { viewModel.revealInFinder(item) },
                            onDelete: { viewModel.delete(item) }
                        )
                        .padding(.horizontal, NotchStyle.contentPadding)
                        .padding(.vertical, 6)
                        .onDrag { viewModel.itemProvider(for: item) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

import SwiftUI

/// Tab bar for the quick terminal, shown even with a single tab.
/// The quick terminal can't use native window tabs (see QuickTerminalController.Tab).
struct QuickTerminalTabBar: View {
    @ObservedObject var controller: QuickTerminalController

    var body: some View {
        if !controller.tabs.isEmpty {
            HStack(spacing: 1) {
                ForEach(Array(controller.tabs.enumerated()), id: \.element.id) { index, tab in
                    if let surface = tab.focused ?? tab.tree.first {
                        QuickTerminalTabItem(
                            surface: surface,
                            selected: index == controller.selectedTab,
                            select: { controller.selectTab(index) },
                            close: { controller.closeTab(id: tab.id) })
                    }
                }

                Button(action: { controller.newTab(nil) }, label: {
                    Image(systemName: "plus")
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .help("New Tab")
            }
            .frame(height: 28)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

private struct QuickTerminalTabItem: View {
    @ObservedObject var surface: Ghostty.SurfaceView
    let selected: Bool
    let select: () -> Void
    let close: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack {
            Text(surface.title.isEmpty ? "Terminal" : surface.title)
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.system(size: 12))
                .foregroundStyle(selected ? .primary : .secondary)
                .padding(.horizontal, 26)

            HStack {
                Button(action: close, label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
                .help("Close Tab")
                Spacer()
            }
            .padding(.leading, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(selected ? Color.primary.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .onHover { hovering = $0 }
    }
}

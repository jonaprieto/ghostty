import Cocoa

struct QuickTerminalRestorableState: TerminalRestorable {
    static var version: Int { 1 }

    var focusedSurface: String? {
        internalState.focusedSurface
    }

    var surfaceTree: SplitTree<Ghostty.SurfaceView> {
        internalState.surfaceTree
    }

    var screenStateEntries: QuickTerminalScreenStateCache.Entries {
        internalState.screenStateEntries
    }

    /// Trees of the tabs other than the selected one, in order.
    var otherTabs: [SplitTree<Ghostty.SurfaceView>] {
        internalState.otherTabs ?? []
    }

    /// Position of the selected tab (`surfaceTree`) among all tabs.
    var selectedTab: Int {
        internalState.selectedTab ?? 0
    }

    private let internalState: InternalState<Ghostty.SurfaceView>

    init(from controller: QuickTerminalController) {
        controller.saveScreenState(exitFullscreen: true)
        self.internalState = .init(from: controller)
    }

    init(copy other: QuickTerminalRestorableState) {
        self = other
    }

    var baseConfig: Ghostty.SurfaceConfiguration? {
        var config = Ghostty.SurfaceConfiguration()
        config.environmentVariables["GHOSTTY_QUICK_TERMINAL"] = "1"
        return config
    }
}

extension QuickTerminalRestorableState {
    /// Internal State we use to perform unit tests
    ///
    /// Since we can't really change the type of `QuickTerminalRestorableState`
    /// due to `CodableBridge<QuickTerminalRestorableState>` supporting secure coding,
    /// we use an internal type to perform migration and tests
    struct InternalState<ViewType: NSView & Codable & Identifiable>: Codable {
        // MARK: - Version 1 (1.3.0)
        let focusedSurface: String?
        let surfaceTree: SplitTree<ViewType>
        let screenStateEntries: QuickTerminalScreenStateCache.Entries

        // MARK: - Fork: quick terminal tabs
        // Optional so v1 data still decodes. The selected tab stays in
        // `surfaceTree`; storing it again here would restore its surfaces twice.
        var otherTabs: [SplitTree<ViewType>]?
        var selectedTab: Int?
    }
}

extension QuickTerminalRestorableState.InternalState where ViewType == Ghostty.SurfaceView {
    init(from controller: QuickTerminalController) {
        let selected = controller.selectedTab
        QuickTerminalController.log.notice("saving \(controller.tabs.count) tabs")
        self.init(
            focusedSurface: controller.focusedSurface?.id.uuidString,
            surfaceTree: controller.surfaceTree,
            screenStateEntries: controller.screenStateCache.stateByDisplay,
            otherTabs: controller.tabs.indices.filter { $0 != selected }.map { controller.tabs[$0].tree },
            selectedTab: selected,
        )
    }
}

import Cocoa

class ModularInterface: InterfaceProtocol {
    
    var type: InterfaceType {.modular}
    
    let preferences: ViewPreferences
    var layoutForNextLaunch: WindowLayout?
    
    init(_ appState: WindowLayoutState, _ preferences: ViewPreferences) {

        self.preferences = preferences
        self.layoutForNextLaunch = appState.rememberedLayout
    }
    
    // App's main window
    var mainWindow: NSWindow = WindowFactory.mainWindow
    
    // Load these optional windows only if/when needed
    var effectsWindow: NSWindow = WindowFactory.effectsWindow
    
    var playlistWindow: NSWindow = WindowFactory.playlistWindow
    
    lazy var playQueueWindowController: PlayQueueWindowViewController = PlayQueueWindowViewController()
    lazy var playQueueWindow: NSWindow = playQueueWindowController.window!
    
    // Helps with lazy loading of chapters list window
    private var chaptersListWindowLoaded: Bool = false
    
    var chaptersListWindow: NSWindow = WindowFactory.chaptersListWindow
    
    let windowDelegate: SnappingWindowDelegate = SnappingWindowDelegate()
    
    //    private var onTop: Bool = false
    
    // Each modal component, when it is loaded, will register itself here, which will enable tracking of modal dialogs / popovers
    private var modalComponentRegistry: [ModalComponentProtocol] = []
    
    func registerModalComponent(_ component: ModalComponentProtocol) {
        modalComponentRegistry.append(component)
    }
    
    var isShowingModalComponent: Bool {
        return modalComponentRegistry.contains(where: {$0.isModal}) || NSApp.modalWindow != nil
    }
    
    // MARK - Core functionality ----------------------------------------------------
    
    func show() {
    
        if preferences.layoutOnStartup.option == .specific {
            
            layout(preferences.layoutOnStartup.layoutName)
            
        } else {
            
            // Remember from last app launch
            layout(layoutForNextLaunch ?? WindowLayouts.defaultLayout)
        }
    }
    
    func hide() {
        
    }
    
    // Revert to default layout if app state is corrupted
    private func defaultLayout() {
        layout(WindowLayouts.defaultLayout)
    }
    
    func layout(_ name: String) {
        layout(WindowLayouts.layoutByName(name)!)
    }
    
    func layout(_ layout: WindowLayout) {
        
        mainWindow.setFrameOrigin(layout.mainWindowOrigin)
        
        if layout.showEffects {
            
            mainWindow.addChildWindow(effectsWindow, ordered: NSWindow.OrderingMode.below)
            effectsWindow.setFrameOrigin(layout.effectsWindowOrigin!)
        }
        
        if layout.showPlaylist {
            
            mainWindow.addChildWindow(playlistWindow, ordered: NSWindow.OrderingMode.below)
            playlistWindow.setFrame(layout.playlistWindowFrame!, display: true)
        }
        
        mainWindow.setIsVisible(true)
        effectsWindow.setIsVisible(layout.showEffects)
        playlistWindow.setIsVisible(layout.showPlaylist)
        
        Messenger.publish(WindowLayoutChangedNotification(showingPlaylistWindow: layout.showPlaylist, showingEffectsWindow: layout.showEffects))
    }
    
    var currentWindowLayout: WindowLayout {
        
        let effectsWindowOrigin = isShowingEffects ? effectsWindow.origin : nil
        let playlistWindowFrame = isShowingPlaylist ? playlistWindow.frame : nil
        
        return WindowLayout("_currentWindowLayout_", isShowingEffects, isShowingPlaylist, mainWindow.origin, effectsWindowOrigin, playlistWindowFrame, false)
    }
    
    var isShowingEffects: Bool {
        return effectsWindow.isVisible
    }
    
    var isShowingPlaylist: Bool {
        return playlistWindow.isVisible
    }
    
    // NOTE - Boolean short-circuiting is important here. Otherwise, the chapters list window will be unnecessarily loaded.
    var isShowingChaptersList: Bool {
        return chaptersListWindowLoaded && chaptersListWindow.isVisible
    }
    
    // NOTE - Boolean short-circuiting is important here. Otherwise, the chapters list window will be unnecessarily loaded.
    var isChaptersListWindowKey: Bool {
        return isShowingChaptersList && chaptersListWindow == NSApp.keyWindow
    }
    
    var mainWindowFrame: NSRect {
        return mainWindow.frame
    }
    
    var effectsWindowFrame: NSRect {
        return effectsWindow.frame
    }
    
    var playlistWindowFrame: NSRect {
        return playlistWindow.frame
    }
    
    // MARK ----------- View toggling code ----------------------------------------------------
    
    // Shows/hides the effects window
    func toggleEffects() {
        
        isShowingEffects ? hideEffects() : showEffects()
    }
    
    // Shows the effects window
    private func showEffects() {
        
        mainWindow.addChildWindow(effectsWindow, ordered: NSWindow.OrderingMode.above)
        effectsWindow.show()
        effectsWindow.orderFront(self)
    }
    
    // Hides the effects window
    private func hideEffects() {
        effectsWindow.hide()
    }
    
    // Shows/hides the playlist window
    func togglePlaylist() {
        
        isShowingPlaylist ? hidePlaylist() : showPlaylist()
    }
    
    // Shows the playlist window
    private func showPlaylist() {
        
        mainWindow.addChildWindow(playlistWindow, ordered: NSWindow.OrderingMode.above)
        playlistWindow.show()
        playlistWindow.orderFront(self)
    }
    
    // Hides the playlist window
    private func hidePlaylist() {
        playlistWindow.hide()
    }
    
    func showPlayQueue() {

        mainWindow.addChildWindow(playQueueWindow, ordered: NSWindow.OrderingMode.above)
        playQueueWindow.show()
        playQueueWindow.orderFront(self)
    }
    
    func toggleChaptersList() {
        
        isShowingChaptersList ? hideChaptersList() : showChaptersList()
    }
    
    func showChaptersList() {
        
        playlistWindow.addChildWindow(chaptersListWindow, ordered: NSWindow.OrderingMode.above)
        chaptersListWindow.makeKeyAndOrderFront(self)
        
        // This will happen only once after each app launch - the very first time the window is shown.
        // After that, the window will be restored to its previous on-screen location
        if !chaptersListWindowLoaded {
            
            UIUtils.centerDialogWRTWindow(chaptersListWindow, playlistWindow)
            chaptersListWindowLoaded = true
        }
    }
    
    func hideChaptersList() {
        
        if chaptersListWindowLoaded {
            chaptersListWindow.setIsVisible(false)
        }
    }
    
//    func addChildWindow(_ window: NSWindow) {
//        mainWindow.addChildWindow(window, ordered: .above)
//    }
    
    //    func toggleAlwaysOnTop() {
    //
    //        onTop = !onTop
    //        mainWindow.level = NSWindow.Level(Int(CGWindowLevelForKey(onTop ? .floatingWindow : .normalWindow)))
    //    }
    
    // Adjusts both window frames to the given location and size (specified as co-ordinates)
    private func setWindowFrames(_ mainWindowX: CGFloat, _ mainWindowY: CGFloat, _ playlistX: CGFloat, _ playlistY: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        
        mainWindow.setFrameOrigin(NSPoint(x: mainWindowX, y: mainWindowY))
        
        var playlistFrame = playlistWindow.frame
        
        playlistFrame.origin = NSPoint(x: playlistX, y: playlistY)
        playlistFrame.size = NSSize(width: width, height: height)
        playlistWindow.setFrame(playlistFrame, display: true)
    }
    
    // MARK ----------- Message handling ----------------------------------------------------
    
    var persistentState: WindowLayoutState {
        
        let uiState = WindowLayoutState()
        
//        uiState.showEffects = effectsWindow.isVisible
//        uiState.showPlaylist = playlistWindow.isVisible
//        
//        uiState.mainWindowOrigin = mainWindow.origin
//        
//        uiState.effectsWindowOrigin = effectsWindow.origin
//        uiState.playlistWindowFrame = playlistWindow.frame
        
        uiState.userLayouts = WindowLayouts.userDefinedLayouts
        
        return uiState
    }
    
    // MARK: NSWindowDelegate functions
    
    fileprivate func windowDidMove(_ notification: Notification) {
        
        // Only respond if movement was user-initiated (flag on window)
        if let movedWindow = notification.object as? SnappingWindow, movedWindow.userMovingWindow {
            
            var snapped = false
            
            if preferences.snapToWindows {
                
                // First check if window can be snapped to another app window
                for mate in getCandidateWindowsForSnap(movedWindow) {
                    
                    if mate.isVisible && UIUtils.checkForSnapToWindow(movedWindow, mate) {
                        
                        snapped = true
                        break
                    }
                }
            }
            
            // If window doesn't need to be snapped to another window, check if it needs to be snapped to the visible frame
            if preferences.snapToScreen && !snapped {
                UIUtils.checkForSnapToVisibleFrame(movedWindow)
            }
        }
    }
    
    // Sorted by order of relevance
    private func getCandidateWindowsForSnap(_ movedWindow: SnappingWindow) -> [NSWindow] {
        
        if movedWindow === playlistWindow {
            return [mainWindow, effectsWindow]
            
        } else if movedWindow === effectsWindow {
            return [mainWindow, playlistWindow]
            
        } else if movedWindow === chaptersListWindow {
            return [playlistWindow, mainWindow, effectsWindow]
        }
        
        // Main window
        return []
    }
}

class SnappingWindowDelegate: NSObject, NSWindowDelegate {
    
    func windowDidMove(_ notification: Notification) {
//        WindowManager.windowDidMove(notification)
    }
}

class ModularInterfaceState {
    
    var showEffects: Bool = true
    var showPlaylist: Bool = true
    
    var mainWindowOrigin: NSPoint = NSPoint.zero
    var effectsWindowOrigin: NSPoint? = nil
    var playlistWindowFrame: NSRect? = nil
    
    var userLayouts: [WindowLayout] = [WindowLayout]()
}
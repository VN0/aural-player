import Cocoa

class PlayQueueWindowController: NSWindowController, NSTabViewDelegate, NotificationSubscriber {
    
    override var windowNibName: String? {return "PlayQueue"}
    
    @IBOutlet weak var rootContainerBox: NSBox!
    
    @IBOutlet weak var btnClose: TintedImageButton!
    @IBOutlet weak var viewMenuIconItem: TintedIconMenuItem!
    
    @IBOutlet weak var tabButtonsBox: NSBox!
    
    @IBOutlet weak var controlsBox: NSBox!
    @IBOutlet weak var controlButtonsSuperview: NSView!
    
    @IBOutlet weak var tabView: AuralTabView!
    
    @IBOutlet weak var btnListView: NSButton!
    @IBOutlet weak var btnTableView: NSButton!
    
    @IBOutlet weak var lblTracksSummary: NSTextField!
    @IBOutlet weak var lblDurationSummary: NSTextField!
    
    private lazy var listViewController: PlayQueueListViewController = PlayQueueListViewController()
    private lazy var listView: NSView = listViewController.view
    
    private lazy var tableViewController: PlayQueueTableViewController = PlayQueueTableViewController()
    private lazy var tableView: NSView = tableViewController.view
    
    private var viewControllers: [PlayQueueViewController] = []
    private var currentViewController: PlayQueueViewController {tabView.selectedIndex == 0 ? listViewController : tableViewController}
    
    private let playQueue: PlayQueueDelegateProtocol = ObjectGraph.playQueueDelegate
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
    
    private lazy var fileOpenDialog = DialogsAndAlerts.openDialog
    
    private var viewControlButtons: [Tintable] = []
    private var functionButtons: [TintedImageButton] = []
    private var childContainerBoxes: [NSBox] = []
    private var tabButtons: [NSButton] = []
    
    override func windowDidLoad() {
        
        viewControllers = [listViewController, tableViewController]
        
        childContainerBoxes = [rootContainerBox, tabButtonsBox, controlsBox]
        viewControlButtons = [btnClose, viewMenuIconItem]
        functionButtons = controlButtonsSuperview.subviews.compactMap {$0 as? TintedImageButton}
        tabButtons = [btnListView, btnTableView]
        
        changeTextSize(PlaylistViewState.textSize)
        applyColorScheme(ColorSchemes.systemScheme)
        
        tabView.addViewsForTabs([listView, tableView])
        listView.anchorToView(tabView.tabViewItem(at: 0).view!)
        tableView.anchorToView(tabView.tabViewItem(at: 1).view!)
        
        (PlayQueueUIState.view == .list ? [1, 0] : [0, 1]).forEach({tabView.selectTabViewItem(at: $0)})
        
        Messenger.subscribeAsync(self, .playQueue_trackAdded, self.trackAdded(_:), queue: .main)
        Messenger.subscribeAsync(self, .playQueue_tracksAdded, self.tracksAdded(_:), queue: .main)
        
        // Only respond if the playing track was updated
        Messenger.subscribeAsync(self, .player_trackInfoUpdated, self.trackInfoUpdated(_:), queue: .main)
        
        Messenger.subscribe(self, .playQueue_addTracks, self.addTracks)
        Messenger.subscribe(self, .playQueue_removeTracks, self.removeSelectedTracks)
        Messenger.subscribe(self, .playQueue_clear, self.clear)
        
        Messenger.subscribe(self, .playQueue_playSelectedItem, self.playSelectedItem)
        
        Messenger.subscribe(self, .playQueue_moveTracksUp, self.moveTracksUp)
        Messenger.subscribe(self, .playQueue_moveTracksDown, self.moveTracksDown)
        
        Messenger.subscribe(self, .playQueue_moveTracksToTop, self.moveTracksToTop)
        Messenger.subscribe(self, .playQueue_moveTracksToBottom, self.moveTracksToBottom)
        
        Messenger.subscribe(self, .playQueue_clearSelection, self.clearSelection)
        Messenger.subscribe(self, .playQueue_cropSelection, self.cropSelection)
        Messenger.subscribe(self, .playQueue_invertSelection, self.invertSelection)
        
        Messenger.subscribe(self, .playQueue_scrollToTop, self.scrollToTop)
        Messenger.subscribe(self, .playQueue_scrollToBottom, self.scrollToBottom)
        Messenger.subscribe(self, .playQueue_pageUp, self.pageUp)
        Messenger.subscribe(self, .playQueue_pageDown, self.pageDown)
        
        Messenger.subscribe(self, .playQueue_exportAsPlaylistFile, self.exportToPlaylist)
        
        Messenger.subscribe(self, .playlist_changeTextSize, self.changeTextSize(_:))
        Messenger.subscribe(self, .applyColorScheme, self.applyColorScheme(_:))
        
        Messenger.subscribe(self, .application_exitRequest, self.onAppExit(_:))
        
        updateSummary()
    }
    
    private func onAppExit(_ request: AppExitRequestNotification) {
        
        PlayQueueUIState.view = tabView.selectedIndex == 0 ? .list : .table
        request.acceptResponse(okToExit: true)
    }

    // Invokes the Open file dialog, to allow the user to add tracks/playlists to the app playlist
    @IBAction func addTracksAction(_ sender: AnyObject) {
        addTracks()
    }
    
    // Invokes the Open file dialog, to allow the user to add tracks/playlists to the play queue.
    func addTracks() {
        
        if fileOpenDialog.runModal() == NSApplication.ModalResponse.OK {
            playQueue.addTracks(from: fileOpenDialog.urls)
        }
    }
    
    // NOTE - Assumes track was added at the end of the queue.
    func trackAdded(_ notification: PlayQueueTrackAddedNotification) {
        updateSummary()
    }
    
    func tracksAdded(_ notification: PlayQueueTracksAddedNotification) {
        updateSummary()
    }
    
    private func trackInfoUpdated(_ notification: TrackInfoUpdatedNotification) {
        updateSummary()
    }
   
    private func updateSummary() {
        
        let summary = playQueue.summary
        let numTracks = summary.size
        
        lblTracksSummary.stringValue = String(format: "%d track%@", numTracks, numTracks == 1 ? "" : "s")
        lblDurationSummary.stringValue = ValueFormatter.formatDurationSummary(summary.totalDuration)
    }
    
    @IBAction func removeTracksAction(_ sender: AnyObject) {
        removeSelectedTracks()
    }
    
    func removeSelectedTracks() {
        
        let selectedRows = currentViewController.selectedRows
        
        if !selectedRows.isEmpty {
            
            _ = playQueue.removeTracks(selectedRows)
            
            viewControllers.forEach {$0.tracksRemoved(fromRows: selectedRows)}
            updateSummary()
        }
    }
    
    @IBAction func exportToPlaylistAction(_ sender: AnyObject) {
        exportToPlaylist()
    }
    
    private func exportToPlaylist() {
        
        //        if playlist.isBeingModified {
        //
        //            alertDialog.showAlert(.error, "Playlist not modified", "The playlist cannot be modified while tracks are being added", "Please wait till the playlist is done adding tracks ...")
        //            return
        //        }
        
        // Make sure there is at least one track to save
        if playQueue.size > 0 {
            
            let dialog = DialogsAndAlerts.savePlaylistDialog
            if dialog.runModal() == NSApplication.ModalResponse.OK, let file = dialog.url {
                playQueue.export(to: file)
            }
        }
    }
    
    func playSelectedItem() {
        currentViewController.playSelectedTrack()
    }
    
    @IBAction func clearAction(_ sender: AnyObject) {
        clear()
    }
    
    func clear() {
        
        playQueue.clear()
        viewControllers.forEach {$0.refreshTableView()}
        updateSummary()
    }
    
    @IBAction func moveTracksUpAction(_ sender: AnyObject) {
        moveTracksUp()
    }
    
    func moveTracksUp() {
        
        let rowCount = currentViewController.rowCount
        let selectedRows = currentViewController.selectedRows
        let selectedRowCount = selectedRows.count
        
        if rowCount > 1 && (1..<rowCount).contains(selectedRowCount) {
            
            let results = playQueue.moveTracksUp(selectedRows)
            if !results.isEmpty {
                viewControllers.forEach {$0.tracksMovedUp(results: results)}
            }
        }
    }
    
    @IBAction func moveTracksDownAction(_ sender: AnyObject) {
        moveTracksDown()
    }
    
    func moveTracksDown() {
        
        let rowCount = currentViewController.rowCount
        let selectedRows = currentViewController.selectedRows
        let selectedRowCount = selectedRows.count
        
        if rowCount > 1 && (1..<rowCount).contains(selectedRowCount) {
            
            let results = playQueue.moveTracksDown(selectedRows)
            if !results.isEmpty {
                viewControllers.forEach {$0.tracksMovedDown(results: results)}
            }
        }
    }
    
    private func moveTracksToTop() {
        
        let rowCount = currentViewController.rowCount
        let selectedRows = currentViewController.selectedRows
        let selectedRowCount = selectedRows.count
        
        if rowCount > 1 && (1..<rowCount).contains(selectedRowCount) {
        
            let results = playQueue.moveTracksToTop(selectedRows)
            if !results.isEmpty {
                viewControllers.forEach {$0.tracksMovedToTop(results: results)}
            }
        }
    }
    
    // Must have a non-empty playlist, and at least one selected row, but not all rows selected.
    private func moveTracksToBottom() {
        
        let rowCount = currentViewController.rowCount
        let selectedRows = currentViewController.selectedRows
        let selectedRowCount = selectedRows.count
        
        if rowCount > 1 && (1..<rowCount).contains(selectedRowCount) {
        
            let results = playQueue.moveTracksToBottom(selectedRows)
            if !results.isEmpty {
                viewControllers.forEach {$0.tracksMovedToBottom(results: results)}
            }
        }
    }
    
    func clearSelection() {
        currentViewController.clearSelection()
    }
    
    func invertSelection() {
        currentViewController.invertSelection()
    }
    
    func cropSelection() {
        
        let rowsToDelete: IndexSet = currentViewController.invertedSelection
        
        if !rowsToDelete.isEmpty {
            
            _ = playQueue.removeTracks(rowsToDelete)
            viewControllers.forEach {$0.refreshTableView()}
            
            updateSummary()
        }
    }
    
    func scrollToTop() {
        currentViewController.scrollToTop()
    }
    
    func scrollToBottom() {
        currentViewController.scrollToBottom()
    }
    
    func pageUp() {
        currentViewController.pageUp()
    }
    
    func pageDown() {
        currentViewController.pageDown()
    }
  
    @IBAction func closeWindowAction(_ sender: AnyObject) {
        window?.close()
    }
    
    // MARK: Appearance
    
    private func changeTextSize(_ textSize: TextSize) {
        
    }
    
    private func changeBackgroundColor(_ color: NSColor) {
        childContainerBoxes.forEach {$0.fillColor = color}
    }
    
    private func changeViewControlButtonColor(_ color: NSColor) {
        viewControlButtons.forEach {$0.reTint()}
    }
    
    private func changeFunctionButtonColor(_ color: NSColor) {
        functionButtons.forEach {$0.reTint()}
    }
    
    private func applyColorScheme(_ scheme: ColorScheme) {
        
        changeBackgroundColor(scheme.general.backgroundColor)
        changeViewControlButtonColor(scheme.general.viewControlButtonColor)
        changeFunctionButtonColor(scheme.general.functionButtonColor)
    }
}
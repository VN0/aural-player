import Cocoa

@IBDesignable
class PlayerView: NSView {
    
    @IBOutlet weak var infoBox: NSBox!
    @IBOutlet weak var controlsBox: NSBox!
    @IBOutlet weak var functionsBox: NSBox!
    @IBOutlet weak var gapBox: NSBox!
    @IBOutlet weak var artView: NSImageView!
    
    @IBOutlet weak var infoView: TrackInfoView!
    @IBOutlet weak var gapView: GapView!
    
    fileprivate let player: PlaybackInfoDelegateProtocol = ObjectGraph.getPlaybackInfoDelegate()
    
    fileprivate var infoBoxDefaultPosition: NSPoint { return NSPoint(x: 0, y: 52) }
    fileprivate var autoHideFields_showing: Bool = false
    
    func showView(_ playbackState: PlaybackState) {
        
        self.addSubview(controlsBox, positioned: .above, relativeTo: nil)
        self.addSubview(functionsBox)
        
        controlsBox.setFrameOrigin(NSPoint.zero)

        infoView.showView(playbackState)
        gapView.showView(playbackState)
        
        playbackState == .waiting ? showGapFields() : showPlayingTrackFields()
    }
    
    fileprivate func moveInfoBoxTo(_ point: NSPoint) {
        
        infoBox.setFrameOrigin(point)
        gapBox.coLocate(infoBox)
        centerFunctionsBox()
    }
    
    fileprivate func centerFunctionsBox() {
        
        // Vertically center functions box w.r.t. info box
        let funcY = infoBox.frame.minY + (infoBox.frame.height / 2) - (functionsBox.frame.height / 2) - 2
        functionsBox.setFrameOrigin(NSPoint(x: self.frame.width - 5 - functionsBox.frame.width, y: funcY))
    }
    
    func hideView() {
        
        controlsBox.removeFromSuperview()
        functionsBox.removeFromSuperview()
    }
    
    func showOrHidePlayingTrackInfo() {
        
        PlayerViewState.showTrackInfo = !PlayerViewState.showTrackInfo
        infoBox.showIf_elseHide(PlayerViewState.showTrackInfo)
    }
    
    func showOrHideSequenceInfo() {
        infoView.showOrHideSequenceInfo()
    }
    
    func showOrHideAlbumArt() {
        
        PlayerViewState.showAlbumArt = !PlayerViewState.showAlbumArt
        artView.showIf_elseHide(PlayerViewState.showAlbumArt)
    }
    
    func showOrHidePlayingTrackFunctions() {
        
        PlayerViewState.showPlayingTrackFunctions = !PlayerViewState.showPlayingTrackFunctions
        functionsBox.showIf_elseHide(PlayerViewState.showPlayingTrackFunctions)
    }
    
    func showOrHideMainControls() {
        
        PlayerViewState.showControls = !PlayerViewState.showControls
        controlsBox.showIf_elseHide(PlayerViewState.showControls)
    }
    
    func mouseEntered() {
        autoHideFields_showing = true
    }
    
    func mouseExited() {
        autoHideFields_showing = false
    }
    
    func needsMouseTracking() -> Bool {
        return false
    }
    
    // MARK: Track info functions
    
    func showNowPlayingInfo(_ track: Track, _ playbackState: PlaybackState, _ sequence: (scope: SequenceScope, trackIndex: Int, totalTracks: Int)) {
        
        infoView.showNowPlayingInfo(track, sequence)
        showPlayingTrackFields()
        
        let trackArt = track.displayInfo.art
        artView.image = trackArt != nil ? trackArt! : (playbackState == .playing ? Images.imgPlayingArt : Images.imgPausedArt)
    }
    
    func clearNowPlayingInfo() {
        
        infoView.clearNowPlayingInfo()
        showPlayingTrackFields()
        
        artView.image = Images.imgPausedArt
    }
    
    func sequenceChanged(_ sequence: (scope: SequenceScope, trackIndex: Int, totalTracks: Int)) {
        infoView.sequenceChanged(sequence)
    }
    
    func gapStarted(_ msg: PlaybackGapStartedAsyncMessage) {
        
        showGapFields()
        
        let track = msg.nextTrack.track
        let trackArt = track.displayInfo.art
        artView.image = trackArt != nil ? trackArt! : Images.imgPausedArt
        
        gapView.gapStarted(msg)
    }
    
    private func showGapFields() {
        
        gapBox.coLocate(infoBox)
        gapBox.show()
        hideViews(infoBox, functionsBox)
    }
    
    fileprivate func showPlayingTrackFields() {
        
        if gapBox.isShown {
            
            gapBox.hide()
            gapView.endGap()
            
            infoBox.showIf_elseHide(PlayerViewState.showTrackInfo || autoHideFields_showing)
            functionsBox.showIf_elseHide(PlayerViewState.showPlayingTrackFunctions)
        }
    }
    
    func handOff(_ otherView: PlayerView) {
        
        infoView.handOff(otherView.infoView)
        gapView.handOff(otherView.gapView)
        otherView.artView.image = artView.image
    }
}

@IBDesignable
class DefaultPlayerView: PlayerView {
    
    override var infoBoxDefaultPosition: NSPoint { return NSPoint(x: 90, y: 85) }
    private let infoBoxCenteredPosition: NSPoint = NSPoint(x: 90, y: 52)
    
    override func showView(_ playbackState: PlaybackState) {
        
        super.showView(playbackState)

        moveInfoBoxTo(PlayerViewState.showControls ? infoBoxDefaultPosition : infoBoxCenteredPosition)
        
        artView.showIf_elseHide(PlayerViewState.showAlbumArt)
        functionsBox.showIf_elseHide(PlayerViewState.showPlayingTrackFunctions)
        infoBox.show()
        controlsBox.showIf_elseHide(PlayerViewState.showControls)
    }
    
    override fileprivate func moveInfoBoxTo(_ point: NSPoint) {
        
        super.moveInfoBoxTo(point)
        artView.frame.origin.y = infoBox.frame.origin.y
    }
    
    override func showOrHideMainControls() {
        
        super.showOrHideMainControls()
        
        // Re-position the info box, art view, and functions box
        moveInfoBoxTo(PlayerViewState.showControls ? infoBoxDefaultPosition : infoBoxCenteredPosition)
    }
    
    override func showOrHidePlayingTrackInfo() {
        // Do nothing (this function is not allowed on the default player view)
    }
    
    override func mouseEntered() {
        
        super.mouseEntered()
        
        if !PlayerViewState.showControls {
            autoHideControls_show()
        }
    }
    
    override func mouseExited() {
        
        super.mouseExited()
        
        if !PlayerViewState.showControls {
            autoHideControls_hide()
        }
    }
    
    private func autoHideControls_show() {
        
        // Show controls
        controlsBox.show()
        moveInfoBoxTo(infoBoxDefaultPosition)
    }
    
    private func autoHideControls_hide() {
        
        // Hide controls
        controlsBox.hide()
        moveInfoBoxTo(infoBoxCenteredPosition)
    }
    
    override fileprivate func showPlayingTrackFields() {
        
        super.showPlayingTrackFields()
        infoBox.show()
    }
    
    override func needsMouseTracking() -> Bool {
        return !PlayerViewState.showControls
    }
}

@IBDesignable
class ExpandedArtPlayerView: PlayerView {
    
    private let infoBoxTopPosition: NSPoint = NSPoint(x: 0, y: 85)
    @IBOutlet weak var overlayBox: NSBox!
    
    override func showView(_ playbackState: PlaybackState) {
        
        super.showView(playbackState)
        
        moveInfoBoxTo(infoBoxDefaultPosition)
        
        artView.show()
        functionsBox.showIf_elseHide(PlayerViewState.showPlayingTrackFunctions)
        infoBox.showIf_elseHide(PlayerViewState.showTrackInfo)
        infoBox.isTransparent = false

        hideViews(controlsBox, overlayBox)
    }
    
    override func showOrHideMainControls() {
        // Do nothing (this function is not allowed on the expanded art player view)
    }
    
    override func showOrHideAlbumArt() {
        // Do nothing (this function is not allowed on the expanded art player view)
    }
    
    override func mouseEntered() {
        
        super.mouseEntered()
        
        autoHideControls_show()
        
        if !PlayerViewState.showTrackInfo {
            autoHideInfo_show()
        }
    }
    
    override func mouseExited() {
        
        super.mouseExited()
        
        if !PlayerViewState.showTrackInfo {
            autoHideInfo_hide()
        }
        
        autoHideControls_hide()
    }
    
    private func autoHideInfo_show() {
        
        makeTransparent(infoBox, gapBox)
        infoBox.showIf_elseHide(player.getPlaybackState().playingOrPaused())
    }
    
    private func autoHideInfo_hide() {
        
        makeOpaque(infoBox, gapBox)
        infoBox.hide()
    }
    
    private func autoHideControls_show() {
        
        // Show controls
        showViews(controlsBox, overlayBox)
        
        makeTransparent(infoBox, controlsBox, gapBox)
        [infoBox, controlsBox, functionsBox, gapBox].forEach({bringViewToFront($0)})
        
        // Re-position the info box, art view, and functions box
        moveInfoBoxTo(infoBoxTopPosition)
        infoBox.showIf_elseHide(player.getPlaybackState().playingOrPaused())
    }
    
    private func autoHideControls_hide() {
        
        // Hide controls
        hideViews(overlayBox, controlsBox)
        
        makeOpaque(infoBox, controlsBox, gapBox)
        moveInfoBoxTo(infoBoxDefaultPosition)
        
        // Show info box as overlay temporarily
        infoBox.hideIf(!PlayerViewState.showTrackInfo)
    }
    
    override func needsMouseTracking() -> Bool {
        return true
    }
}

fileprivate func showViews(_ views: NSView...) {
    views.forEach({$0.show()})
}

fileprivate func hideViews(_ views: NSView...) {
    views.forEach({$0.hide()})
}

fileprivate func makeTransparent(_ boxes: NSBox...) {
    boxes.forEach({$0.isTransparent = true})
}

fileprivate func makeOpaque(_ boxes: NSBox...) {
    boxes.forEach({$0.isTransparent = false})
}

fileprivate func bringViewToFront(_ aView: NSView) {
    
    let superView = aView.superview
    aView.removeFromSuperview()
    superView?.addSubview(aView, positioned: .above, relativeTo: nil)
}

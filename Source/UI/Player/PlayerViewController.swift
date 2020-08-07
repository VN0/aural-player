/*
    View controller that handles the assembly of the player view tree from its multiple pieces, and switches between high-level views depending on current player state (i.e. playing / stopped, etc).
 
    The player view tree consists of:
        
        - Playing track info (track info, art, etc)
            - Default view
            - Expanded Art view
 
        - Waiting track info (when a track is waiting to play after a delay)
 
        - Player controls (play/seek, next/previous track, repeat/shuffle, volume/balance)
 
        - Functions toolbar (detailed track info / favorite / bookmark, etc)
 */
import Cocoa

class PlayerViewController: NSViewController, NotificationSubscriber {
    
//    private var playingTrackView: PlayingTrackView = ViewFactory.playingTrackView as! PlayingTrackView
//    private var waitingTrackView: NSView = ViewFactory.waitingTrackView
//    
//    // Delegate that conveys all seek and playback info requests to the player
//    private let player: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
//    
//    override var nibName: String? {return "Player"}
//    
//    override func viewDidLoad() {
//        
//        [playingTrackView, waitingTrackView, transcodingTrackView].forEach({
//            
//            self.view.addSubview($0)
//            $0.setFrameOrigin(NSPoint.zero)
//        })
//
//        switchView()
//        Messenger.subscribeAsync(self, .player_trackTransitioned, self.switchView, queue: .main)
//    }
//    
//    // Depending on current player state, switch to one of the 3 views.
//    func switchView() {
//        
//        switch player.state {
//
//        case .noTrack, .playing, .paused:
//            
//            NSView.hideViews(waitingTrackView, transcodingTrackView)
//            playingTrackView.showView()
//
//        case .waiting:
//            
//            playingTrackView.hideView()
//            transcodingTrackView.hide()
//            
//            waitingTrackView.show()
//
//        case .transcoding:
//            
//            playingTrackView.hideView()
//            waitingTrackView.hide()
//            
//            transcodingTrackView.show()
//        }
//    }
}

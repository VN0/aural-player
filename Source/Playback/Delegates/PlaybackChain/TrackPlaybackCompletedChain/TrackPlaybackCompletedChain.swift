import Foundation

class TrackPlaybackCompletedChain: PlaybackChain {
    
    private let startPlaybackChain: StartPlaybackChain
    private let stopPlaybackChain: StopPlaybackChain
    
    private let sequencer: PlaybackSequencerProtocol
    
    init(_ startPlaybackChain: StartPlaybackChain, _ stopPlaybackChain: StopPlaybackChain, _ sequencer: PlaybackSequencerProtocol, _ playlist: PlaylistCRUDProtocol, _ profiles: PlaybackProfiles, _ preferences: PlaybackPreferences) {
        
        self.startPlaybackChain = startPlaybackChain
        self.stopPlaybackChain = stopPlaybackChain
        self.sequencer = sequencer
        
        super.init()
        
        _ = withAction(ResetPlaybackProfileAction(profiles))
        .withAction(DelayAfterTrackCompletionAction(playlist, sequencer, preferences))
    }
    
    override func execute(_ context: PlaybackRequestContext) {
        
        super.execute(context)
        
        // Continue playback with the subsequent track.
        if let subsequentTrack = sequencer.subsequent() {
            
            context.requestedTrack = subsequentTrack.track
            context.cancelWaitingOrTranscoding = false
            
            startPlaybackChain.execute(context)
            
        }
        // Stop playback if there is no subsequent track.
        else {
            
            context.requestedTrack = nil
            context.cancelWaitingOrTranscoding = true
            
            stopPlaybackChain.execute(context)
        }
    }
}
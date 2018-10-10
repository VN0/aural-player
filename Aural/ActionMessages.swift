import Foundation

// Contract for a subscriber to an ActionMessage
protocol ActionMessageSubscriber {
    
    // Every message subscriber must implement this method to consume the type of message it is interested in
    func consumeMessage(_ message: ActionMessage)
    
    func getID() -> String
}

/*
    A message sent from one UI component to another, to request that some action be performed. Example - the master playlist view controller (PlaylistViewController) sends action messsages to its child view controllers (for each of the 4 playlist views) requesting each of them to refresh their views when new tracks are added to the playlist.
 */
protocol ActionMessage {
    
    // Specifies the type of action/function to be performed by the recipient of the message
    var actionType: ActionType {get}
}

// Enumeration of the different message types. See the various Message structs below, for descriptions of each message type.
enum ActionType {
    
    // MARK: Playlist actions
    
    // Refresh the entire view
    case refresh
    
    // Add tracks to playlist
    case addTracks
    
    // Remove tracks from playlist
    case removeTracks
    
    // Save playlist to file
    case savePlaylist
    
    // Clear the playlist of all tracks
    case clearPlaylist
    
    // Show the currently playing track within the current playlist view, if there is one
    case showPlayingTrack
    
    // Play the item selected within the current playlist view
    case playSelectedItem
    
    // Insert a playback gap before/after the selected track
    case insertGap
    
    case removeGap
    
    // Move selected items up one row within playlist
    case moveTracksUp
    
    // Move selected items down one row within playlist
    case moveTracksDown
    
    // Show the selected track in Finder
    case showTrackInFinder
    
    // Switch playlist tabs to switch between playlist views
    case shiftTab
    
    // Invoke the search dialog
    case search
    
    // Invoke the sort dialog
    case sort
    
    case invertSelection
    
    // Crop selection
    case cropSelection
    
    // Scroll to the top of the playlist
    case scrollToTop
    
    // Scroll to the bottom of the playlist
    case scrollToBottom
    
    // Switch to the previous playlist view (in the tab group)
    case previousPlaylistView
    
    // Switch to the next playlist view (in the tab group)
    case nextPlaylistView
    
    // Display detailed track info popover for the selected playlist track
    case selectedTrackInfo
    
    // MARK: Playlist window actions
    
    // Dock playlist to the left of the main window
    case dockLeft
    
    // Dock playlist to the right of the main window
    case dockRight
    
    // Dock playlist below the main window
    case dockBottom
    
    // Maximize playlist both horizontally and vertically
    case maximize
    
    // Maximize playlist horizontally
    case maximizeHorizontal
    
    // Maximize playlist vertically
    case maximizeVertical
    
    // MARK: Playback actions
    
    // Play, pause, or resume playback
    case playOrPause
    
    // Replay the currently playing track from the beginning, if there is one
    case replayTrack
    
    // Toggle A->B segment playback loop
    case toggleLoop
    
    // Play the previous track in the current playback sequence
    case previousTrack
    
    // Play the next track in the current playback sequence
    case nextTrack
    
    // Seek backward within the currently playing track
    case seekBackward
    
    // Seek forward within the currently playing track
    case seekForward
    
    // Seek backward within the currently playing track
    case seekBackward_secondary
    
    // Seek forward within the currently playing track
    case seekForward_secondary
    
    // Set repeat mode to "Off"
    case repeatOff
    
    // Set repeat mode to "Repeat One"
    case repeatOne
    
    // Set repeat mode to "Repeat All"
    case repeatAll
    
    // Set shuffle mode to "Off"
    case shuffleOff
    
    // Set shuffle mode to "On"
    case shuffleOn
    
    // Show detailed info for the currently playing track
    case moreInfo
    
    // MARK: Audio graph actions
    
    case enableEffects
    
    case disableEffects
    
    // Mute or unmute the player
    case muteOrUnmute
    
    // Sets the volume to a specific value
    case setVolume
    
    // Increases the volume by a certain preset increment
    case increaseVolume
    
    // Decreases the volume by a certain preset decrement
    case decreaseVolume
    
    // Sets the stereo pan to a specific value
    case setPan
    
    // Pans the sound towards the left channel, by a certain preset value
    case panLeft
    
    // Pans the sound towards the right channel, by a certain preset value
    case panRight
    
    // Provides a "bass boost". Increases each of the EQ bass bands by a certain preset increment.
    case increaseBass
    
    // Decreases each of the EQ bass bands by a certain preset decrement
    case decreaseBass
    
    // Increases each of the EQ mid-frequency bands by a certain preset increment
    case increaseMids
    
    // Decreases each of the EQ mid-frequency bands by a certain preset decrement
    case decreaseMids
    
    // Decreases each of the EQ treble bands by a certain preset increment
    case increaseTreble
    
    // Decreases each of the EQ treble bands by a certain preset decrement
    case decreaseTreble
    
    // Increases the pitch by a certain preset increment
    case increasePitch
    
    // Decreases the pitch by a certain preset decrement
    case decreasePitch
    
    // Sets the pitch to a specific value
    case setPitch
    
    // Increases the playback rate by a certain preset increment
    case increaseRate
    
    // Decreases the playback rate by a certain preset decrement
    case decreaseRate
    
    // Sets the playback rate to a specific value
    case setRate
    
    // Saves the current settings in a sound profile for the current track
    case saveSoundProfile
    
    case deleteSoundProfile
    
    case savePlaybackProfile
    
    case deletePlaybackProfile
    
    // MARK: Effects view actions
    
    // Switches the Effects panel tab group to a specfic tab
    case showEffectsUnitTab
    
    case updateEffectsView
    
    // MARK: View actions
    
    // Show/hide the playlist window
    case togglePlaylist
    
    // Show/hide the Effects panel
    case toggleEffects
    
    case bookmark
    
    case windowLayout
    
    // MARK: App mode actions
    
    case regularAppMode
    
    case statusBarAppMode
    
    case miniBarAppMode
    
    // MARK: Effects presets editor actions
    
    case renameEffectsPreset
    case deleteEffectsPresets
    case applyEffectsPreset
    
    // MARK: Mini bar actions
    
    case dockTopLeft
    case dockTopRight
    case dockBottomLeft
    case dockBottomRight
}

enum ActionMode {
    
    case discrete
    
    case continuous
}

// A message sent to one of the playlist view controllers, either from another playlist view controller or from another app component, to perform some action on the playlist.
struct PlaylistActionMessage: ActionMessage {
    
    var actionType: ActionType
    
    // Specifies the type of playlist to which this action applies. A nil value indicates that it is independent of playlist type, i.e. applies to all of them.
    let playlistType: PlaylistType?
    
    init(_ actionType: ActionType, _ playlistType: PlaylistType?) {
        self.actionType = actionType
        self.playlistType = playlistType
    }
}

struct MiniBarActionMessage: ActionMessage {
    
    var actionType: ActionType
    
    init(_ actionType: ActionType) {
        self.actionType = actionType
    }
}

// A message sent to the playback view controller to perform a playback function.
struct PlaybackActionMessage: ActionMessage {
    
    var actionType: ActionType
    var actionMode: ActionMode
    
    init(_ actionType: ActionType, _ actionMode: ActionMode = .discrete) {
        self.actionType = actionType
        self.actionMode = actionMode
    }
}

// A message sent to the audio graph view controller to perform an audio graph (i.e. sound altering) function.
struct AudioGraphActionMessage: ActionMessage {
    
    var actionType: ActionType
    var actionMode: ActionMode
    
    // A generic numerical parameter value whose meaning depends on the action type. Example, if actionType = setRate, this value represents the desired playback rate.
    var value: Float?
    
    init(_ actionType: ActionType, _ actionMode: ActionMode = .discrete, _ value: Float? = nil) {
        
        self.actionType = actionType
        self.actionMode = actionMode
        self.value = value
    }
}

// A message sent to the window controller to perform a view-related function.
struct ViewActionMessage: ActionMessage {
    
    var actionType: ActionType
    
    init(_ actionType: ActionType) {
        self.actionType = actionType
    }
}

// A message sent to the effects view controller to perform a function related to the effects view (e.g. switch to a certain effects unit tab)
struct EffectsViewActionMessage: ActionMessage {
    
    var actionType: ActionType
 
    // The effects unit that is the sender of this message
    let effectsUnit: EffectsUnit
    
    init(_ actionType: ActionType, _ effectsUnit: EffectsUnit) {
        self.actionType = actionType
        self.effectsUnit = effectsUnit
    }
}

struct AppModeActionMessage: ActionMessage {
    
    var actionType: ActionType
    
    init(_ actionType: ActionType) {
        self.actionType = actionType
    }
}

struct BookmarkActionMessage: ActionMessage {
    
    let actionType: ActionType = .bookmark
    
    private init() {}
    
    static let instance: BookmarkActionMessage = BookmarkActionMessage()
}

struct WindowLayoutActionMessage: ActionMessage {
    
    let actionType: ActionType = .windowLayout
    
    let layout: WindowLayoutPresets
    
    init(_ layout: WindowLayoutPresets) {
        self.layout = layout
    }
}

struct SoundProfileActionMessage: ActionMessage {
    
    let actionType: ActionType
    
    private init(_ actionType: ActionType) {self.actionType = actionType}
    
    static let save: SoundProfileActionMessage = SoundProfileActionMessage(.saveSoundProfile)
    
    static let delete: SoundProfileActionMessage = SoundProfileActionMessage(.deleteSoundProfile)
}

struct PlaybackProfileActionMessage: ActionMessage {
    
    let actionType: ActionType
    
    private init(_ actionType: ActionType) {self.actionType = actionType}
    
    static let save: PlaybackProfileActionMessage = PlaybackProfileActionMessage(.savePlaybackProfile)
    
    static let delete: PlaybackProfileActionMessage = PlaybackProfileActionMessage(.deletePlaybackProfile)
}

struct EffectsPresetsEditorActionMessage: ActionMessage {
    
    let actionType: ActionType
    let effectsPresetsUnit: EffectsUnit
    
    init(_ actionType: ActionType, _ effectsPresetsUnit: EffectsUnit) {
        self.actionType = actionType
        self.effectsPresetsUnit = effectsPresetsUnit
    }
}

struct InsertPlaybackGapActionMessage: ActionMessage {
    
    let actionType: ActionType = .insertGap
    
    let track: Track
    let gap: PlaybackGap
    let playlistType: PlaylistType?
    
    init(_ track: Track, _ gap: PlaybackGap, _ playlistType: PlaylistType?) {
        self.track = track
        self.gap = gap
        self.playlistType = playlistType
    }
}

struct RemovePlaybackGapActionMessage: ActionMessage {
    
    let actionType: ActionType = .removeGap
    
    let track: Track
    let position: PlaybackGapPosition
    let playlistType: PlaylistType?
    
    init(_ track: Track, _ position: PlaybackGapPosition, _ playlistType: PlaylistType?) {
        self.track = track
        self.position = position
        self.playlistType = playlistType
    }
}

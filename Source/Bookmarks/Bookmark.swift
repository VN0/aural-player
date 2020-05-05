import Cocoa

class Bookmark: StringKeyedItem, PlayableItem {
    
    // A name or description (e.g. "2nd chapter of audiobook")
    private var _name: String
    
    // Used by the UI (track.conciseDisplayName)
    var name: String {
        
        get {
            
            if let track = self.track {
                return track.conciseDisplayName
            }
            
            return _name
        }
        
        set(newValue) {
            _name = newValue
        }
    }
    
    var key: String {
        
        get {
            return name
        }
        
        set(newValue) {
            name = newValue
        }
    }
    
    // The file of the track being bookmarked
    let file: URL
    
    var track: Track?
    
    // Seek position within track, expressed in seconds
    let startPosition: Double
    
    // Seek position within track, expressed in seconds
    let endPosition: Double?
    
    convenience init(_ name: String, _ file: URL, _ startPosition: Double) {
        self.init(name, file, startPosition, nil)
    }
    
    init(_ name: String, _ file: URL, _ startPosition: Double, _ endPosition: Double?) {
        
        self._name = name
        self.file = file
        self.startPosition = startPosition
        self.endPosition = endPosition
    }
    
    init(_ name: String, _ track: Track, _ startPosition: Double, _ endPosition: Double?) {
        
        self._name = name
        self.track = track
        self.file = track.file
        self.startPosition = startPosition
        self.endPosition = endPosition
    }
}
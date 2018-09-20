import Foundation

class PitchPresets {
    
    private static var presets: [String: PitchPreset] = {
        
        var map = [String: PitchPreset]()
        SystemDefinedPitchPresets.allValues.forEach({
            map[$0.rawValue] = PitchPreset(name: $0.rawValue, pitch: $0.pitch, overlap: $0.overlap, systemDefined: true)
        })
        
        return map
    }()
    
    static var userDefinedPresets: [PitchPreset] {
        return presets.values.filter({$0.systemDefined == false})
    }
    
    static var systemDefinedPresets: [PitchPreset] {
        return presets.values.filter({$0.systemDefined == true})
    }
    
    static var defaultPreset: PitchPreset {
        return presetByName(SystemDefinedPitchPresets.normal.rawValue)
    }
    
    static func presetByName(_ name: String) -> PitchPreset {
        return presets[name] ?? defaultPreset
    }
    
    static func loadUserDefinedPresets(_ userDefinedPresets: [PitchPreset]) {
        userDefinedPresets.forEach({presets[$0.name] = $0})
    }
    
    // Assume preset with this name doesn't already exist
    static func addUserDefinedPreset(_ name: String, _ pitch: Float, _ overlap: Float) {
        presets[name] = PitchPreset(name: name, pitch: pitch, overlap: overlap, systemDefined: false)
    }
    
    static func presetWithNameExists(_ name: String) -> Bool {
        return presets[name] != nil
    }
}

// TODO: Make this a sibling of EQPreset with a protocol
struct PitchPreset {
    
    let name: String
    let pitch: Float
    let overlap: Float
    let systemDefined: Bool
}

/*
    An enumeration of built-in pitch presets the user can choose from
 */
fileprivate enum SystemDefinedPitchPresets: String {
    
    case normal = "Normal"  // default
    case happyLittleGirl = "Happy little girl"
    case chipmunk = "Chipmunk"
    case oneOctaveUp = "+1 8ve"
    case twoOctavesUp = "+2 8ve"
    
    case deep = "A bit deep"
    case robocop = "Robocop"
    case oneOctaveDown = "-1 8ve"
    case twoOctavesDown = "-2 8ve"
    
    static var allValues: [SystemDefinedPitchPresets] = [.normal, .chipmunk, .happyLittleGirl, .oneOctaveUp, .twoOctavesUp, .deep, .robocop, .oneOctaveDown, .twoOctavesDown]
    
    // Converts a user-friendly display name to an instance of PitchPresets
    static func fromDisplayName(_ displayName: String) -> SystemDefinedPitchPresets {
        return SystemDefinedPitchPresets(rawValue: displayName) ?? .normal
    }
    
    var pitch: Float {
        
        switch self {
            
        case .normal:   return 0
            
        case .happyLittleGirl: return 0.3
            
        case .chipmunk: return 0.5
            
        case .oneOctaveUp:  return 1
            
        case .twoOctavesUp: return 2
            
        case .deep: return -0.3
            
        case .robocop:  return -0.5
            
        case .oneOctaveDown:    return -1
            
        case .twoOctavesDown:   return -2
            
        }
    }
    
    var overlap: Float {
        return 8
    }
}
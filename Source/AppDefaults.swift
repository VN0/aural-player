import Cocoa
import AVFoundation

/*
    Default values for app settings
*/
struct AppDefaults {
    
    static let repeatMode: RepeatMode = .off
    static let shuffleMode: ShuffleMode = .off
    
    static let volume: Float = 0.5
    static let balance: Float = 0
    static let muted: Bool = false
    
    static let masterState: EffectsUnitState = .active
    
    static let eqState: EffectsUnitState = .bypassed
    static let eqGlobalGain: Float = 0
    static let eqBandGain: Float = 0
    
    static let pitchState: EffectsUnitState = .bypassed
    static let pitch: PitchShift = PitchShift(fromCents: 0)
    
    static let pitchOctaves: Int = 0
    static let pitchSemitones: Int = 0
    static let pitchCents: Int = 0
    
    static let pitchOverlap: Float = 8
    
    static let timeState: EffectsUnitState = .bypassed
    static let timeStretchRate: Float = 1
    static let timeShiftPitch: Bool = false
    static let timeOverlap: Float = 8
    
    static let reverbState: EffectsUnitState = .bypassed
    static let reverbSpace: ReverbSpaces = .mediumHall
    static let reverbAmount: Float = 50
    
    static let delayState: EffectsUnitState = .bypassed
    static let delayAmount: Float = 100
    static let delayTime: Double = 1
    static let delayFeedback: Float = 50
    static let delayLowPassCutoff: Float = 15000

    static let filterState: EffectsUnitState = .bypassed
    static let filterBandType: FilterBandType = .bandStop
    static let filterBandMinFreq: Float = AppConstants.Sound.audibleRangeMin
    static let filterBandMaxFreq: Float = AppConstants.Sound.subBass_max
    
    static let lastTrackPosition: Double = 0
    
    static let playbackGapDuration: Double = 5
    static let playbackGapPosition: PlaybackGapPosition = .afterTrack
    static let playbackGapType: PlaybackGapType = .persistent
}

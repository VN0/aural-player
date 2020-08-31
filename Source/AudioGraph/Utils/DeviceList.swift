import AudioToolbox

class DeviceList {
    
    static var hardwareDevicesPropertyAddress: AudioObjectPropertyAddress =
        AudioObjectPropertyAddress(globalPropertyWithSelector: kAudioHardwarePropertyDevices)
    
    static let systemAudioObjectId: AudioObjectID = AudioObjectID(kAudioObjectSystemObject)
    
    // id -> Device
    private var knownDevices: [AudioDeviceID: AudioDevice] = [:]
    
    private(set) var devices: [AudioDevice] = []
    
    // id -> Device
    private var devicesMap: [AudioDeviceID: AudioDevice] = [:]
    
    // TODO: Make this thread-safe ???
    private var lastRebuildTime: Double = 0
    
    func deviceById(_ id: AudioDeviceID) -> AudioDevice? {devicesMap[id]}
    func deviceByUID(_ uid: String) -> AudioDevice? {devices.first(where: {$0.uid == uid})}

    init() {
        
        rebuildList()
        
        // Devices list change listener
        AudioObjectAddPropertyListenerBlock(Self.systemAudioObjectId, &Self.hardwareDevicesPropertyAddress, DispatchQueue.global(qos: .utility), {_, _ in
            
            let now = CFAbsoluteTimeGetCurrent()
            let timeDiff = now - self.lastRebuildTime
            
            self.lastRebuildTime = now
            
            if timeDiff > 0.1 {
                
                self.rebuildList()
                Messenger.publish(.deviceManager_deviceListUpdated)
            }
        })
    }
    
    private func rebuildList() {
        
        var propSize: UInt32 = 0
        if AudioObjectGetPropertyDataSize(Self.systemAudioObjectId, &Self.hardwareDevicesPropertyAddress,
                                          sizeOfPropertyAddress, nil, &propSize) != noErr {return}
        
        let numDevices = Int(propSize / sizeOfDeviceId)
        var deviceIds: [AudioDeviceID] = Array(repeating: AudioDeviceID(), count: numDevices)
        
        if AudioObjectGetPropertyData(Self.systemAudioObjectId, &Self.hardwareDevicesPropertyAddress, 0, nil, &propSize, &deviceIds) == noErr {
            
            devices.removeAll()
            devicesMap.removeAll()
            
            for deviceId in deviceIds {
                
                if let device = knownDevices[deviceId] ?? AudioDevice(deviceId: deviceId) {
                    
                    devices.append(device)
                    devicesMap[deviceId] = device
                    
                    if knownDevices[deviceId] == nil {
                        knownDevices[deviceId] = device
                    }
                }
            }
        }
    }
    
    func isDeviceAvailable(_ device: AudioDevice) -> Bool {devicesMap[device.id] != nil}
}

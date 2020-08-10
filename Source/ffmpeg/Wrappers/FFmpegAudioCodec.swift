import Foundation

///
/// A Codec that decodes (encoded) audio data packets into raw (PCM) frames.
///
class FFmpegAudioCodec: FFmpegCodec {
    
    ///
    /// Average bit rate of the encoded data.
    ///
    var bitRate: Int64 {params.bit_rate}
    
    ///
    /// Sample rate of the encoded data (i.e. number of samples per second or Hz).
    ///
    var sampleRate: Int32 {params.sample_rate}
    
    ///
    /// PCM format of the samples.
    ///
    var sampleFormat: FFmpegSampleFormat = FFmpegSampleFormat(encapsulating: AVSampleFormat(0))
    
    ///
    /// Number of channels of audio data.
    ///
    var channelCount: Int32 = 0
    
    ///
    /// Describes the number and physical / spatial arrangement of the channels. (e.g. "5.1 surround" or "stereo")
    ///
    var channelLayout: Int64 = 0
    
    ///
    /// Instantiates an AudioCodec object, given a pointer to its parameters.
    ///
    /// - Parameter paramsPointer: A pointer to parameters for the associated AVCodec object.
    ///
    override init(fromParameters paramsPointer: UnsafeMutablePointer<AVCodecParameters>) throws {
        
        try super.init(fromParameters: paramsPointer)
        
        self.sampleFormat = FFmpegSampleFormat(encapsulating: context.sample_fmt)
        self.channelCount = params.channels
        
        // Correct channel layout if necessary.
        // NOTE - This is necessary for some files like WAV files that don't specify a channel layout.
        self.channelLayout = context.channel_layout != 0 ? Int64(context.channel_layout) : av_get_default_channel_layout(context.channels)
    }
    
    ///
    /// Decodes a single packet and produces (potentially) multiple frames.
    ///
    /// - Parameter packet: The packet that needs to be decoded.
    ///
    /// - returns: An ordered list of frames.
    ///
    /// - throws: **DecoderError** if an error occurs during decoding.
    ///
    func decode(packet: FFmpegPacket) throws -> [FFmpegBufferedFrame] {
        
        // Send the packet to the decoder for decoding.
        let resultCode: Int32 = packet.send(to: self)
        
        // The packet may be destroyed at this point as it has already been sent to the codec.
        packet.destroy()

        // If the packet send failed, log a message and throw an error.
        if resultCode.isNegative {
            
            print("\nCodec.decode(): Failed to decode packet. Error: \(resultCode) \(resultCode.errorDescription))")
            throw DecoderError(resultCode)
        }
        
        return receiveFrames()
    }
    
    ///
    /// Receives frames from the decoder (after sending one packet to it).
    ///
    /// - returns: An ordered list of frames.
    ///
    private func receiveFrames() -> [FFmpegBufferedFrame] {
        
        // Receive (potentially) multiple frames

        // Resuse a single Frame object multiple times.
        let frame = FFmpegFrame(sampleFormat: self.sampleFormat)
        
        // Collect the received frames in an array.
        var bufferedFrames: [FFmpegBufferedFrame] = []
        
        // Receive a decoded frame from the codec.
        var resultCode: Int32 = frame.receive(from: self)
        
        // Keep receiving frames while no errors are encountered
        while resultCode.isZero, frame.hasSamples {
            
            bufferedFrames.append(FFmpegBufferedFrame(frame))
            frame.unreferenceBuffers()
            
            resultCode = frame.receive(from: self)
        }
        
        // The frame is no longer needed.
        frame.destroy()
        
        return bufferedFrames
    }
    
    func decodeAndDrop(packet: FFmpegPacket) {
        
        // Send the packet to the decoder for decoding.
        var resultCode: Int32 = packet.send(to: self)
        if resultCode.isNegative {return}
        
        var avFrame: AVFrame = AVFrame()
        
        repeat {
            resultCode = avcodec_receive_frame(contextPointer, &avFrame)
        } while resultCode.isZero && avFrame.nb_samples > 0
    }
    
    ///
    /// Drains the codec of all internally buffered frames.
    ///
    /// Call this function after reaching EOF within a stream.
    ///
    /// - throws: **DecoderError** if an error occurs while draining the codec.
    ///
    func drain() throws -> [FFmpegBufferedFrame] {
        
        // Send the "flush packet" to the decoder
        let resultCode: Int32 = avcodec_send_packet(contextPointer, nil)
        
        if resultCode.isNonZero {
            
            print("\nCodec.decode(): Failed to decode packet. Error: \(resultCode) \(resultCode.errorDescription))")
            throw DecoderError(resultCode)
        }
        
        return receiveFrames()
    }
    
    ///
    /// Flush this codec's internal buffers.
    ///
    /// Make sure to call this function prior to seeking within a stream.
    ///
    func flushBuffers() {
        avcodec_flush_buffers(contextPointer)
    }
    
    ///
    /// Print some codec info to the console.
    /// May be used to verify that the codec was properly read / initialized.
    /// Useful for debugging purposes.
    ///
    func printInfo() {
        
        print("\n---------- Codec Info ----------\n")
        
        print(String(format: "Codec Name:    %@", longName))
        print(String(format: "Sample Rate:   %7d", sampleRate))
        print(String(format: "Sample Format: %7@", sampleFormat.name))
        print(String(format: "Planar Samples ?: %7@", String(sampleFormat.isPlanar)))
        print(String(format: "Sample Size:   %7d", sampleFormat.size))
        print(String(format: "Channels:      %7d", channelCount))
        
        print("---------------------------------\n")
    }
}

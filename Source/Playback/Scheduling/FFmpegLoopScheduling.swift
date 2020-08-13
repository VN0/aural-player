import AVFoundation

extension FFmpegScheduler {
    
    var endOfLoop: Bool {decoder.endOfLoop}
    
    func playLoop(_ session: PlaybackSession, _ beginPlayback: Bool = true) {
        
        stop()
        scheduledBufferCount.value = 0
        
        guard let thePlaybackCtx = session.track.playbackContext as? FFmpegPlaybackContext, let loop = session.loop, let loopEndTime = loop.endTime else {return}
        self.playbackCtx = thePlaybackCtx
        
        print("\nPlaying loop with startTime = \(loop.startTime), endTime = \(loopEndTime)")
        
//        decoder.initialize(with: thePlaybackCtx.fileContext)
        
        initiateLoopDecodingAndScheduling(for: session, with: loop)
        
        // Check that at least one audio buffer was successfully scheduled, before beginning playback.
        if beginPlayback && scheduledBufferCount.isPositive {
            playerNode.play()
        }
    }
    
    func initiateLoopDecodingAndScheduling(for session: PlaybackSession, with loop: PlaybackLoop) {
        
        do {
            
            // If a seek position was specified, ask the decoder to seek
            // within the stream.
                
            try decoder.seek(to: loop.startTime)
            
            // Schedule one buffer for immediate playback
            decodeAndScheduleOneLoopBuffer(for: session, from: loop.startTime, maxSampleCount: playbackCtx.sampleCountForImmediatePlayback)
            
            // Schedule a second buffer asynchronously, for later, to avoid a gap in playback.
            // If this is not done, when the first buffer finishes playing, there will be
            // a gap in playback equal to the time taken to read/decode the next batch of
            // samples and construct and schedule the next buffer.
            //
            // So, at any given time, while a file is playing, there will always be one
            // extra buffer in the playback queue.
            //
            decodeAndScheduleOneLoopBufferAsync(for: session, maxSampleCount: playbackCtx.sampleCountForDeferredPlayback)
            
        } catch {
            print("\nDecoder threw error: \(error)")
        }
    }
    
    ///
    /// Asynchronously decodes and schedules a single audio buffer, of the given size (sample count), for playback.
    ///
    /// - Parameter maxSampleCount: The maximum number of samples to be decoded and scheduled for playback.
    ///
    /// # Notes #
    ///
    /// 1. If the decoder has already reached EOF prior to this function being called, nothing will be done. This function will
    /// simply return.
    ///
    /// 2. Since the task is enqueued on an OperationQueue (whose underlying queue is the global DispatchQueue),
    /// this function will not block the caller, i.e. the main thread, while the task executes.
    ///
    private func decodeAndScheduleOneLoopBufferAsync(for session: PlaybackSession, maxSampleCount: Int32) {
        
        if endOfLoop {return}
        
        self.schedulingOpQueue.addOperation {
            self.decodeAndScheduleOneLoopBuffer(for: session, maxSampleCount: maxSampleCount)
        }
    }

    ///
    /// Decodes and schedules a single audio buffer, of the given size (sample count), for playback.
    ///
    /// - Parameter maxSampleCount: The maximum number of samples to be decoded and scheduled for playback.
    ///
    /// ```
    /// Delegates to the decoder to decode and buffer a pre-determined (maximum) number of samples.
    ///
    /// Once the decoding is done, an AVAudioPCMBuffer is created from the decoder output, which is
    /// then actually sent to the audio engine for scheduling.
    /// ```
    /// # Notes #
    ///
    /// 1. If the decoder has already reached EOF prior to this function being called, nothing will be done. This function will
    /// simply return.
    ///
    /// 2. If the decoder reaches EOF when invoked from this function call, the number of samples decoded (and subsequently scheduled)
    /// may be less than the maximum sample count specified by the **maxSampleCount** parameter. However, in rare cases, the actual
    /// number of samples may be slightly larger than the maximum, because upon reaching EOF, the decoder will drain the codec's
    /// internal buffers which may result in a few additional samples that will be allowed as this is the terminal buffer.
    ///
    private func decodeAndScheduleOneLoopBuffer(for session: PlaybackSession, from seekPosition: Double? = nil, maxSampleCount: Int32) {
        
        if endOfLoop {return}
        
        // Ask the decoder to decode up to the given number of samples.
        let frameBuffer: FFmpegFrameBuffer = decoder.decodeLoop(maxSampleCount: maxSampleCount, loopEndTime: session.loop!.endTime!)
        
        // Transfer the decoded samples into an audio buffer that the audio engine can schedule for playback.
        if let audioBuffer: AVAudioPCMBuffer = frameBuffer.constructAudioBuffer(format: playbackCtx.audioFormat) {
            
            // Pass off the audio buffer to the audio engine. The completion handler is executed when
            // the buffer has finished playing.
            //
            // Note that:
            //
            // 1 - the completion handler recursively triggers another decoding / scheduling task.
            // 2 - the completion handler will be invoked by a background thread.
            // 3 - the completion handler will execute even when the player is stopped, i.e. the buffer
            //      has not really completed playback but has been removed from the playback queue.
            
            playerNode.scheduleBuffer(audioBuffer, for: session, completionHandler: self.loopBufferCompletionHandler(session), seekPosition, seekPosition != nil)
            
            // Upon scheduling the buffer, increment the counter.
            scheduledBufferCount.increment()
        }
    }
    
    func loopBufferCompleted(_ session: PlaybackSession) {
        
        // Audio buffer has completed playback, so decrement the counter.
        self.scheduledBufferCount.decrement()
        
        // If the buffer-associated session is not the same as the current session
        // (possible if stop() was called, eg. old buffers that complete when seeking), don't do anything.
        guard PlaybackSession.isCurrent(session) else {return}
        
        if !self.endOfLoop {

            // If EOF has not been reached, continue recursively decoding / scheduling.
            self.decodeAndScheduleOneLoopBufferAsync(for: session, maxSampleCount: playbackCtx.sampleCountForDeferredPlayback)

        } else if self.scheduledBufferCount.isZero {
            
            // EOF has been reached, and all buffers have completed playback.
            // Signal playback completion (on the main thread).

            DispatchQueue.main.async {
                self.loopCompleted(session)
            }
        }
    }
    
    func loopCompleted(_ session: PlaybackSession) {
        playLoop(session)
    }
    
    // Computes a segment completion handler closure, given a playback session.
    func loopBufferCompletionHandler(_ session: PlaybackSession) -> SessionCompletionHandler {
        
        return {(_ session: PlaybackSession) -> Void in
            self.loopBufferCompleted(session)
        }
    }
    
    func playLoop(_ playbackSession: PlaybackSession, _ playbackStartTime: Double, _ beginPlayback: Bool) {
        
    }
    
    func endLoop(_ playbackSession: PlaybackSession, _ loopEndTime: Double) {
        
    }
}
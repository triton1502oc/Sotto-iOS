import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

public final class ChimePlayer: NSObject, AVAudioPlayerDelegate {
    public static let shared = ChimePlayer()
    
    private let sampleRate: Double = 44100.0
    private var cachedWavData: Data?
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        self.cachedWavData = generateWavData()
    }
    
    /// Generates a two-tone musical chime identical to Android:
    /// Note 1: D5 (587.33 Hz) for 90ms with gentle decay
    /// Note 2: A5 (880.00 Hz) for 160ms with smooth bell-like exponential decay
    private func generateWavData() -> Data {
        let duration1 = 0.09
        let duration2 = 0.16
        let totalDuration = duration1 + duration2
        let totalSamples = Int(totalDuration * sampleRate)
        let numSamples1 = Int(duration1 * sampleRate)
        let numSamples2 = totalSamples - numSamples1
        
        let freq1 = 587.33
        let freq2 = 880.00
        
        var samples = [Int16](repeating: 0, count: totalSamples)
        
        // Note 1 (D5)
        for i in 0..<numSamples1 {
            let t = Double(i) / sampleRate
            let angle = 2.0 * Double.pi * freq1 * t
            let attack = min(Double(i) / (0.01 * sampleRate), 1.0)
            let decay = 1.0 - (Double(i) / Double(numSamples1)) * 0.3
            let envelope = attack * decay
            let rawSample = sin(angle) * envelope * Double(Int16.max) * 0.75
            let clamped = max(Double(Int16.min), min(Double(Int16.max), rawSample))
            samples[i] = Int16(clamped)
        }
        
        // Note 2 (A5)
        for i in 0..<numSamples2 {
            let t = Double(i) / sampleRate
            let angle = 2.0 * Double.pi * freq2 * t
            let attack = min(Double(i) / (0.008 * sampleRate), 1.0)
            let decay = exp(-4.5 * (Double(i) / Double(numSamples2)))
            let envelope = attack * decay
            let rawSample = (sin(angle) * 0.8 + sin(2.0 * angle) * 0.2) * envelope * Double(Int16.max) * 0.75
            let clamped = max(Double(Int16.min), min(Double(Int16.max), rawSample))
            samples[numSamples1 + i] = Int16(clamped)
        }
        
        // Create 44-byte WAV header + PCM data
        let pcmDataSize = UInt32(totalSamples * MemoryLayout<Int16>.size)
        let totalChunkSize = 36 + pcmDataSize
        
        var data = Data()
        data.reserveCapacity(44 + Int(pcmDataSize))
        
        // RIFF Header
        data.append(contentsOf: Array("RIFF".utf8))
        var chunkSizeLE = totalChunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeLE, count: 4))
        data.append(contentsOf: Array("WAVE".utf8))
        
        // "fmt " Subchunk
        data.append(contentsOf: Array("fmt ".utf8))
        var subchunk1Size: UInt32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: UInt16 = 1 // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: UInt16 = 1 // Mono
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateUInt = UInt32(sampleRate)
        data.append(Data(bytes: &sampleRateUInt, count: 4))
        var byteRate: UInt32 = UInt32(sampleRate) * 1 * 2
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: UInt16 = 1 * 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        
        // "data" Subchunk
        data.append(contentsOf: Array("data".utf8))
        var dataSizeLE = pcmDataSize.littleEndian
        data.append(Data(bytes: &dataSizeLE, count: 4))
        
        // Append PCM samples
        samples.withUnsafeBufferPointer { buffer in
            let rawBytes = Data(buffer: buffer)
            data.append(rawBytes)
        }
        
        return data
    }
    
    public func play() {
        #if canImport(UIKit)
        // Haptic feedback
        DispatchQueue.main.async {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
        }
        #endif
        
        // Audio playback
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let wavData = self.cachedWavData ?? self.generateWavData()
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
                try audioSession.setActive(true)
                
                let player = try AVAudioPlayer(data: wavData)
                player.delegate = self
                self.audioPlayer = player
                player.prepareToPlay()
                player.play()
            } catch {
                // Ignore audio playback errors
            }
        }
    }
}

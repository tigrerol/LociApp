import Foundation
import AVFoundation
import Combine

@Observable
@MainActor
class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false
    var speechCompleted = PassthroughSubject<Void, Never>()
    var selectedVoice: AVSpeechSynthesisVoice?
    var availableVoices: [AVSpeechSynthesisVoice] = []
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupVoices()
    }
    
    private func setupVoices() {
        // Get English voices
        availableVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.starts(with: "en")
        }
        
        // Set default voice (try to find a preferred one, fallback to first available)
        selectedVoice = availableVoices.first { $0.identifier.contains("com.apple.ttsbundle.Samantha-compact") } 
                    ?? availableVoices.first { $0.language == "en-US" }
                    ?? availableVoices.first
        
        print("Available voices: \(availableVoices.count)")
        print("Selected voice: \(selectedVoice?.name ?? "None")")
    }
    
    func speak(text: String) {
        guard !text.isEmpty else {
            return
        }
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
    }
    
    func getVoiceName(_ voice: AVSpeechSynthesisVoice) -> String {
        return voice.name
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        // Send completion notification
        speechCompleted.send()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
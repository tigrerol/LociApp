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
    
    enum VoiceQuality: Int, CaseIterable {
        case standard = 0
        case enhanced = 1
        case premium = 2
        
        var description: String {
            switch self {
            case .standard: return "Standard"
            case .enhanced: return "Enhanced"
            case .premium: return "Premium"
            }
        }
    }
    
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
        
        // Sort voices by quality (premium first, then enhanced, then standard)
        availableVoices.sort { voice1, voice2 in
            let quality1 = detectVoiceQuality(voice1)
            let quality2 = detectVoiceQuality(voice2)
            
            if quality1.rawValue != quality2.rawValue {
                return quality1.rawValue > quality2.rawValue
            }
            
            // If same quality, prefer US English
            if voice1.language == "en-US" && voice2.language != "en-US" {
                return true
            }
            if voice2.language == "en-US" && voice1.language != "en-US" {
                return false
            }
            
            // Finally, sort by name
            return voice1.name < voice2.name
        }
        
        // Select the highest quality voice available
        selectedVoice = availableVoices.first
        
        #if DEBUG
        print("Available voices: \(availableVoices.count)")
        print("Selected voice: \(selectedVoice?.name ?? "None") (\(detectVoiceQuality(selectedVoice!).description))")
        
        // Print voice quality distribution for debugging
        let qualityDistribution = availableVoices.reduce(into: [VoiceQuality: Int]()) { result, voice in
            let quality = detectVoiceQuality(voice)
            result[quality, default: 0] += 1
        }
        print("Voice quality distribution: \(qualityDistribution)")
        #endif
    }
    
    private func detectVoiceQuality(_ voice: AVSpeechSynthesisVoice) -> VoiceQuality {
        let identifier = voice.identifier.lowercased()
        let name = voice.name.lowercased()
        
        // Premium/Neural voices (highest quality)
        if identifier.contains("siri") || name.contains("siri") {
            return .premium
        }
        
        // Enhanced voices (better quality)
        if identifier.contains("enhanced") || 
           identifier.contains("premium") ||
           name.contains("enhanced") ||
           name.contains("premium") {
            return .enhanced
        }
        
        // Specific high-quality voice identifiers
        let premiumIdentifiers = [
            "com.apple.ttsbundle.siri",
            "com.apple.speech.synthesis.voice",
            "com.apple.ttsbundle.daniel-compact",
            "com.apple.ttsbundle.moira-compact",
            "com.apple.ttsbundle.karen-compact"
        ]
        
        for premiumId in premiumIdentifiers {
            if identifier.contains(premiumId) {
                return .premium
            }
        }
        
        // Enhanced quality identifiers
        let enhancedIdentifiers = [
            "com.apple.ttsbundle.samantha-compact",
            "com.apple.ttsbundle.alex-compact",
            "com.apple.ttsbundle.victoria-compact"
        ]
        
        for enhancedId in enhancedIdentifiers {
            if identifier.contains(enhancedId) {
                return .enhanced
            }
        }
        
        // Default to standard quality
        return .standard
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
        
        // Optimize speech parameters for better quality and comprehension
        utterance.rate = getOptimalSpeechRate()
        utterance.pitchMultiplier = getOptimalPitch()
        utterance.volume = 0.8  // Slightly reduced volume for better quality
        
        // Add natural pauses for better comprehension
        utterance.postUtteranceDelay = 0.1
        utterance.preUtteranceDelay = 0.05
        
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
    
    func getVoiceQuality(_ voice: AVSpeechSynthesisVoice) -> VoiceQuality {
        return detectVoiceQuality(voice)
    }
    
    private func getOptimalSpeechRate() -> Float {
        // Slower than default for better comprehension of location learning
        // Default is ~0.5, we use 0.45 for clearer pronunciation
        return AVSpeechUtteranceDefaultSpeechRate * 0.9
    }
    
    private func getOptimalPitch() -> Float {
        // Slightly lower pitch for more natural and pleasant listening
        return 0.95
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
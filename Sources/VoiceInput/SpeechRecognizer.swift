import Foundation
import AVFoundation
import Speech

enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition or microphone access was not authorized."
        case .recognizerUnavailable:
            return "SFSpeechRecognizer could not be created for the current locale."
        }
    }
}

final class SpeechRecognizer: NSObject {

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onRMSUpdate: ((Float) -> Void)?
    var onError: ((Error) -> Void)?

    private(set) var localeCode: String

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var finalTranscription: String = ""

    init(localeCode: String = "zh-CN") {
        self.localeCode = localeCode
        super.init()
    }

    func startRecording() async throws {
        resetState()

        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard authStatus == .authorized else {
            throw SpeechRecognizerError.notAuthorized
        }

        let micAuth = await AVAudioApplication.requestRecordPermission()
        guard micAuth else {
            throw SpeechRecognizerError.notAuthorized
        }

        let locale = Locale(identifier: localeCode)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw SpeechRecognizerError.recognizerUnavailable
        }
        self.speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.recognitionRequest?.append(buffer)
            let rms = self.computeRMS(from: buffer)
            Task { @MainActor [weak self] in
                self?.onRMSUpdate?(rms)
            }
        }

        self.audioEngine = engine

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error {
                Task { @MainActor [weak self] in
                    self?.onError?(error)
                }
                return
            }

            guard let result else { return }

            let transcription = result.bestTranscription.formattedString

            if result.isFinal {
                self.finalTranscription = transcription
                Task { @MainActor [weak self] in
                    self?.onFinalResult?(transcription)
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.onPartialResult?(transcription)
                }
            }
        }
        self.recognitionTask = task

        try engine.start()
    }

    func stopRecording() async -> String? {
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        let result = finalTranscription.isEmpty ? nil : finalTranscription

        resetState()

        return result
    }

    func setLanguage(_ localeCode: String) {
        self.localeCode = localeCode
    }

    private func resetState() {
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest = nil
        speechRecognizer = nil
        finalTranscription = ""
    }

    private func computeRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        let channelDataPointer = channelData[0]

        var sum: Float = 0.0
        for frame in 0 ..< frameLength {
            let sample = channelDataPointer[frame]
            sum += sample * sample
        }

        let mean = sum / Float(frameLength)
        return sqrt(mean)
    }
}

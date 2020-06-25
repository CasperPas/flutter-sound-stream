import Flutter
import UIKit
import AVFoundation

public enum SoundStreamErrors: String {
    case FailedToRecord
    case FailedToPlay
    case FailedToStop
    case FailedToWriteBuffer
    case Unknown
}

public enum SoundStreamStatus: String {
    case Unset
    case Initialized
    case Playing
    case Stopped
}

@available(iOS 9.0, *)
public class SwiftSoundStreamPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel
    private var registrar: FlutterPluginRegistrar
    private var hasPermission: Bool = false
    private var debugLogging: Bool = false
    
    private let mAudioEngine = AVAudioEngine()
    private var isUsingSpeaker: Bool = false
    
    //========= Recorder's vars
    private let mRecordBus = 0
    private var mInputNode: AVAudioInputNode
    private var mRecordSampleRate: Double = 16000 // 16Khz
    private var mRecordBufferSize: AVAudioFrameCount = 8192
    private var mRecordChannel = 0
    private var mRecordSettings: [String:Int]!
    private var mRecordFormat: AVAudioFormat!
    private var mRecordMixer: AVAudioMixerNode!
    private var isRecording: Bool = false
    
    //========= Player's vars
    private let PLAYER_OUTPUT_SAMPLE_RATE: Double = 32000   // 32Khz
    private let mPlayerBus = 0
    private let mPlayerNode = AVAudioPlayerNode()
    private var mPlayerSampleRate: Double = 16000 // 16Khz
    private var mPlayerBufferSize: AVAudioFrameCount = 8192
    private var mPlayerOutputFormat: AVAudioFormat!
    private var mPlayerInputFormat: AVAudioFormat!
    
    /** ======== Basic Plugin initialization ======== **/
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vn.casperpas.sound_stream:methods", binaryMessenger: registrar.messenger())
        let instance = SwiftSoundStreamPlugin( channel, registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init( _ channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar ) {
        self.channel = channel
        self.registrar = registrar
        self.mInputNode = mAudioEngine.inputNode
        self.mRecordMixer = AVAudioMixerNode()
        
        super.init()
        self.attachPlayer()
        self.initEngine()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasPermission":
            hasPermission(result)
        case "usingSpeaker":
            sendResult(result, isUsingSpeaker)
        case "usePhoneSpeaker":
            usePhoneSpeaker(call, result)
        case "initializeRecorder":
            initializeRecorder(call, result)
        case "startRecording":
            startRecording(result)
        case "stopRecording":
            stopRecording(result)
        case "initializePlayer":
            initializePlayer(call, result)
        case "startPlayer":
            startPlayer(result)
        case "stopPlayer":
            stopPlayer(result)
        case "writeChunk":
            writeChunk(call, result)
        default:
            print("Unrecognized method: \(call.method)")
            sendResult(result, FlutterMethodNotImplemented)
        }
    }
    
    private func sendResult(_ result: @escaping FlutterResult, _ arguments: Any?) {
        DispatchQueue.main.async {
            result( arguments )
        }
    }
    
    private func invokeFlutter( _ method: String, _ arguments: Any? ) {
        DispatchQueue.main.async {
            self.channel.invokeMethod( method, arguments: arguments )
        }
    }
    
    /** ======== Plugin methods ======== **/
    
    private func checkAndRequestPermission(completion callback: @escaping ((Bool) -> Void)) {
        if (hasPermission) {
            callback(hasPermission)
            return
        }
        
        var permission: AVAudioSession.RecordPermission
        #if swift(>=4.2)
        permission = AVAudioSession.sharedInstance().recordPermission
        #else
        permission = AVAudioSession.sharedInstance().recordPermission()
        #endif
        switch permission {
        case .granted:
            print("granted")
            hasPermission = true
            callback(hasPermission)
            break
        case .denied:
            print("denied")
            hasPermission = false
            callback(hasPermission)
            break
        case .undetermined:
            print("undetermined")
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                if allowed {
                    self.hasPermission = true
                    print("undetermined true")
                    callback(self.hasPermission)
                } else {
                    self.hasPermission = false
                    print("undetermined false")
                    callback(self.hasPermission)
                }
            }
            break
        default:
            callback(hasPermission)
            break
        }
    }
    
    private func hasPermission( _ result: @escaping FlutterResult) {
        checkAndRequestPermission { value in
            self.sendResult(result, value)
        }
    }
    
    private func initEngine() {
        mAudioEngine.prepare()
        startEngine()
        
        let avAudioSession = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = [AVAudioSession.CategoryOptions.allowBluetooth, AVAudioSession.CategoryOptions.mixWithOthers]
        if #available(iOS 10.0, *) {
            options.insert(AVAudioSession.CategoryOptions.allowBluetoothA2DP)
        }
        try? avAudioSession.setCategory(AVAudioSession.Category.playAndRecord, options: options)
        try? avAudioSession.setMode(AVAudioSession.Mode.default)
        
        setUsePhoneSpeaker(false)
    }
    
    private func startEngine() {
        guard !mAudioEngine.isRunning else {
            return
        }
        
        try? mAudioEngine.start()
    }
    
    private func stopEngine() {
        mAudioEngine.stop()
        mAudioEngine.reset()
    }
    
    private func sendEventMethod(_ name: String, _ data: Any) {
        var eventData: [String: Any] = [:]
        eventData["name"] = name
        eventData["data"] = data
        invokeFlutter("platformEvent", eventData)
    }
    
    private func initializeRecorder(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>
            else {
                sendResult(result, FlutterError( code: SoundStreamErrors.Unknown.rawValue,
                                                 message:"Incorrect parameters",
                                                 details: nil ))
                return
        }
        mRecordSampleRate = argsArr["sampleRate"] as? Double ?? mRecordSampleRate
        debugLogging = argsArr["showLogs"] as? Bool ?? debugLogging
        mRecordFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: mRecordSampleRate, channels: 1, interleaved: true)
        
        checkAndRequestPermission { isGranted in
            if isGranted {
                self.sendRecorderStatus(SoundStreamStatus.Initialized)
                self.sendResult(result, true)
            } else {
                self.sendResult(result, FlutterError( code: SoundStreamErrors.Unknown.rawValue,
                                                      message:"Incorrect parameters",
                                                      details: nil ))
            }
        }
    }
    
    private func startRecorder() {
        stopRecorder()
        let input = mAudioEngine.inputNode
        let inputFormat = input.inputFormat(forBus: mRecordBus)
        let converter = AVAudioConverter(from: inputFormat, to: mRecordFormat!)!
        let ratio: Float = Float(inputFormat.sampleRate)/Float(mRecordFormat.sampleRate)
        
        input.installTap(onBus: mRecordBus, bufferSize: mRecordBufferSize, format: inputFormat) { (buffer, time) -> Void in
            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            self.isRecording = true
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.mRecordFormat!, frameCapacity: UInt32(Float(buffer.frameCapacity) / ratio))!
            
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)
            
            if (self.mRecordFormat?.commonFormat == AVAudioCommonFormat.pcmFormatInt16) {
                let values = self.audioBufferToBytes(convertedBuffer)
                self.sendMicData(values)
            }
        }
    }
    
    
    private func stopRecorder() {
        mAudioEngine.inputNode.removeTap(onBus: mRecordBus)
        isRecording = false
    }
    
    private func startRecording(_ result: @escaping FlutterResult) {
        startEngine()
        startRecorder()
        sendRecorderStatus(SoundStreamStatus.Playing)
        result(true)
    }
    
    private func stopRecording(_ result: @escaping FlutterResult) {
        stopRecorder()
        sendRecorderStatus(SoundStreamStatus.Stopped)
        result(true)
    }
    
    private func sendMicData(_ data: [UInt8]) {
        let channelData = FlutterStandardTypedData(bytes: NSData(bytes: data, length: data.count) as Data)
        sendEventMethod("dataPeriod", channelData)
    }
    
    private func sendRecorderStatus(_ status: SoundStreamStatus) {
        sendEventMethod("recorderStatus", status.rawValue)
    }
    
    private func initializePlayer(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>
            else {
                sendResult(result, FlutterError( code: SoundStreamErrors.Unknown.rawValue,
                                                 message:"Incorrect parameters",
                                                 details: nil ))
                return
        }
        
        mPlayerSampleRate = argsArr["sampleRate"] as? Double ?? mPlayerSampleRate
        debugLogging = argsArr["showLogs"] as? Bool ?? debugLogging
        mPlayerInputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: mPlayerSampleRate, channels: 1, interleaved: true)
        sendPlayerStatus(SoundStreamStatus.Initialized)
    }
    
    private func usePhoneSpeaker(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>
            else {
                sendResult(result, FlutterError( code: SoundStreamErrors.Unknown.rawValue,
                                                 message:"Incorrect parameters",
                                                 details: nil ))
                return
        }
        let useSpeaker = argsArr["value"] as? Bool ?? false
        
        setUsePhoneSpeaker(useSpeaker)
        sendResult(result, true)
    }
    
    private func setUsePhoneSpeaker(_ enabled: Bool) {
        if mPlayerNode.isPlaying {
            mPlayerNode.stop()
            sendPlayerStatus(SoundStreamStatus.Stopped)
        }
        
        if isRecording {
            stopRecorder()
            sendRecorderStatus(SoundStreamStatus.Stopped)
        }
        
        let avAudioSession = AVAudioSession.sharedInstance()
        
        if enabled {
            try? avAudioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            
            for input in avAudioSession.availableInputs!{
                if input.portType == AVAudioSession.Port.builtInMic || input.portType == AVAudioSession.Port.builtInReceiver {
                    if debugLogging {
                        print(input.portName)
                    }
                    try? avAudioSession.setPreferredInput(input)
                    break
                }
            }
        } else {
            try? avAudioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            
            for input in avAudioSession.availableInputs!{
                if input.portType == AVAudioSession.Port.bluetoothA2DP || input.portType == AVAudioSession.Port.bluetoothHFP || input.portType == AVAudioSession.Port.bluetoothLE || input.portType == AVAudioSession.Port.headsetMic {
                    if debugLogging {
                        print(input.portName)
                    }
                    try? avAudioSession.setPreferredInput(input)
                    break
                }
            }
        }
        
        if debugLogging {
            print("INPUTS")
            for input in avAudioSession.availableInputs!{
                print(input.portName)
            }
            
            print("OUTPUTS")
            for output in avAudioSession.currentRoute.outputs{
                print(output.portName)
            }
        }
        
        try? avAudioSession.setActive(true)
        
        isUsingSpeaker = enabled
        startEngine()
    }
    
    private func attachPlayer() {
        mPlayerOutputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: PLAYER_OUTPUT_SAMPLE_RATE, channels: 1, interleaved: true)
        
        mAudioEngine.attach(mPlayerNode)
        mAudioEngine.connect(mPlayerNode, to: mAudioEngine.mainMixerNode, format: mPlayerOutputFormat)
    }
    
    private func startPlayer(_ result: @escaping FlutterResult) {
        startEngine()
        if !mPlayerNode.isPlaying {
            mPlayerNode.play()
        }
        sendPlayerStatus(SoundStreamStatus.Playing)
        result(true)
    }
    
    private func stopPlayer(_ result: @escaping FlutterResult) {
        if mPlayerNode.isPlaying {
            mPlayerNode.stop()
        }
        sendPlayerStatus(SoundStreamStatus.Stopped)
        result(true)
    }
    
    private func sendPlayerStatus(_ status: SoundStreamStatus) {
        sendEventMethod("playerStatus", status.rawValue)
    }
    
    private func writeChunk(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>,
            let data = argsArr["data"] as? FlutterStandardTypedData
            else {
                sendResult(result, FlutterError( code: SoundStreamErrors.FailedToWriteBuffer.rawValue,
                                                 message:"Failed to write Player buffer",
                                                 details: nil ))
                return
        }
        let byteData = [UInt8](data.data)
        pushPlayerChunk(byteData, result)
    }
    
    private func pushPlayerChunk(_ chunk: [UInt8], _ result: @escaping FlutterResult) {
        let buffer = bytesToAudioBuffer(chunk)
        mPlayerNode.scheduleBuffer(convertBufferFormat(
            buffer,
            from: mPlayerInputFormat,
            to: mPlayerOutputFormat
        ));
        result(true)
    }
    
    private func convertBufferFormat(_ buffer: AVAudioPCMBuffer, from: AVAudioFormat, to: AVAudioFormat) -> AVAudioPCMBuffer {
        
        let formatConverter =  AVAudioConverter(from: from, to: to)
        let ratio: Float = Float(from.sampleRate)/Float(to.sampleRate)
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: to, frameCapacity: UInt32(Float(buffer.frameCapacity) / ratio))!
        
        var error: NSError? = nil
        let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        formatConverter?.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
        
        return pcmBuffer
    }
    
    private func audioBufferToBytes(_ audioBuffer: AVAudioPCMBuffer) -> [UInt8] {
        let srcLeft = audioBuffer.int16ChannelData![0]
        let bytesPerFrame = audioBuffer.format.streamDescription.pointee.mBytesPerFrame
        let numBytes = Int(bytesPerFrame * audioBuffer.frameLength)
        
        // initialize bytes by 0
        var audioByteArray = [UInt8](repeating: 0, count: numBytes)
        
        srcLeft.withMemoryRebound(to: UInt8.self, capacity: numBytes) { srcByteData in
            audioByteArray.withUnsafeMutableBufferPointer {
                $0.baseAddress!.initialize(from: srcByteData, count: numBytes)
            }
        }
        
        return audioByteArray
    }
    
    private func bytesToAudioBuffer(_ buf: [UInt8]) -> AVAudioPCMBuffer {
        let frameLength = UInt32(buf.count) / mPlayerInputFormat.streamDescription.pointee.mBytesPerFrame
        
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: mPlayerInputFormat, frameCapacity: frameLength)!
        audioBuffer.frameLength = frameLength
        
        let dstLeft = audioBuffer.int16ChannelData![0]
        
        buf.withUnsafeBufferPointer {
            let src = UnsafeRawPointer($0.baseAddress!).bindMemory(to: Int16.self, capacity: Int(frameLength))
            dstLeft.initialize(from: src, count: Int(frameLength))
        }
        
        return audioBuffer
    }
    
}

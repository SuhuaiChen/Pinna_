//
//  AudioSpectrumPlayer.swift
//  Pinna
///
//  Created by Matt Chen on 2022/3/20.
//

import Foundation
import AVFoundation
import Accelerate

protocol AudioSpectrumPlayerDelegate: AnyObject {
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]])
}

class AudioSpectrumPlayer {
    
    
    weak var delegate: AudioSpectrumPlayerDelegate?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    let volumeEffect = AVAudioUnitEQ()
    
    public var bufferSize: Int? {
        didSet {
            if let bufferSize = self.bufferSize {
                analyzer = RealtimeAnalyzer(fftSize: bufferSize)
                engine.mainMixerNode.removeTap(onBus: 0)
                engine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: nil, block: {[weak self](buffer, when) in
                    guard let strongSelf = self else { return }
                    if !strongSelf.player.isPlaying { return }
                    buffer.frameLength = AVAudioFrameCount(bufferSize)
                    let spectra = strongSelf.analyzer.analyse(with: buffer)
                    self!.volumeEffect.globalGain = 0
                    let amplitudes = spectra[0]
                    let index = self!.analyzer.findMajorFrequency(amplitudes: spectra[0])
                    print(amplitudes[index])
                    
                    
                    if index > 0 && index < 15  {
                        self!.volumeEffect.globalGain = (0.5-UserSetting.shared.low) * 40
                    }
                    else if index > 15 && index < 150 {
                        self!.volumeEffect.globalGain = (0.5-UserSetting.shared.medium) * 40
                    }
                    else if index > 150 {
                        self!.volumeEffect.globalGain = (0.5-UserSetting.shared.high) * 40
                    }
                    else{
                        self!.volumeEffect.globalGain = 0
                    }
                    
                   
                    if strongSelf.delegate != nil {
                        strongSelf.delegate!.player(strongSelf, didGenerateSpectrum: spectra)
                    }
                })
            }
        }
    }
    
    
    public var analyzer: RealtimeAnalyzer!
    
    init(bufferSize: Int = 2048) {
        engine.attach(volumeEffect)
        engine.attach(player)
        engine.connect(player, to: volumeEffect, format: nil)
        engine.connect(volumeEffect, to: engine.mainMixerNode, format: nil)
        
        engine.prepare()
        try! engine.start()
    
        defer {
            self.bufferSize = bufferSize
        }
    }

    func play(withFileName fileName: String) {
        
        guard let audioFileURL = URL(string: fileName),
              let audioFile = try? AVAudioFile(forReading: audioFileURL) else { return }
        player.stop()
        player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        player.stop()
    }
    
    

   
}



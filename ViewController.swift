//
//  ViewController.swift
//  Pinna
//
//  Created by Matt Chen on 2022/3/20.
//

import UIKit
import AVFoundation
import UserNotifications

class ViewController: UIViewController {

    
    var recorder:AVAudioRecorder? //录音器
       // var player:AVAudioPlayer! //播放器
        var player: AudioSpectrumPlayer!
        var recorderSeetingsDic:[String : Any]? //录音器设置参数数组
        var volumeTimer:Timer! //定时器线程，循环监测录音的音量大小
        var aacPath:String? //录音存储路径
       
   
    
    @IBOutlet weak var spectrumview: SpectrumView!
    @IBOutlet weak var volumLab: UILabel!
    @IBOutlet weak var playAudio: UIButton!
    @IBOutlet weak var recordAudio: UIButton!
    @IBOutlet weak var stopRecord: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var StopPlay: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        stopRecord.isEnabled = false
        recordAudio.isEnabled = true
        recordingLabel.text = "tap the start button to record"
        player = AudioSpectrumPlayer()
        player.delegate = self
        //初始化录音器
                let session:AVAudioSession = AVAudioSession.sharedInstance()
                 
                //设置录音类型
                try! session.setCategory(AVAudioSession.Category.playAndRecord)
                //设置支持后台
                try! session.setActive(true)
                //获取Document目录
                let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                 .userDomainMask, true)[0]
                //组合录音文件路径
                aacPath = docDir + "/play.aac"
                //初始化字典并添加设置参数
                recorderSeetingsDic =
                    [
                        AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                        AVNumberOfChannelsKey: 2, //录音的声道数，立体声为双声道
                        AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                        AVEncoderBitRateKey : 320000,
                        AVSampleRateKey : 44100.0 //录音器每秒采集的录音样本数
                ]
            }
    
    
    @IBAction func recordAudio(_ sender: UIButton) {
        print("tap")
        recordingLabel.text = "is recoridng"
        recordAudio.isEnabled = false
        stopRecord.isEnabled = true
        
        recorder = try! AVAudioRecorder(url: URL(string: aacPath!)!,
                                                settings: recorderSeetingsDic!)
        if recorder != nil {
                    //开启仪表计数功能
                    recorder!.isMeteringEnabled = true
                    //准备录音
                    recorder!.prepareToRecord()
                    //开始录音
                    recorder!.record()
                    //启动定时器，定时更新录音音量
                    volumeTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                        selector: #selector(ViewController.levelTimer),
                                        userInfo: nil, repeats: true)
                }
    }
    
    
    @IBAction func stopRecord(_ sender: UIButton) {
        print("stop")
        recordingLabel.text = "tap the start button to record"
        recordAudio.isEnabled = true
        stopRecord.isEnabled = false
        //停止录音
                recorder?.stop()
                //录音器释放
                recorder = nil
                //暂停定时器
                volumeTimer.invalidate()
                volumeTimer = nil
                volumLab.text = "0"
           
        
    }
    
    @IBAction func playAudio(_ sender: UIButton) {
        //播放
        
        let name:String = aacPath!
        player.play(withFileName: name)
        /*
                player = try! AVAudioPlayer(contentsOf: URL(string: aacPath!)!)
                if player == nil {
                    print("播放失败")
                }else{
                    player?.play()
                }
         */
    }
    
    
    @IBAction func StopPlay(_ sender: UIButton) {
        player.stop()
    }
    
    //定时检测录音音量
        @objc func levelTimer(){
            recorder!.updateMeters() // 刷新音量数据
            let averageV:Float = recorder!.averagePower(forChannel: 0) //获取音量的平均值
            let maxV:Float = recorder!.peakPower(forChannel: 0) //获取音量最大值
            let lowPassResult:Double = pow(Double(10), Double(0.05*maxV))
            
            let power:Float = averageV + 110;
            var dB:Int = 0
            
                if power < 0 {
                    dB = 0;
                } else if power < 40 {
                    dB = (Int)(power * 0.875);
                } else if power < 100 {
                    dB = (Int)(power - 30);
                } else if power < 110 {
                    dB = (Int)(power * 2.5 - 165);
                } else {
                    dB = 110;
                }
            
            if dB > 70{
                let content = UNMutableNotificationContent()
                content.title = "Hi"
                content.subtitle = "noise too loud"
                content.body = "It may lead to permanet hearing damage!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "feiji.wav"))
                content.badge = 1
                content.userInfo = ["username": "YungFan", "career": "Teacher"]
                content.categoryIdentifier = "testUserNotifications1"
              //  setupAttachment(content: content)

                // 设置通知触发器
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                // 设置请求标识符
                let requestIdentifier = "com.abc.testUserNotifications2"
                // 设置一个通知请求
                let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
                // 将通知请求添加到发送中心
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
            volumLab.text = "\(dB)"
            
        }
}

extension ViewController: AudioSpectrumPlayerDelegate {
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]]) {
        DispatchQueue.main.async {
            print(spectra)
            self.spectrumview.spectra = spectra
        }
    }
}

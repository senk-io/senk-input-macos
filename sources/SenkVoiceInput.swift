//
//  SenkVoiceInput.swift
//  Senk
//
//  SENK：语音输入。按住右 Option 说话，松开上屏。
//  只用本机离线识别（SFSpeechRecognizer + requiresOnDeviceRecognition），不联网，不接入大模型。
//

import AVFoundation
import Speech

final class SenkVoiceInput {
  enum Failure: Error {
    case denied       // 麦克风或语音识别权限被拒绝
    case unavailable  // 本机没有中文离线识别
    case audio        // 麦克风无法启动
  }

  // 松开按键后等最终结果的最长时间，超时就用已经识别出的文字
  private static let finalResultTimeout: TimeInterval = 3

  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
  private let engine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var finalTimer: Timer?
  // 没装过 tap 时不碰 engine.inputNode：访问它就会打开麦克风
  private var tapInstalled = false
  private var text = ""
  // 每次 start 加一，旧识别任务迟到的回调按它丢掉
  private var generation = 0
  private var wanted = false
  private var onUpdate: ((String) -> Void)?
  private var onFinish: ((String) -> Void)?
  private var onFailure: ((Failure) -> Void)?

  // 回调都在主线程。onFinish 在 finish() 之后调用一次，带最终文字（可能为空）；cancel() 之后不再回调
  func start(onUpdate: @escaping (String) -> Void, onFinish: @escaping (String) -> Void, onFailure: @escaping (Failure) -> Void) {
    cancel()
    generation += 1
    let current = generation
    wanted = true
    text = ""
    self.onUpdate = onUpdate
    self.onFinish = onFinish
    self.onFailure = onFailure
    authorize { [weak self] granted in
      guard let self, self.generation == current, self.wanted else { return }
      guard granted else { return self.fail(.denied) }
      do {
        try self.begin(current)
      } catch let failure as Failure {
        self.fail(failure)
      } catch {
        self.fail(.audio)
      }
    }
  }

  // 松开按键：停止录音，等最终结果
  func finish() {
    guard onFinish != nil else { return }
    wanted = false
    guard task != nil else { return complete() }
    stopAudio()
    request?.endAudio()
    finalTimer = Timer.scheduledTimer(withTimeInterval: Self.finalResultTimeout, repeats: false) { [weak self] _ in
      self?.complete()
    }
  }

  func cancel() {
    wanted = false
    clearCallbacks()
    task?.cancel()
    cleanup()
  }
}

private extension SenkVoiceInput {
  // 第一次使用时系统弹窗询问语音识别和麦克风权限
  func authorize(_ done: @escaping (Bool) -> Void) {
    let reply = { (granted: Bool) in DispatchQueue.main.async { done(granted) } }
    let microphone = {
      switch AVCaptureDevice.authorizationStatus(for: .audio) {
      case .authorized: reply(true)
      case .notDetermined: AVCaptureDevice.requestAccess(for: .audio) { reply($0) }
      default: reply(false)
      }
    }
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized: microphone()
    case .notDetermined: SFSpeechRecognizer.requestAuthorization { $0 == .authorized ? microphone() : reply(false) }
    default: reply(false)
    }
  }

  func begin(_ current: Int) throws {
    guard let recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else { throw Failure.unavailable }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    request.addsPunctuation = true
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else { throw Failure.audio }
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }
    tapInstalled = true
    engine.prepare()
    do {
      try engine.start()
    } catch {
      stopAudio()
      throw Failure.audio
    }
    self.request = request
    task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      DispatchQueue.main.async {
        guard let self, self.generation == current else { return }
        if let result {
          self.text = result.bestTranscription.formattedString
          if result.isFinal {
            return self.complete()
          }
          self.onUpdate?(self.text)
        }
        // 没说话、识别中断等：用已经识别出的文字结束
        if error != nil {
          self.complete()
        }
      }
    }
  }

  func complete() {
    let finish = onFinish
    let result = text
    clearCallbacks()
    cleanup()
    finish?(result)
  }

  func fail(_ failure: Failure) {
    let report = onFailure
    clearCallbacks()
    task?.cancel()
    cleanup()
    report?(failure)
  }

  func clearCallbacks() {
    onUpdate = nil
    onFinish = nil
    onFailure = nil
  }

  func stopAudio() {
    if engine.isRunning {
      engine.stop()
    }
    if tapInstalled {
      engine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
  }

  func cleanup() {
    finalTimer?.invalidate()
    finalTimer = nil
    stopAudio()
    request = nil
    task = nil
  }
}

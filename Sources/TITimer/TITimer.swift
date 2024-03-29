import UIKit

public final class TITimer: ITimer {

    private let mode: TimerRunMode
    private let type: TimerType

    private var sourceTimer: IInvalidatable?
    
    private var enterBackgroundDate: Date?
    private var interval: TimeInterval = 0

    public private(set) var elapsedTime: TimeInterval = 0
    
    public var isRunning: Bool {
        sourceTimer != nil
    }
    
    public var eventHandler: ((TimeInterval) -> Void)?
    
    // MARK: - Initialization
    
    public init(type: TimerType, mode: TimerRunMode) {
        self.mode = mode
        self.type = type
        
        if mode == .activeAndBackground {
            addObserver()
        }
    }
    
    deinit {
        if mode == .activeAndBackground {
            removeObserver()
        }
        
        invalidate()
    }
    
    // MARK: - Public
    
    public func start(with interval: TimeInterval = 1) {
        invalidate()
        
        self.interval = interval
        
        switch type {
        case let .dispatchSourceTimer(queue):
            sourceTimer = startDispatchSourceTimer(interval: interval, queue: queue)
            
        case let .runloopTimer(runloop, mode):
            sourceTimer = startTimer(interval: interval, runloop: runloop, mode: mode)
            
        case let .custom(timer):
            sourceTimer = timer

            timer.start(with: interval)
        }
        
        eventHandler?(elapsedTime)
    }
    
    public func invalidate() {
        elapsedTime = 0
        sourceTimer?.invalidate()
        sourceTimer = nil
    }
    
    // MARK: - Private
    
    @objc private func handleSourceUpdate() {
        guard enterBackgroundDate == nil else {
            return
        }
        
        elapsedTime += interval
        
        eventHandler?(elapsedTime)
    }
}

// MARK: - Factory

extension TITimer {

    public static var `default`: TITimer {
        .init(type: .runloopTimer(runloop: .main, mode: .default), mode: .activeAndBackground)
    }
}

// MARK: - NotificationCenter

private extension TITimer {

    func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willEnterForegroundNotification() {
        guard let unwrappedEnterBackgroundDate = enterBackgroundDate else {
            return
        }
        
        let timeInBackground = -unwrappedEnterBackgroundDate.timeIntervalSinceNow.rounded()
        
        enterBackgroundDate = nil
        elapsedTime += timeInBackground
        eventHandler?(elapsedTime)
    }
    
    @objc func didEnterBackgroundNotification() {
        enterBackgroundDate = Date()
    }
}

// MARK: - DispatchSourceTimer

private extension TITimer {

    func startDispatchSourceTimer(interval: TimeInterval, queue: DispatchQueue) -> IInvalidatable? {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler() { [weak self] in
            self?.handleSourceUpdate()
        }
        
        timer.resume()
        
        return timer as? DispatchSource
    }
}

// MARK: - Timer

private extension TITimer {
    
    func startTimer(interval: TimeInterval, runloop: RunLoop, mode: RunLoop.Mode) -> IInvalidatable {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.handleSourceUpdate()
        }
        
        runloop.add(timer, forMode: mode)
        
        return timer
    }
}

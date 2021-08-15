import UIKit

final class TITimer {
    
    private let mode: TimerRunMode
    private let type: TimerType

    private var sourceTimer: IInvalidatable?
    
    private var enterBackgroundDate: Date?
    private var interval: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0 {
        didSet {
            eventHandler?(elapsedTime)
        }
    }
    
    var eventHandler: ((TimeInterval) -> Void)?
    
    // MARK: - Initialization
    
    init(type: TimerType, mode: TimerRunMode) {
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
    }
    
    // MARK: - Public
    
    func start(with interval: TimeInterval) {
        invalidate()
        
        self.interval = interval
        
        switch type {
        case let .dispatchSourceTimer(queue):
            sourceTimer = startDispatchSourceTimer(interval: interval, queue: queue)
            
        case let .runloopTimer(runloop, mode):
            sourceTimer = startTimer(interval: interval, runloop: runloop, mode: mode)
            
        case let .caDisplayLink(runloop, mode):
            sourceTimer = startCADisplayLink(runloop: runloop, mode: mode)
            
        case let .custom(timer):
            sourceTimer = timer

            timer.start(with: interval)
        }
    }
    
    func invalidate() {
        sourceTimer?.invalidate()
        sourceTimer = nil
    }
    
    // MARK: - Private
    
    @objc private func handleSourceUpdate() {
        guard enterBackgroundDate == nil else {
            return
        }
        
        elapsedTime += interval
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
        
        let timeInBackground = -unwrappedEnterBackgroundDate.timeIntervalSinceNow
        
        enterBackgroundDate = nil
        elapsedTime += timeInBackground
    }
    
    @objc func didEnterBackgroundNotification() {
        enterBackgroundDate = Date()
    }
}

// MARK: - DispatchSourceTimer

private extension TITimer {

    func startDispatchSourceTimer(interval: TimeInterval, queue: DispatchQueue) -> IInvalidatable? {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.schedule(deadline: .distantFuture, repeating: interval)
        timer.setEventHandler(handler: handleSourceUpdate)
        
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

// MARK: - CADisplayLink

private extension TITimer {
    
    func startCADisplayLink(runloop: RunLoop, mode: RunLoop.Mode) -> IInvalidatable {
        let timer = CADisplayLink(target: self, selector: #selector(handleSourceUpdate))
        timer.add(to: runloop, forMode: mode)
        
        return timer
    }
}

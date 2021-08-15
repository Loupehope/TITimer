//
//  TimerType.swift
//  
//
//  Created by Vlad Suhomlinov on 15.08.2021.
//

import UIKit

enum TimerType {
    
    // Запуск таймера на определенной GCD очереди
    case dispatchSourceTimer(queue: DispatchQueue)
    
    // Запуск таймера на определенном режиме Runloop
    case runloopTimer(runloop: RunLoop = .main, mode: RunLoop.Mode)
    
    // Запуск таймера, синхронизированного с частотой кадром девайса, на определенном режиме Runloop
    case caDisplayLink(runloop: RunLoop = .main, mode: RunLoop.Mode)
    
    // Собственная реализация таймера
    case custom(ITimer)
}

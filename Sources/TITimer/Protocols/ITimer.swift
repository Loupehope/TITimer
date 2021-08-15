//
//  ITimer.swift
//  
//
//  Created by Vlad Suhomlinov on 15.08.2021.
//

import Foundation

protocol ITimer: IInvalidatable {
    
    // Запустить работу таймера
    func start(with interval: TimeInterval)
}

//
//  IInvalidatable.swift
//  
//
//  Created by Vlad Suhomlinov on 15.08.2021.
//

import UIKit

protocol IInvalidatable: AnyObject {
    
    // Уничтожить объект
    func invalidate()
}

// MARK: - IInvalidatable

extension Timer: IInvalidatable { }

extension CADisplayLink: IInvalidatable { }

extension DispatchSource: IInvalidatable {
    
    func invalidate() {
        setEventHandler(handler: nil)
        
        if !isCancelled {
            cancel()
        }
    }
}

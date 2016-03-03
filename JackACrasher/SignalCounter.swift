//
//  SignalCounter.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 2/17/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import Foundation


class SignalCounter {
    
    let barrier:Int
    
    var completionBlock:dispatch_block_t! = nil
    
    init(barrier:Int) {
        self.barrier = barrier
    }
    
    private (set) var value:Int32 = 0
    
    func increment() {
        OSAtomicAdd32(1, &value)
        
        if (didReachBarrierOnce()) {
            
            completionBlock()
        }
    }
    
    private func didReachBarrierOnce() -> Bool {
        
        return OSAtomicCompareAndSwap32(Int32(self.barrier), Int32(self.barrier + 1), &value)
    }
    
}
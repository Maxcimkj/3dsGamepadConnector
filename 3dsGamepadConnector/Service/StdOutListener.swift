//
//  StdOutListener.swift
//  3dsGamepadConnectorProject
//
//  Created by Funny Tomatto on 4/16/23.
//

import Foundation

class StdOutListener {
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    
    public func onInput(processor:@escaping (String) -> Void) {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        
        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor,STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        // listening on the readabilityHandler
        inputPipe.fileHandleForReading.readabilityHandler = { [self] handle in
            let data = handle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                DispatchQueue.main.async {
                    processor(string)
                }
                outputPipe.fileHandleForWriting.write(data)
            }
        }
    }
    
}

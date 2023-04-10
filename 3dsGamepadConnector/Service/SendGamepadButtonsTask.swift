//
//  SendGamepadButtonsTask.swift
//  3dsGamepadConnectorProject
//
//  Created by Funny Tomatto on 4/16/23.
//

import Foundation
import GameController

class SendGamepadButtonsTask {
    private var address: String
    private var port: Int32
    private var gamepad: GCExtendedGamepad
    
    private var udpClient:UdpClient? = nil
    private var dispatchWorkItem:DispatchWorkItem? = nil
    
    private let gamepadButtonsMapper = GamepadButtonsMapper()
    
    init(
        address newAddress: String,
        port newPort: Int32,
        gamepad: GCExtendedGamepad
    ) {
        self.address = newAddress
        self.port = newPort
        self.gamepad = gamepad
    }
    
    
    public func start() -> DispatchWorkItem? {
        print("Start sending gamepad buttons by UDP")
        print("Gamepad: \(gamepad.debugDescription)")
        
        self.udpClient = UdpClient(address: self.address, port: self.port)
        
        self.dispatchWorkItem = DispatchWorkItem { [self] in
            let isCancelled = self.dispatchWorkItem?.isCancelled ?? false
            while(!isCancelled) {
                let gamepadSnapshot = self.gamepad.capture()
                let frame = self.gamepadButtonsMapper.mapToDataFrame(gamepadSnapshot: gamepadSnapshot)
                self.udpClient?.send(frame)
                
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        return self.dispatchWorkItem
    }
    
    public func stop() {
        self.dispatchWorkItem?.cancel()
    }
}

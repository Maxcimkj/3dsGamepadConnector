//
//  ButtonsMapper.swift
//  3dsGamepadConnectorProject
//
//  Created by Funny Tomatto on 4/16/23.
//

import Foundation
import Network
import GameController

class GamepadButtonsMapper {
    
    let CPAD_BOUND: UInt32 = 0x5d0
    let CPP_BOUND: UInt32 =  0x7f
    
    public func mapToDataFrame(gamepadSnapshot: GCExtendedGamepad) -> Data {
        let hidPad:UInt32 = setHidPadState(
            hidPad: 0xfff,
            gamepadSnapshot: gamepadSnapshot
        )
        var hidPadLE = hidPad.littleEndian
        
        let touchScreenState:UInt32 = 0x2000000
        var touchScreenStateLE = touchScreenState.littleEndian
        
        let circlePadState:UInt32 = setCirclePad(circlePadState: 0x7ff7ff, gamepadSnapshot: gamepadSnapshot)
        var circlePadStateLE = circlePadState.littleEndian
        
        let cppState:UInt32 = setCppState(cpp: 0x80800081, gamepadSnapshot: gamepadSnapshot)
        var cppStateLE = cppState.littleEndian
        
        let interfaceButtons:UInt32 = setInterfaceButtons(interfaceButtons: 0, gamepadShapshot: gamepadSnapshot)
        var interfaceButtonsLE = interfaceButtons.littleEndian
        
        var data = Data()
        data.append(Data(bytes: &hidPadLE, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &touchScreenStateLE, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &circlePadStateLE, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &cppStateLE, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &interfaceButtonsLE, count: MemoryLayout<UInt32>.size))
        return data
    }
    
    
    func setHidPadState(hidPad:UInt32, gamepadSnapshot: GCExtendedGamepad) -> UInt32 {
        var hidPadResult = hidPad
        if (gamepadSnapshot.dpad.up.isPressed) {
            hidPadResult &= ~(1 << 6)
        }
        if (gamepadSnapshot.dpad.left.isPressed) {
            hidPadResult &= ~(1 << 5)
        }
        if (gamepadSnapshot.dpad.right.isPressed) {
            hidPadResult &= ~(1 << 4)
        }
        if (gamepadSnapshot.dpad.down.isPressed) {
            hidPadResult &= ~(1 << 7)
        }
        if (gamepadSnapshot.buttonX.isPressed) {
            hidPadResult &= ~(1 << 10)
        }
        if (gamepadSnapshot.buttonY.isPressed) {
            hidPadResult &= ~(1 << 11)
        }
        if (gamepadSnapshot.buttonA.isPressed) {
            hidPadResult &= ~(1 << 0)
        }
        if (gamepadSnapshot.buttonB.isPressed) {
            hidPadResult &= ~(1 << 1)
        }
        if (gamepadSnapshot.leftTrigger.isPressed) {
            hidPadResult &= ~(1 << 9)
        }
        if (gamepadSnapshot.rightTrigger.isPressed) {
            hidPadResult &= ~(1 << 8)
        }
        if (gamepadSnapshot.buttonMenu.isPressed) {
            hidPadResult &= ~(1 << 3)
        }
        
        let isbuttonOptionsPressed = gamepadSnapshot.buttonOptions?.isPressed
        if (isbuttonOptionsPressed != nil && isbuttonOptionsPressed!) {
            hidPadResult &= ~(1 << 2)
        }
        
        return hidPadResult
    }
    
    func setCirclePad(circlePadState:UInt32, gamepadSnapshot: GCExtendedGamepad) -> UInt32 {
        var circlePadStateResult = circlePadState
        
        let lx:Float = gamepadSnapshot.leftThumbstick.xAxis.value
        let ly:Float = gamepadSnapshot.leftThumbstick.yAxis.value
        
        if (lx != 0.0 || ly != 0.0) {
            var x = UInt32(lx * Float(CPAD_BOUND) + 0x800)
            var y = UInt32(ly * Float(CPAD_BOUND) + 0x800)
            x = x >= 0xfff ? (lx < 0.0 ? 0x000 : 0xfff) : x
            y = y >= 0xfff ? (ly < 0.0 ? 0x000 : 0xfff) : y
            
            circlePadStateResult = (y << 12) | x
        }
        
        return circlePadStateResult
    }
    
    func setInterfaceButtons(interfaceButtons:UInt32, gamepadShapshot: GCExtendedGamepad) -> UInt32 {
        var interfaceButtonsResult = interfaceButtons
        
        let isbuttonHomePressed = gamepadShapshot.buttonHome?.isPressed
        if (isbuttonHomePressed != nil && isbuttonHomePressed!) {
            interfaceButtonsResult |= 1
        }
        
        return interfaceButtonsResult
    }
    
    func setCppState(cpp:UInt32, gamepadSnapshot: GCExtendedGamepad) -> UInt32 {
        var cppResult = cpp
        
        var irButton:UInt32 = 0;
        if (gamepadSnapshot.rightShoulder.isPressed) {
            irButton |= 1 << (12 - 11)
        }
        if (gamepadSnapshot.leftShoulder.isPressed) {
            irButton |= 1 << (13 - 11)
        }
        
        let rx:Float = gamepadSnapshot.rightThumbstick.xAxis.value
        let ry:Float = gamepadSnapshot.rightThumbstick.yAxis.value
        let x_1:Float = Float(0.5.squareRoot()) * (rx + ry) * Float(CPP_BOUND)
        var x = UInt32(x_1) + 0x80
        let y_1:Float = Float(0.5.squareRoot()) * (ry - rx) * Float(CPP_BOUND)
        var y = UInt32(y_1) + 0x80
        x = x >= 0xff ? (rx < 0.0 ? 0x00 : 0xff) : x
        y = y >= 0xff ? (ry < 0.0 ? 0x00 : 0xff) : y
        
        cppResult = (y << 24) | (x << 16) | (irButton << 8) | 0x81;
        return cppResult
    }
}

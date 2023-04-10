//
//  GamepadView.swift
//  3dsGamepadConnectorProject
//
//  Created by Funny Tomatto on 4/11/23.
//

import Foundation
import SwiftUI
import GameController
//
//  ContentView.swift
//  3dsGamepadConnectorProject
//
//  Created by Funny Tomatto on 4/2/23.
//

struct GamepadView: View {
    let LOG_WINDOW_ROW_SIZE = 2000
    
    let ipAddressRegex = try! NSRegularExpression(pattern: "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])")
    
    let queue = DispatchQueue(label: "send_gamepad_buttons_queue")
    let stdOutListener = StdOutListener()
    
    @AppStorage("consoleIP") private var ip:String = ""
    @State private var log:String = ""
    @State private var task:SendGamepadButtonsTask? = nil
    @State var gamepad: GCExtendedGamepad? = nil
    
    
    var body: some View {
        Spacer()
        VStack {
            TextField(
                "172.20.10.13:4950",
                text: $ip
            )
            
        }.padding()
        Spacer()
        
        VStack {
            Button {
                startSendButtonsAsync()
            } label: {
                Label("Start/Restart", systemImage: "gamecontroller")
            }
        }.padding()
        Spacer()
        
        VStack {
            ScrollView() {
                Text(log)
                    .lineLimit(nil)
                    .frame(
                        maxHeight: .infinity,
                        alignment: .topLeading)
            }
        }.padding()
        
        Spacer()
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.GCControllerDidConnect), perform: { _ in
                print("Connect gamepad \(GCController.controllers()[0].debugDescription)")
                
                if (GCController.controllers()[0].extendedGamepad == nil) {
                    print("Extended gamepads supported only")
                    return
                }
                self.gamepad = GCController.controllers()[0].extendedGamepad
            })
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.GCControllerDidDisconnect), perform: { _ in
                print("Disconnect gamepad")
            })
            .onAppear() {
                stdOutListener.onInput(processor: putStdOutInputIntoLog)
            }
    }
    
    
    func putStdOutInputIntoLog(input: String) {
        // cut old log for keeping logs size
        if(self.log.count > LOG_WINDOW_ROW_SIZE) {
            self.log = String(self.log.dropFirst(max(0, self.log.count - LOG_WINDOW_ROW_SIZE)))
        }
        
        self.log += "[\(Date().description)] \r\n \(input)"
    }
    
    func startSendButtonsAsync() {
        // stop last task
        if (self.task != nil) {
            self.task?.stop()
            self.log = ""
        }
        
        
        if (self.ip.isEmpty) {
            print("IP is empty")
            return
        }
        if (isNotValidIp(ip: self.ip)) {
            print("IP is not valid: \(self.ip)")
            return
        }
        if (gamepad == nil) {
            print("Gamepad is not connected")
            return
        }
        self.task = SendGamepadButtonsTask(
            address: String(self.ip.split(separator: ":")[0]),
            port: Int32(self.ip.split(separator: ":")[1])!,
            gamepad: gamepad!
        )
        queue.async(execute: self.task!.start()!)
    }
    
    func isNotValidIp(ip: String) -> Bool {
        let ipSize = NSRange(location: 0, length: self.ip.utf16.count)
        return ipAddressRegex.firstMatch(in: self.ip, options: [], range: ipSize) == nil
    }
}

struct GamepadView_Previews: PreviewProvider {
    static var previews: some View {
        GamepadView()
    }
}

import Network
import Foundation

class UdpClient {
    var connection: NWConnection
    var address: NWEndpoint.Host
    var port: NWEndpoint.Port
    
    var resultHandler = NWConnection.SendCompletion.contentProcessed { NWError in
        guard NWError == nil else {
            print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            return
        }
    }
    
    init?(address newAddress: String, port newPort: Int32) {
        guard let codedAddress = IPv4Address(newAddress),
              let codedPort = NWEndpoint.Port(rawValue: NWEndpoint.Port.RawValue(newPort)) else {
            print("Failed to create connection address")
            return nil
        }
        address = .ipv4(codedAddress)
        port = codedPort
        
        print("Create connection: address=\(address), port=\(port)")
        connection = NWConnection(host: address, port: port, using: .udp)
        connection.stateUpdateHandler = { newState in
            switch (newState) {
            case .ready:
                print("Connection state: Ready")
                return
            case .setup:
                print("Connection state: Setup")
            case .cancelled:
                print("Connection state: Cancelled")
            case .preparing:
                print("Connection state: Preparing")
            default:
                print("ERROR! Connection state not defined!\n")
            }
        }
        connection.start(queue: .global())
    }
    
    deinit {
        connection.cancel()
    }
    
    func send(_ data: Data) {
        self.connection.send(content: data, completion: self.resultHandler)
    }
}

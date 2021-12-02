//
//  ContentView.swift
//  StreamingScribble
//
//  Created by Terry Chen on 2021/12/1.
//

import SwiftUI
import CoreData


extension SteamingViewModel: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        switch (eventCode, aStream) {
        
        case (.openCompleted, _):
            print("Stream delegate: \(aStream) open completed")
        
        case (.hasBytesAvailable, let inputStream as InputStream):
            print("Stream delegate: \(aStream) has bytes available")
           
            readData(in: inputStream) { result in
                switch result {
                case let .success(data):
                    DispatchQueue.main.async { [self] in
                        self.receivedData = data
                    }
                case let .failure(err): print(err.localizedDescription)
                }
            }
        
        case (.hasSpaceAvailable, let outputStream as OutputStream):
            print("Stream delegate: \(aStream) has space available")
            writeData(in: outputStream, content: receivedData)
        
        case (.errorOccurred, _):
            print("Stream delegate: \(aStream) error occurred")
            
        case (.endEncountered, _):
            print("Stream delegate: \(aStream) Encountered end")
            aStream.close()
        
        default:
            print("Stream delegate: \(aStream) Unknown stream event")
        }
    }
    
    func readData(in inputStream: InputStream,
                  bufferLength: Int = 1024,
                  onCompletion: (Result<Data, Error>) -> Void) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        defer { buffer.deallocate() }
        
        var result = Data()
        
        while inputStream.hasBytesAvailable {
            let numberOfBytes = inputStream.read(buffer, maxLength: bufferLength)
            
            if numberOfBytes < 0, let err = inputStream.streamError {
                print("read Bytes Error: ", err.localizedDescription)
                onCompletion(.failure(err))
                return
            }
            guard numberOfBytes > 0 else { break }
            result.append(buffer, count: numberOfBytes)
        }
        
        onCompletion(.success(result))
       
    }
    
    func writeData(in outputStream: OutputStream, content: Data) {
        content.withUnsafeBytes { buffer in
            let numberOfBytes = outputStream.write(buffer.bindMemory(to: UInt8.self).baseAddress!,
                                                   maxLength: content.count)
            if numberOfBytes == content.count {
                outputStream.close()
            }
        }
    }
}


class SteamingViewModel: NSObject, ObservableObject {
    
    @Published var receivedData = Data()
    
    func start() {
        DispatchQueue.global().async { [self] in
            readFile()
        }
    }
    
    func readFile(_ fileName: String? = "Alamofire",
              ofType: String? = "md",
              schedule runloop: RunLoop = .current,
              runLoopMode: RunLoop.Mode = .default) {
        
        DispatchQueue(label: "read.queue").sync {
            
            let filePath = Bundle.main.path(forResource: fileName, ofType: ofType)!
            let inputStream = InputStream(fileAtPath: filePath)!
            inputStream.delegate = self
            inputStream.schedule(in: runloop, forMode: runLoopMode)
            inputStream.open()
            
            let outputPath = Bundle.main.bundlePath + "\(fileName!)output"
            print("xxx ", outputPath)
            let outputStream = OutputStream(toFileAtPath: outputPath, append: true)!
            outputStream.delegate = self
            outputStream.schedule(in: runloop, forMode: runLoopMode)
            outputStream.open()
            
            print("start a runloop on read.queue")
            runloop.run()
            
            print("stop a runloop on read.queue")
        }
    }
}


struct ContentView: View {
    
    @StateObject var viewModel =  SteamingViewModel()
    var body: some View {
        Text(String(data: viewModel.receivedData, encoding: .utf8) ?? "")
            .onAppear(perform: viewModel.start)
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

//
//  StreamingScribbleApp.swift
//  StreamingScribble
//
//  Created by Terry Chen on 2021/12/1.
//

import SwiftUI

@main
struct StreamingScribbleApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

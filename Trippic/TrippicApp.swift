//
//  TrippicApp.swift
//  Trippic
//
//  Created by Alessio Garzia Marotta Brusco on 03/05/22.
//

import SwiftUI

@main
struct TrippicApp: App {
    @StateObject var dataController = DataController()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        dataController.save()
                    }
                }
                .task {
                    await PhotoLibrary.checkAuthorization()
                }
        }
    }
}

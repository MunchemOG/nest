//
//  ContentView.swift
//  NestApp
//
//  Created by Mithun Dhanes on 11/10/26.
//

import SwiftUI

struct ContentView: View {
    let home: HomeModel

    var body: some View {
        AppFrame(home: home)
    }
}

#Preview {
    ContentView(home: HomeModel())
}

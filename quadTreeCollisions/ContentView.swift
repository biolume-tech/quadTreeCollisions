
import SwiftUI

struct ContentView: View {
    
    //    @State private var hideStatusBar = true        // this is how we set the status bar state ( IOS ONLY )
    
    
    @State private var renderer: Renderer?
    var body: some View {
        VStack {
            MetalView()
        }
        
        
        //       .statusBar(hidden: hideStatusBar)       // hide status bar , ( IOS ONLY )
        //        .persistentSystemOverlays(.hidden)     // hide other overlays    ( IOS ONLY )
    }
    
}


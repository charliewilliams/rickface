//
//  ContentView.swift
//  Rickface
//
//  Created by Charlie Williams on 02/10/2022.
//

import SwiftUI

struct MainView: View {
    
    @State var face: Face
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Image(uiImage: face.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Gradient(colors: [.clear, .clear, .clear, .clear, .black]))
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                
                Text("Rick feels")
                    .font(.callout)
                    .foregroundColor(.white)
                
                Text(face.emotion)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
            }
        }
        .onShake {
            face = Face.random()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(face: Face(index: 0)!)
    }
}

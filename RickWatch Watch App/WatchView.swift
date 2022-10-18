//
//  ContentView.swift
//  RickWatch Watch App
//
//  Created by Charlie Williams on 13/10/2022.
//

import SwiftUI

struct WatchView: View {
    @State var face: Face
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Image(uiImage: face.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)

            Rectangle()
                .fill(Gradient(colors: [.clear, .clear, .black]))
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {

                Text("Rick feels")
                    .font(.callout)
                    .foregroundColor(.white)

                Text(face.emotion)
                    .font(.title)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.25)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: -10, leading: 0, bottom: 0, trailing: 0))
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
        }
        .onTapGesture {
            face = Face.random()
        }
    }
}

struct WatchView_Previews: PreviewProvider {
    static var previews: some View {
        WatchView(face: Face.random())
    }
}

//
//  ContentView.swift
//  supervisedTrainingTest
//
//  Created by David Duarte on 06/10/2020.
//

import SwiftUI
import UIKit


struct ContentView: View {
    
    @State private var isShowPhotoLibrary = false
    @State private var isShowCamera = false
    @State private var image = UIImage()
    @State private var result = "First you've to select an image"
     
    var body: some View {
        ZStack(alignment: .bottom) {
                Image(uiImage: self.image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
            Text(result)
                .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .top)
            HStack {
                    Button(action: {
                        self.isShowPhotoLibrary = true
                    }) {
                        ButtonView(icon: "photo", title: "Photo library")
                        .sheet(isPresented: $isShowCamera) {
                            ImagePicker(result: self.$result, selectedImage: self.$image, sourceType: .camera)
                        }
                    }
                    Button(action: {
                        self.isShowCamera = true
                    }) {
                        ButtonView(icon: "camera", title: "Camera")
                        .sheet(isPresented: $isShowPhotoLibrary) {
                            ImagePicker(result: self.$result, selectedImage: self.$image, sourceType: .photoLibrary)
                        }
                    }
                }
            }
        }
}

struct ButtonView: View {
    var iconImage: String
    var buttonTitle: String
    
    init(icon: String, title: String) {
        iconImage = icon
        buttonTitle = title
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconImage)
                .font(.system(size: 20))

            Text(buttonTitle)
                .font(.headline)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

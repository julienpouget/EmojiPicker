//
//  ContentView.swift
//  EmojiPickerDemo
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI
import EmojiPicker

struct ContentView: View {
    @State private var showPicker = false
    @State private var showPopover = false
    @State private var showInline = false
    @State private var selected = "🤙"

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text(selected)
                    .font(.system(size: 120))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Button {
                        showPicker = true
                    } label: {
                        Label("Pick an emoji (sheet)", systemImage: "face.smiling")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .emojiPicker(isPresented: $showPicker, selection: $selected)

                    Button {
                        showPopover = true
                    } label: {
                        Label("Pick an emoji (macOS popover)", systemImage: "bubble.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .emojiPickerPopover(isPresented: $showPopover, selection: $selected)

                    Button {
                        showInline.toggle()
                    } label: {
                        Label("Toggle inline picker", systemImage: "square.grid.2x2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal)

                if showInline {
                    EmojiPickerView(
                        configuration: EmojiPickerConfiguration(dismissesOnSelection: false)
                    ) { emoji in
                        selected = emoji
                    }
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2))
                    )
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("EmojiPicker")
        }
        .navigationViewStyle(.stack)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

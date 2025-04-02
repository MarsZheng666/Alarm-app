//
//  SoundSelectionView.swift
//  Alarm
//
//  Created by 郑席明 on 08/04/2025.
//

// SoundSelectionView.swift

import SwiftUI
import UniformTypeIdentifiers

struct SoundSelectionView: View {
    @Binding var selectedSound: String
    @Binding var selectedExt: String

    private let sounds: [(name: String, ext: String)] = [
        ("Anticipate", "caf"),
        ("Radar",      "caf"),
        ("Beacon",     "caf"),
        ("Chimes",     "caf"),
        ("Circuit",    "caf"),
        ("Reflection", "caf"),
        ("Xylophone",  "caf"),
        ("Classic",    "m4r"),
        ("Modern",     "m4r")
    ]

    @State private var showingPicker = false

    var body: some View {
        List {
            ForEach(sounds, id: \.name) { sound in
                Button {
                    selectedSound = sound.name
                    selectedExt   = sound.ext
                } label: {
                    HStack {
                        Text(sound.name)
                        Spacer()
                        if sound.name == selectedSound && sound.ext == selectedExt {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            // 从文件中选择
            Button {
                showingPicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Choose from Files")
                    Spacer()
                }
            }
        }
        .navigationTitle("Select Sound")
        .sheet(isPresented: $showingPicker) {
            DocumentPicker { url in
                // 拷贝到 app 沙盒或直接使用原 URL
                let name = url.deletingPathExtension().lastPathComponent
                let ext  = url.pathExtension
                selectedSound = name
                selectedExt   = ext
                showingPicker = false
            }
        }
    }
}

/// SwiftUI 包装的文档选择器，用于挑选音频文件
struct DocumentPicker: UIViewControllerRepresentable {
    /// 支持的文件类型，比如 mp3、wav、m4a
    let supportedTypes: [UTType] = [.mp3, .wav]
    /// 回调：返回所选文件的本地 URL
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: supportedTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
struct SoundSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SoundSelectionView(selectedSound: .constant("Anticipate"),
                selectedExt:
                .constant("caf"))
            
        }
    }
}

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
    @Binding var selectedURL:   URL?

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
                    selectedURL   = nil          // 清空 URL
                } label: {
                    HStack {
                        Text(sound.name)
                        Spacer()
                        if selectedURL == nil,
                           sound.name == selectedSound,
                           sound.ext  == selectedExt {
                            Image(systemName:"checkmark")
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
                    if selectedURL != nil {
                        Image(systemName:"checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .navigationTitle("Select Sound")
        .sheet(isPresented: $showingPicker) {
            DocumentPicker { url in
                // ② 复制到沙盒 /Library/Sounds（让通知也能找到）
                if let copied = copyToSoundsFolder(url) {
                    selectedURL   = copied
                    selectedSound = copied.deletingPathExtension().lastPathComponent
                    selectedExt   = copied.pathExtension
                }
                showingPicker = false
            }
        }
    }
    
    /// 把用户挑选的文件复制到 Library/Sounds，返回新 URL
    private func copyToSoundsFolder(_ src: URL) -> URL? {
        let dstFolder = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dstFolder,
                                                 withIntermediateDirectories: true)
        let dstURL = dstFolder.appendingPathComponent(src.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: src, to: dstURL)
            return dstURL
        } catch {
            print("❌ 复制失败：\(error)")
            return nil
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
                selectedExt: .constant("caf"),
                selectedURL:   .constant(nil))
            
        }
    }
}




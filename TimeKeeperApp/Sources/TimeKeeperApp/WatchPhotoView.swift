import SwiftUI

#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

struct WatchPhotoView: View {
    let photoId: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let image = loadImage() {
                #if canImport(AppKit)
                Image(nsImage: image).resizable().aspectRatio(contentMode: contentMode)
                #else
                Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                #endif
            } else {
                ZStack {
                    TKTheme.subtleFill
                    Image(systemName: "wristwatch")
                        .font(.largeTitle.weight(.ultraLight))
                        .foregroundStyle(TKTheme.brass.opacity(0.45))
                }
                .accessibilityLabel("No photo")
            }
        }
    }

    private func loadImage() -> PlatformImage? {
        if let data = PhotoStore.loadData(photoId: photoId) {
            #if canImport(AppKit)
            return NSImage(data: data)
            #else
            return UIImage(data: data)
            #endif
        }
        if let photoId {
            let stem = PhotoStore.stem(from: photoId)
            #if canImport(AppKit)
            return NSImage(named: stem)
            #else
            return UIImage(named: stem)
            #endif
        }
        return nil
    }
}

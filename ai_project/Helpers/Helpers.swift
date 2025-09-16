import UIKit
import AVFoundation



func generateThumbnail(for url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true

    let duration = asset.duration.seconds
    let captureSecond = duration.isFinite && duration > 0 ? min(1.0, duration / 2.0) : 0.5
    let time = CMTime(seconds: captureSecond, preferredTimescale: 600)

    do {
        let cg = try generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cg)
    } catch {
        print("Thumbnail generation failed:", error)
        return nil
    }
}


func formatDateMMDDYYYY(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    return formatter.string(from: date)
}

// Renders the Blabber app icon at every size iconutil needs, then packs
// it into Blabber.icns. Run with: swift Scripts/make-icon.swift
//
// Mark: a speech bubble whose tail doubles as a waveform downstroke —
// one glyph that reads as both "talking" and "audio", legible at 16px.
// Palette: near-black ground (#0E0E11), coral accent (#FF5C47).
//
// Draws straight into a CGBitmapContext sized in exact pixels — NSImage
// + lockFocus silently multiplies by the screen's backing scale factor
// (2x on this Retina display), which otherwise doubles every output
// size regardless of what's requested.
import AppKit
import CoreGraphics

let sizes: [Int] = [16, 32, 128, 256, 512]
let outDir = "Resources/Blabber.iconset"

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func makeContext(pixelSize: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    return CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func render(pixelSize: Int) -> CGImage {
    let ctx = makeContext(pixelSize: pixelSize)
    let s = CGFloat(pixelSize)

    let ground = CGColor(red: 0x0E/255.0, green: 0x0E/255.0, blue: 0x11/255.0, alpha: 1.0)
    let coral = CGColor(red: 1.0, green: 0x5C/255.0, blue: 0x47/255.0, alpha: 1.0)

    let fullRect = CGRect(x: 0, y: 0, width: s, height: s)
    ctx.addPath(roundedRectPath(fullRect, radius: s * 0.22))
    ctx.setFillColor(ground)
    ctx.fillPath()

    // Speech bubble body.
    let margin = s * 0.20
    let bubbleRect = CGRect(
        x: margin, y: margin + s * 0.10,
        width: s - margin * 2,
        height: s - margin * 2 - s * 0.10
    )
    ctx.addPath(roundedRectPath(bubbleRect, radius: bubbleRect.width * 0.28))
    ctx.setFillColor(coral)
    ctx.fillPath()

    // Tail, doubling as a waveform downstroke, bottom-left of the bubble.
    let tailBaseX = bubbleRect.minX + bubbleRect.width * 0.22
    let tailTipX = bubbleRect.minX + bubbleRect.width * 0.08
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: tailBaseX, y: bubbleRect.minY + bubbleRect.height * 0.12))
    tail.addLine(to: CGPoint(x: tailTipX, y: bubbleRect.minY - bubbleRect.height * 0.14))
    tail.addLine(to: CGPoint(x: tailBaseX + bubbleRect.width * 0.14, y: bubbleRect.minY + bubbleRect.height * 0.02))
    tail.closeSubpath()
    ctx.addPath(tail)
    ctx.setFillColor(coral)
    ctx.fillPath()

    // Waveform bars inside the bubble, cut out in the ground color.
    let barCount = 5
    let barWidth = bubbleRect.width * 0.07
    let gap = bubbleRect.width * 0.045
    let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * gap
    let startX = bubbleRect.midX - totalWidth / 2
    let heights: [CGFloat] = [0.32, 0.56, 0.78, 0.50, 0.30]
    for i in 0..<barCount {
        let h = bubbleRect.height * heights[i]
        let barRect = CGRect(
            x: startX + CGFloat(i) * (barWidth + gap),
            y: bubbleRect.midY - h / 2,
            width: barWidth,
            height: h
        )
        ctx.addPath(roundedRectPath(barRect, radius: barWidth / 2))
        ctx.setFillColor(ground)
        ctx.fillPath()
    }

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else {
        print("Failed to create destination for \(path)")
        return
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        print("Failed to write \(path)")
    }
}

import ImageIO

for size in sizes {
    writePNG(render(pixelSize: size), to: "\(outDir)/icon_\(size)x\(size).png")
    writePNG(render(pixelSize: size * 2), to: "\(outDir)/icon_\(size)x\(size)@2x.png")
}

print("Wrote iconset to \(outDir)")

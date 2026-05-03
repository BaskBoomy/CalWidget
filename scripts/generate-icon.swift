#!/usr/bin/env swift
import AppKit
import Foundation

let size: CGFloat = 1024

guard let imageRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
) else {
    fputs("Failed to allocate bitmap\n", stderr); exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let ctx = NSGraphicsContext(bitmapImageRep: imageRep) else {
    fputs("Failed to create context\n", stderr); exit(1)
}
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

let bgColors = [
    CGColor(red: 0.32, green: 0.46, blue: 0.96, alpha: 1) as CFTypeRef,
    CGColor(red: 0.36, green: 0.27, blue: 0.85, alpha: 1) as CFTypeRef
]
guard let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: bgColors as CFArray,
    locations: [0, 1]
) else { exit(1) }
cg.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

let pad: CGFloat = 180
let bodyRect = CGRect(x: pad, y: pad, width: size - 2 * pad, height: size - 2 * pad)
let bodyPath = CGPath(
    roundedRect: bodyRect,
    cornerWidth: 80,
    cornerHeight: 80,
    transform: nil
)

cg.saveGState()
cg.addPath(bodyPath)
cg.setShadow(
    offset: CGSize(width: 0, height: -16),
    blur: 28,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
)
cg.setFillColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
cg.fillPath()
cg.restoreGState()

cg.saveGState()
cg.addPath(bodyPath)
cg.clip()
let stripeHeight: CGFloat = 130
let stripeY = bodyRect.maxY - stripeHeight
let stripeRect = CGRect(x: bodyRect.minX, y: stripeY, width: bodyRect.width, height: stripeHeight)
cg.setFillColor(red: 0.96, green: 0.30, blue: 0.30, alpha: 1)
cg.fill(stripeRect)
cg.restoreGState()

let dotRadius: CGFloat = 22
let dotY = bodyRect.maxY + 8
for dotX in [bodyRect.minX + 130, bodyRect.maxX - 130] {
    let dotRect = CGRect(
        x: dotX - dotRadius,
        y: dotY - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    )
    cg.setFillColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    cg.fillEllipse(in: dotRect)
}

let textColor = NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.22, alpha: 1)
let font = NSFont.systemFont(ofSize: 380, weight: .heavy)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: textColor
]
let attrStr = NSAttributedString(string: "31", attributes: attrs)
let textSize = attrStr.size()

let whiteTopY = stripeY
let whiteBottomY = bodyRect.minY
let whiteHeight = whiteTopY - whiteBottomY

let textX = (size - textSize.width) / 2
let textY = whiteBottomY + (whiteHeight - textSize.height) / 2 - 20

attrStr.draw(at: CGPoint(x: textX, y: textY))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = imageRep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr); exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let url = URL(fileURLWithPath: outputPath)
try pngData.write(to: url)
print("Wrote \(pngData.count) bytes to \(url.path)")

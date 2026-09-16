import AppKit

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.1
    let squircleRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = size * 0.22

    // Background squircle path
    let path = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    context.saveGState()
    context.addPath(path)
    context.clip()

    // Gradient background
    let colors = [
        NSColor(calibratedRed: 0.18, green: 0.14, blue: 0.38, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.38, green: 0.20, blue: 0.65, alpha: 1.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size, y: size), options: [])
    }
    context.restoreGState()

    // Subtle border
    context.saveGState()
    context.addPath(path)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
    context.setLineWidth(size * 0.015)
    context.strokePath()
    context.restoreGState()

    // Draw Emoji in the center
    let emoji = "✨"
    let emojiFont = NSFont.systemFont(ofSize: size * 0.46)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: emojiFont
    ]
    let str = NSAttributedString(string: emoji, attributes: attributes)
    let strSize = str.size()
    let strRect = CGRect(
        x: (size - strSize.width) / 2.0,
        y: (size - strSize.height) / 2.0 - size * 0.02,
        width: strSize.width,
        height: strSize.height
    )
    str.draw(in: strRect)

    image.unlockFocus()
    return image
}

let iconsetDir = "/Users/patrickfu/dev/emoji-ai/dist/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (base, scale) in sizes {
    let px = base * scale
    let img = renderIcon(size: CGFloat(px))
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let filename = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let fileUrl = URL(fileURLWithPath: "\(iconsetDir)/\(filename)")
        try? png.write(to: fileUrl)
    }
}
print("Iconset generated.")

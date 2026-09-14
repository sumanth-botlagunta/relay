import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: size * 0.06, y: size * 0.06, width: size * 0.88, height: size * 0.88)
let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.2, yRadius: size * 0.2)
NSGradient(colors: [
    NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.96, alpha: 1),
    NSColor(calibratedRed: 0.56, green: 0.27, blue: 0.92, alpha: 1),
])!.draw(in: path, angle: -60)

let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .semibold)
    .applying(.init(paletteColors: [.white]))
if let symbol = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let s = symbol.size
    let scale = (size * 0.5) / max(s.width, s.height)
    let w = s.width * scale
    let h = s.height * scale
    symbol.draw(in: NSRect(x: (size - w) / 2, y: (size - h) / 2, width: w, height: h))
}
image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "Resources/icon-1024.png"))
print("wrote Resources/icon-1024.png")

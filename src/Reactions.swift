import Cocoa

// Tepkiler: yüksekten bırakılınca kızıp miyavlama, okşanınca kalp çıkarma

enum Meow {
    // Dosya gerektirmeden sentezlenen miyav sesi (frekans süpürmesi + armonikler)
    static func wav(angry: Bool) -> Data {
        let sr = 22050.0
        let dur = angry ? 0.75 : 0.5
        let n = Int(sr * dur)
        var pcm = [Int16](repeating: 0, count: n)
        var phase = 0.0
        for i in 0..<n {
            let t = Double(i) / Double(n)
            let f: Double
            if angry { f = 620 + 520 * sin(.pi * t) - 160 * t + 18 * sin(t * 90) }   // yüksek, titrek "MİYAV!"
            else     { f = 480 + 260 * sin(.pi * t) }
            phase += 2 * .pi * f / sr
            var s = sin(phase) + 0.5 * sin(2 * phase) + 0.3 * sin(3 * phase) + 0.15 * sin(5 * phase)
            if angry { s += 0.25 * Double.random(in: -1...1) * sin(.pi * t) }          // hırıltı
            let env = min(1, t / 0.08) * pow(1 - t, 0.7)
            pcm[i] = Int16(max(-1, min(1, s * env * 0.35)) * 32000)
        }
        var d = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + n * 2)); d.append("WAVEfmt ".data(using: .ascii)!)
        u32(16); u16(1); u16(1); u32(UInt32(sr)); u32(UInt32(sr) * 2); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(UInt32(n * 2))
        pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
        return d
    }
    static var sounds: [Bool: NSSound] = [:]
    static func play(angry: Bool) {
        if sounds[angry] == nil { sounds[angry] = NSSound(data: wav(angry: angry)) }
        guard let s = sounds[angry] else { return }
        s.stop(); s.play()
    }
}

extension AppDelegate {
    // Kedinin üstünde kısa süre yüzen emoji / yazı
    func floatLabel(_ text: String, size: CGFloat, dx: CGFloat, dy: CGFloat, rise: CGFloat, life: TimeInterval) {
        if text.count > 2 { floatBubble(text, size: size, rise: rise, life: life); return }   // yazılar balon içinde, emojiler tek başına
        let f = win.frame
        let w = NSWindow(contentRect: NSRect(x: f.midX - size + dx, y: f.maxY - 8 + dy, width: size * 4, height: size * 1.6),
                         styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.hasShadow = false
        w.ignoresMouseEvents = true; w.level = win.level; w.collectionBehavior = win.collectionBehavior
        w.isReleasedWhenClosed = false
        let l = NSTextField(labelWithString: text)
        l.font = NSFont.systemFont(ofSize: size, weight: .heavy)
        l.alignment = .center; l.textColor = .systemRed
        l.frame = NSRect(x: 0, y: 0, width: size * 4, height: size * 1.6)
        w.contentView = l
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = life
            w.animator().setFrameOrigin(NSPoint(x: w.frame.origin.x + CGFloat.random(in: -10...10), y: w.frame.origin.y + rise))
            w.animator().alphaValue = 0
        }, completionHandler: { w.orderOut(nil) })
    }

    // Yumuşak konuşma balonu: beyaz yuvarlak kutu, pembe ince çerçeve, yuvarlak yazı tipi
    func floatBubble(_ text: String, size: CGFloat, rise: CGFloat, life: TimeInterval) {
        var font = NSFont.systemFont(ofSize: max(13, size * 0.7), weight: .semibold)
        if let d = font.fontDescriptor.withDesign(.rounded), let r = NSFont(descriptor: d, size: font.pointSize) { font = r }
        let l = NSTextField(labelWithString: text)
        l.font = font; l.textColor = NSColor(srgbRed: 0.45, green: 0.28, blue: 0.36, alpha: 1)
        l.sizeToFit()
        let padX: CGFloat = 14, padY: CGFloat = 7
        let bw = l.frame.width + padX * 2, bh = l.frame.height + padY * 2
        let f = win.frame
        let w = NSWindow(contentRect: NSRect(x: f.midX - bw / 2, y: f.maxY - 4, width: bw, height: bh),
                         styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.hasShadow = false
        w.ignoresMouseEvents = true; w.level = win.level; w.collectionBehavior = win.collectionBehavior
        w.isReleasedWhenClosed = false
        let box = NSView(frame: NSRect(x: 0, y: 0, width: bw, height: bh))
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(white: 1, alpha: 0.96).cgColor
        box.layer?.cornerRadius = bh / 2
        box.layer?.borderWidth = 1.5
        box.layer?.borderColor = NSColor(srgbRed: 1, green: 0.72, blue: 0.8, alpha: 1).cgColor
        l.frame.origin = NSPoint(x: padX, y: padY)
        box.addSubview(l)
        w.contentView = box
        w.alphaValue = 0
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup({ ctx in               // yumuşakça belirir
            ctx.duration = 0.25
            w.animator().alphaValue = 1
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + life * 0.6) {   // sonra süzülüp kaybolur
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = life * 0.4
                w.animator().setFrameOrigin(NSPoint(x: w.frame.origin.x, y: w.frame.origin.y + min(rise, 20)))
                w.animator().alphaValue = 0
            }, completionHandler: { w.orderOut(nil) })
        }
    }

    func petted() {
        let now = Date().timeIntervalSince1970
        guard !dragging, !clinging, now - lastPet > 0.8 else { return }
        lastPet = now
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { [weak self] in
                self?.floatLabel(["❤️", "💖", "💕"].randomElement()!, size: CGFloat.random(in: 18...26),
                                 dx: CGFloat.random(in: -26...26), dy: CGFloat.random(in: 0...10),
                                 rise: CGFloat.random(in: 50...80), life: 1.4)
            }
        }
        Meow.play(angry: false)
        // sevinç zıplaması
        let a = CABasicAnimation(keyPath: "transform.translation.y")
        a.fromValue = 0; a.toValue = 5; a.duration = 0.12; a.autoreverses = true; a.repeatCount = 2
        iv.wantsLayer = true
        iv.layer?.add(a, forKey: "happy")
    }

    func angryMeow() {
        Meow.play(angry: true)
        floatLabel("Miyaaav! 😾", size: 20, dx: 0, dy: 4, rise: 30, life: 1.8)
        // öfkeyle sallanma
        let a = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        a.values = [0, 0.18, -0.18, 0.14, -0.14, 0.08, -0.08, 0]
        a.duration = 0.6
        iv.wantsLayer = true
        iv.layer?.add(a, forKey: "angry")
    }
}

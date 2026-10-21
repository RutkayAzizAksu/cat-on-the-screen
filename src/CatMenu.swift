import Cocoa

// Kediye sağ tıklayınca açılan menü: miyavla, hışla, bağır, uyandır, uyu, yala, zıpla

extension Meow {
    // Hışırtı: yüksek frekanslı gürültü patlaması
    static func hissData() -> Data {
        let sr = 22050.0, n = Int(sr * 0.8)
        var pcm = [Int16](repeating: 0, count: n)
        var prev = 0.0
        for i in 0..<n {
            let t = Double(i) / Double(n)
            let white = Double.random(in: -1...1)
            let hp = white - prev * 0.85; prev = white          // basit yüksek geçiren filtre
            let env = min(1, t / 0.1) * pow(1 - t, 0.9)
            pcm[i] = Int16(max(-1, min(1, hp * env * 0.6)) * 32000)
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
    static var hiss: NSSound? = NSSound(data: hissData())

    // Mırıltı: ~25 Hz titreşimle kalınlaşan alçak ton (yalarken / uyurken)
    static func purrData() -> Data {
        let sr = 22050.0, n = Int(sr * 1.2)
        var pcm = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / sr, u = Double(i) / Double(n)
            let am = 0.55 + 0.45 * sin(2 * .pi * 25 * t)
            let s = (sin(2 * .pi * 110 * t) + 0.5 * sin(2 * .pi * 220 * t) + 0.2 * Double.random(in: -1...1)) * am
            let env = min(1, u / 0.15) * min(1, (1 - u) / 0.3)
            pcm[i] = Int16(max(-1, min(1, s * env * 0.3)) * 32000)
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
    static var purr: NSSound? = NSSound(data: purrData())
}

extension AppDelegate {
    func showCatMenu(_ e: NSEvent) {
        let m = NSMenu()
        let items: [(String, Selector)] = [
            ("🐱  Miyavla", #selector(catMeow)),
            ("😾  Hışla", #selector(catHiss)),
            ("📢  Bağır", #selector(catShout)),
            ("☀️  Uyandır (uyuma)", #selector(catWake)),
            ("😴  Uyu", #selector(catSleep)),
            ("👅  Yalan (dil at)", #selector(catLick)),
            ("🦘  Zıpla", #selector(catJump)),
        ]
        for (t, s) in items {
            let it = NSMenuItem(title: t, action: s, keyEquivalent: "")
            it.target = self
            m.addItem(it)
        }
        NSMenu.popUpContextMenu(m, with: e, for: iv)
    }

    @objc func catMeow() {
        Meow.play(angry: false)
        floatLabel("Miyaav~ 🐾", size: 18, dx: 0, dy: 4, rise: 36, life: 1.4)
    }
    @objc func catHiss() {
        Meow.hiss?.stop(); Meow.hiss?.play()
        floatLabel("Hışşş 😾", size: 18, dx: 0, dy: 4, rise: 36, life: 1.4)
        shake()
    }
    @objc func catShout() { angryMeow() }
    @objc func catWake() {
        guard !dragging, !clinging else { return }
        if st == .sleep { enter(.idle); iv.image = frame("alert", 0) }
        floatLabel("☀️", size: 20, dx: 0, dy: 4, rise: 36, life: 1.2)
    }
    @objc func catSleep() {
        guard !dragging, !clinging, st == .idle || st == .walk || st == .zoomies else { return }
        toFood = false; eating = false; eatingRef = nil
        enter(.sleep)
        Meow.purr?.stop(); Meow.purr?.play()
        floatLabel("💤", size: 20, dx: 0, dy: 4, rise: 36, life: 1.8)
    }
    @objc func catLick() {
        guard !dragging, !clinging, st == .idle || st == .sleep || st == .walk else { return }
        eating = false; eatingRef = nil
        enter(.idle); stDur = 60            // idle'ın ortasında yıkanma animasyonu oynar
        Meow.purr?.stop(); Meow.purr?.play()
        floatLabel("👅", size: 20, dx: 0, dy: 4, rise: 30, life: 1.6)
    }
    @objc func catJump() {
        guard !dragging, !clinging, st != .falling, !leaping else { return }
        fallY = win.frame.origin.y + SIZE / 2
        fallVx = 0; fallVy = -34; flyHang = false
        Meow.play(angry: false)
        st = .falling
    }

    func shake() {
        let a = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        a.values = [0, 0.15, -0.15, 0.1, -0.1, 0]
        a.duration = 0.5
        iv.wantsLayer = true
        iv.layer?.add(a, forKey: "shake")
    }
}

import Cocoa

// Pencere üstü: kedi bırakıldığında/düştüğünde açık uygulama pencerelerinin üst kenarına konabilir.
// Pencere kapanır, taşınır ya da kedi kenardan yürürse tekrar düşer.

struct PerchWin {
    let id: Int
    let minX: CGFloat, maxX: CGFloat
    let top: CGFloat          // AppKit koordinatında pencerenin üst kenarı
}

extension AppDelegate {
    // Ekrandaki normal uygulama pencereleri (menü çubuğu, Dock, Neko'nun kendisi hariç)
    func perchWindows() -> [PerchWin] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
              let primary = NSScreen.screens.first else { return [] }
        let pid = Int(ProcessInfo.processInfo.processIdentifier)
        var out: [PerchWin] = []
        for w in list {
            guard (w[kCGWindowLayer as String] as? Int) == 0,
                  (w[kCGWindowOwnerPID as String] as? Int) != pid,
                  (w[kCGWindowAlpha as String] as? Double ?? 1) > 0.05,
                  let bd = w[kCGWindowBounds as String] as? NSDictionary,
                  let r = CGRect(dictionaryRepresentation: bd as CFDictionary),
                  r.width >= 120, r.height >= 80,
                  let id = w[kCGWindowNumber as String] as? Int else { continue }
            let top = primary.frame.height - r.minY
            // ekranı tamamen kaplayan (tam ekran) pencereler zemin sayılmaz
            if NSScreen.screens.contains(where: { r.width >= $0.frame.width - 2 && r.height >= $0.frame.height - 2 }) { continue }
            out.append(PerchWin(id: id, minX: r.minX, maxX: r.maxX, top: top))
        }
        return out
    }

    func floorFor(_ w: PerchWin) -> CGFloat { w.top + SIZE / 2 - FOOT }

    // Düşen kedinin ineceği zemin: ekran tabanı ya da altındaki en yüksek pencere üstü
    func groundBelow() -> (CGFloat, PerchWin?) {
        var best = curScreen().frame.minY + SIZE / 2 - FOOT
        var found: PerchWin? = nil
        let scr = curScreen().frame
        if fallVy >= 0 {                                       // sadece aşağı inerken pencereye konar
            for w in perchWindows() where x >= w.minX + 10 && x <= w.maxX - 10 && w.top < scr.maxY - SIZE {
                let g = floorFor(w)
                if g <= fallY + 2 && g > best { best = g; found = w }
            }
        }
        return (best, found)
    }

    // Gezinme: boştayken ara sıra başka bir pencerenin üstüne (ya da yere) zıplar
    func maybeRoamJump() {
        guard st == .idle, stTicks > 20, !eating, !toFood, !toPlay, !goingAway, !leaving, !hunting,
              !dragging, !clinging, !leaping, !bedtimeNow, energy > 0.25,
              Int.random(in: 0..<110) == 0 else { return }
        let scr = curScreen().frame
        let y0 = y
        struct Target { let tx: CGFloat; let yt: CGFloat }
        var cands: [Target] = []
        for w in perchWindows() where w.id != perch?.id && w.top < scr.maxY - SIZE && w.top > scr.minY + SIZE {
            let lo = max(w.minX + SIZE / 2 + 10, scr.minX + SIZE / 2), hi = min(w.maxX - SIZE / 2 - 10, scr.maxX - SIZE / 2)
            guard hi > lo, floorFor(w) - y0 < 330 else { continue }
            cands.append(Target(tx: CGFloat.random(in: lo...hi), yt: floorFor(w)))
        }
        if perch != nil {                                    // pencere üstündeyse bazen yere de iner
            cands.append(Target(tx: CGFloat.random(in: (scr.minX + SIZE)...(scr.maxX - SIZE)),
                                yt: scr.minY + SIZE / 2 - FOOT))
        }
        guard let t = cands.randomElement() else { return }
        let dx = t.tx - x
        let h = max(0, t.yt - y0)
        let v0 = -(12 * (h + 60)).squareRoot()                 // tepe noktası hedefin ~60px üstünde
        let dy = y0 - t.yt
        let b = 3 + v0
        let T = (-b + (b * b + 12 * dy).squareRoot()) / 6
        guard T > 1 else { return }
        var s: CGFloat = 0, f: CGFloat = 1                     // havadaki yatay sürtünmeyi hesaba kat
        for _ in 0..<Int(T.rounded()) { s += f; f *= 0.985 }
        let vx = dx / max(s, 1)
        guard abs(vx) < 45 else { return }
        perch = nil
        fallY = y0; fallVx = vx; fallVy = v0; flyHang = false; flySpin = 0
        angryOnLanding = false
        st = .falling
    }

    // Pencere üstündeyken her tick: pencere gitti/taşındı/kenardan çıkıldı → düş
    func validatePerch() {
        guard let p = perch else { return }
        var ok = st != .digging && st != .away && !leaping
        if ok {
            if let w = perchWindows().first(where: { $0.id == p.id }),
               abs(w.top - p.top) < 2, x >= w.minX + 4, x <= w.maxX - 4 {
                perch = w                                      // genişlik değişmiş olabilir
            } else { ok = false }
        }
        if !ok {
            fallY = y; fallVx = 0; fallVy = 0; flyHang = false
            perch = nil
            st = .falling
        }
    }
}

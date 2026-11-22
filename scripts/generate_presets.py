"""Genera los presets Swift de ambos widgets desde config.json (sin App Groups).

Ejecutar: python3 scripts/generate_presets.py
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
config = json.loads((root / 'config.json').read_text(encoding='utf-8'))

def swiftstr(v: str) -> str:
    if not isinstance(v, str) or len(v) > 40:
        raise ValueError('Se esperaba una cadena de hasta 40 caracteres')
    return json.dumps(v, ensure_ascii=False)

def color(v: str) -> str:
    if not isinstance(v, str) or len(v) != 7 or not v.startswith('#') or any(c not in '0123456789abcdefABCDEF' for c in v[1:]):
        raise ValueError('Color inválido; usa #RRGGBB')
    return swiftstr(v)

def make_theme(key: str) -> str:
    t = config[key]
    return f'''    static let {key} = GolfDesign(
        theme: {swiftstr(key)},
        title: {swiftstr(t["title"])},
        subtitle: {swiftstr(t["subtitle"])},
        footer: {swiftstr(t["footer"])},
        accent: {color(t["accent"])},
        background: {color(t["background"])},
        showClock: {str(bool(t["showClock"])).lower()}
    )'''

src = '''// Archivo generado automáticamente desde config.json. No editar a mano.
import Foundation
import SwiftUI

struct GolfDesign {
    var theme: String
    var title: String
    var subtitle: String
    var footer: String
    var accent: String
    var background: String
    var showClock: Bool

''' + make_theme('sport') + '\n\n' + make_theme('custom') + '''

    static func preset(theme: String) -> GolfDesign {
        theme == "custom" ? custom : sport
    }
}

extension Color {
    init(golfHex: String) {
        let value = golfHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let hex = UInt64(value, radix: 16) else {
            self = .red
            return
        }
        self = Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

struct GolfCardView: View {
    let design: GolfDesign
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 5) {
                Text(design.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                Spacer(minLength: 2)
                Image(systemName: design.theme == "sport" ? "gauge.high" : "star.fill")
                    .foregroundStyle(Color(golfHex: design.accent))
            }
            Spacer(minLength: 4)
            Text(design.subtitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if design.showClock {
                Text(date, style: .time)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(golfHex: design.accent))
                .frame(height: 3)
            Text(design.footer.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white.opacity(0.78))
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(golfHex: design.background))
    }
}
'''
(root / 'ios' / 'Shared' / 'GolfSettings.swift').write_text(src, encoding='utf-8')
print('Presets Swift generados desde config.json')

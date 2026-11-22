"""Vista previa local de Golf Widgets. Solo biblioteca estándar de Python.

Windows: py -3 preview.py
Visita http://127.0.0.1:8765 en el navegador.
"""
import json
import re
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIG_FILE = ROOT / "config.json"
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")


def normalize(data):
    if not isinstance(data, dict) or data.get("theme") not in ("sport", "custom"):
        raise ValueError("Tema no válido")
    clean = {"theme": data["theme"]}
    for theme in ("sport", "custom"):
        src = data.get(theme)
        if not isinstance(src, dict):
            raise ValueError(f"Faltan ajustes de {theme}")
        entry = {}
        for field in ("title", "subtitle", "footer"):
            value = src.get(field, "")
            if not isinstance(value, str) or len(value) > 40:
                raise ValueError(f"Texto no válido: {field}")
            entry[field] = value
        for field in ("accent", "background"):
            value = src.get(field, "")
            if not isinstance(value, str) or not HEX_COLOR.fullmatch(value):
                raise ValueError(f"Color no válido: {field}")
            entry[field] = value
        if not isinstance(src.get("showClock"), bool):
            raise ValueError("showClock debe ser verdadero o falso")
        entry["showClock"] = src["showClock"]
        clean[theme] = entry
    return clean


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        if self.path.split("?")[0] == "/api/config":
            self.reply(200, CONFIG_FILE.read_bytes())
        else:
            super().do_GET()

    def do_POST(self):
        if self.path != "/api/config":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 1 or length > 65536:
                raise ValueError("Tamaño incorrecto")
            data = normalize(json.loads(self.rfile.read(length)))
            content = (json.dumps(data, indent=2, ensure_ascii=False) + "\n").encode()
            CONFIG_FILE.write_bytes(content)
        except (ValueError, UnicodeError, json.JSONDecodeError) as exc:
            self.reply(400, json.dumps({"error": str(exc)}).encode())
            return
        self.reply(200, b'{"ok":true}')

    def reply(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
    print("Golf Widgets: http://127.0.0.1:8765")
    print("Ctrl+C para parar")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

import SwiftUI

struct ContentView: View {
    @StateObject private var model = PerformanceModel()
    @State private var connection = 0
    @State private var showDashboard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PerformanceDashboard(readings: model.readings,
                                         connected: model.isConnected,
                                         demo: model.demo,
                                         status: model.status)
                        .frame(height: 345)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    Button {
                        showDashboard = true
                    } label: {
                        Label("Ver cuadro deportivo a pantalla completa", systemImage: "arrow.up.left.and.arrow.down.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    connectionPanel
                    livePanel
                    diagnostics
                }
                .padding()
            }
            .background(Color(red: 0.045, green: 0.055, blue: 0.08))
            .foregroundStyle(.white)
            .navigationTitle("Golf Performance")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .fullScreenCover(isPresented: $showDashboard) {
                FullScreenPerformanceDashboard(model: model)
            }
        }
    }

    private var connectionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONEXIÓN ELM327").font(.headline)
            Picker("Conexión", selection: $connection) {
                Text("Bluetooth LE").tag(0)
                Text("Wi-Fi").tag(1)
            }.pickerStyle(.segmented)
            if connection == 0 {
                Button("Buscar adaptadores Bluetooth") { model.scanBLE() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                ForEach(model.devices) { device in
                    Button {
                        model.connectBLE(device.id)
                    } label: {
                        HStack {
                            Text(device.name).lineLimit(1)
                            Spacer()
                            Text("\(device.rssi) dBm").font(.caption).foregroundStyle(.gray)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                Text("Si no aparece, cierra Car Scanner, activa Bluetooth y prueba otra vez.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                TextField("IP del ELM", text: $model.host).textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                TextField("Puerto TCP", text: $model.port).keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Conectar por Wi-Fi") { model.connectWiFi() }
                    .buttonStyle(.borderedProminent).tint(.red)
                Text("Conecta antes el iPhone a la red Wi-Fi del ELM. IP/puerto: mira los ajustes de Car Scanner.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Modo demo") { model.startDemo() }.buttonStyle(.bordered)
                Spacer()
                Button("Desconectar") { model.disconnect() }.buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var livePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CARPLAY · LIVE ACTIVITY").font(.headline)
            Text("Envía valores reales resumidos hacia CarPlay. iOS controla cuándo los pinta; la app del iPhone sí actualiza cada respuesta OBD.")
                .font(.caption).foregroundStyle(.secondary)
            Stepper("Intentar actualizar cada \(model.liveIntervalSeconds) s", value: $model.liveIntervalSeconds, in: 2...15)
                .font(.caption)
            Text("Intervalo solicitado, no garantizado: CarPlay decide cuándo redibujar la Live Activity.")
                .font(.caption2).foregroundStyle(.gray)
            HStack {
                Button("Iniciar en CarPlay") { model.startLive() }
                    .buttonStyle(.borderedProminent).tint(.red)
                    .disabled(!model.isConnected || model.demo || model.liveEnabled)
                Spacer()
                Button("Detener") { model.stopLive() }
                    .buttonStyle(.bordered)
                    .disabled(!model.liveEnabled)
            }
            Text(model.liveStatus).font(.caption).foregroundStyle(.gray)
        }
        .padding(16)
        .background(.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var diagnostics: some View {
        DisclosureGroup("Diagnóstico y conexión") {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(model.messages.enumerated()), id: \.offset) { _, message in
                    Text(message).font(.system(size: 11, design: .monospaced))
                }
                Text("RPM 010C · km/h 010D · °C 0105 · carga 0104 · MAP 010B")
                    .font(.caption2).foregroundStyle(.gray)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

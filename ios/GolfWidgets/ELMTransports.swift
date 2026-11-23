import Foundation
import CoreBluetooth
import Network

struct BLEDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
}

// Todas las callbacks se entregan en la cola principal.
protocol ELMTransport: AnyObject {
    var onData: ((String) -> Void)? { get set }
    var onReady: (() -> Void)? { get set }
    var onStatus: ((String) -> Void)? { get set }
    func send(_ command: String)
    func stop()
}

final class BLEELMTransport: NSObject, ELMTransport, CBCentralManagerDelegate, CBPeripheralDelegate {
    var onData: ((String) -> Void)?
    var onReady: (() -> Void)?
    var onStatus: ((String) -> Void)?
    var onDevices: (([BLEDevice]) -> Void)?
    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var strengths: [UUID: Int] = [:]
    private var peripheral: CBPeripheral?
    private var tx: CBCharacteristic?
    private var rx: CBCharacteristic?
    private var allCharacteristics: [CBCharacteristic] = []
    private var pendingServices = 0
    private var started = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main,
                                   options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    func scan() {
        started = true
        if central.state == .poweredOn {
            onStatus?("Buscando dispositivos BLE…")
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            onStatus?("Activa Bluetooth en el iPhone")
        }
    }

    func connect(id: UUID) {
        guard let item = peripherals[id] else { onStatus?("Dispositivo no encontrado"); return }
        central.stopScan()
        peripheral = item
        tx = nil; rx = nil; allCharacteristics = []
        onStatus?("Conectando con \(item.name ?? "ELM")…")
        central.connect(item, options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && started { scan() }
        else if central.state != .poweredOn { onStatus?("Bluetooth no disponible: \(central.state.rawValue)") }
    }

    func centralManager(_ central: CBCentralManager, didDiscover discovered: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals[discovered.identifier] = discovered
        strengths[discovered.identifier] = RSSI.intValue
        let devices = peripherals.values.map { p in
            BLEDevice(id: p.identifier,
                      name: p.name ?? (String(p.identifier.uuidString.prefix(8)) + " (sin nombre)"),
                      rssi: strengths[p.identifier] ?? -100)
        }.sorted { $0.rssi > $1.rssi }
        onDevices?(devices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        onStatus?("BLE conectado; detectando canales…")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onStatus?("Error BLE: \(error?.localizedDescription ?? "sin detalle")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        tx = nil; rx = nil
        onStatus?("ELM desconectado: \(error?.localizedDescription ?? "")")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            onStatus?("No se pudieron descubrir servicios BLE")
            return
        }
        pendingServices = services.count
        if pendingServices == 0 { onStatus?("Sin servicios BLE") }
        for service in services { peripheral.discoverCharacteristics(nil, for: service) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let list = service.characteristics { allCharacteristics.append(contentsOf: list) }
        pendingServices -= 1
        if pendingServices == 0 { selectChannels(peripheral) }
    }

    private func selectChannels(_ peripheral: CBPeripheral) {
        // Prioridad a perfiles BLE ELM más comunes. UUID 18F0: RX 2AF0, TX 2AF1.
        // Nordic UART: RX notifica 6E400003; TX escribe 6E400002.
        // FFE0/FFE1: un mismo canal suele permitir escribir y notificar.
        func characteristic(_ uuid: String) -> CBCharacteristic? {
            allCharacteristics.first { $0.uuid.uuidString.uppercased() == uuid.uppercased() }
        }
        let bleNUSNotify = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
        let bleNUSWrite = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        if let receive = characteristic("2AF0"), let write = characteristic("2AF1") {
            rx = receive; tx = write
        } else if let receive = characteristic(bleNUSNotify), let write = characteristic(bleNUSWrite) {
            rx = receive; tx = write
        } else if let c = characteristic("FFE1"),
                  c.properties.contains(.notify),
                  (c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse)) {
            rx = c; tx = c
        } else {
            let notifies = allCharacteristics.filter { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
            let writes = allCharacteristics.filter { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }
            // Último recurso para clones con UUIDs no estándar.
            if let notify = notifies.first, let write = writes.first { rx = notify; tx = write }
        }
        guard let receive = rx, tx != nil else {
            onStatus?("No encuentro RX/TX de este ELM. Necesito sus UUID Bluetooth.")
            return
        }
        onStatus?("Canales detectados: RX \(receive.uuid), TX \(tx!.uuid)")
        peripheral.setNotifyValue(true, for: receive)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil && characteristic.isNotifying { onStatus?("ELM BLE preparado"); onReady?() }
        else { onStatus?("No se pudieron activar notificaciones BLE") }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let bytes = characteristic.value, error == nil else { return }
        onData?(String(decoding: bytes, as: UTF8.self))
    }

    func send(_ command: String) {
        guard let p = peripheral, let c = tx else { return }
        let data = Data((command + "\r").utf8)
        let kind: CBCharacteristicWriteType = c.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        let maximum = p.maximumWriteValueLength(for: kind)
        for start in stride(from: 0, to: data.count, by: max(1, maximum)) {
            p.writeValue(data.subdata(in: start..<min(start + max(1, maximum), data.count)), for: c, type: kind)
        }
    }

    func stop() {
        started = false
        central.stopScan()
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
    }
}

final class WiFiELMTransport: ELMTransport {
    var onData: ((String) -> Void)?
    var onReady: (() -> Void)?
    var onStatus: ((String) -> Void)?
    private var connection: NWConnection?

    func connect(host: String, port: UInt16) {
        guard let tcpPort = NWEndpoint.Port(rawValue: port) else {
            onStatus?("Puerto TCP inválido"); return
        }
        let c = NWConnection(host: NWEndpoint.Host(host), port: tcpPort, using: .tcp)
        connection = c
        c.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.onStatus?("ELM Wi-Fi conectado")
                self.onReady?()
                self.receive()
            case .failed(let error): self.onStatus?("Wi-Fi: \(error.localizedDescription)")
            case .cancelled: self.onStatus?("Wi-Fi desconectado")
            default: break
            }
        }
        c.start(queue: .main)
    }

    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, completed, error in
            guard let self else { return }
            if let data, !data.isEmpty { self.onData?(String(decoding: data, as: UTF8.self)) }
            if let error { self.onStatus?("Lectura TCP: \(error.localizedDescription)") }
            if !completed && error == nil { self.receive() }
        }
    }

    func send(_ command: String) {
        connection?.send(content: Data((command + "\r").utf8), completion: .contentProcessed { [weak self] error in
            if let error { self?.onStatus?("Envío TCP: \(error.localizedDescription)") }
        })
    }
    func stop() { connection?.cancel(); connection = nil }
}

import SwiftUI

struct ContentView: View {
    @State private var theme = "sport"

    var body: some View {
        NavigationStack {
            Form {
                Section("Diseño incluido") {
                    Picker("Modo", selection: $theme) {
                        Text("Deportivo").tag("sport")
                        Text("Personalizado").tag("custom")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Vista previa") {
                    HStack {
                        Spacer()
                        GolfCardView(design: GolfDesign.preset(theme: theme), date: .now)
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 19))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                Section("Versión gratuita") {
                    Text("Los dos widgets se incluyen en esta app. Para cambiar textos y colores, modifica config.json en Windows, vuelve a subir los cambios a GitHub y genera una nueva IPA.")
                    Text("Esta versión no usa App Groups: los ajustes se incorporan al compilar la app y no se modifican directamente desde el iPhone.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Golf Widgets")
        }
    }
}

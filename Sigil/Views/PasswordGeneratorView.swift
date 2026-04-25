import SwiftUI

struct PasswordGeneratorView: View {
    @Binding var isPresented: Bool
    let onUse: (String) -> Void

    @State private var options = PasswordGeneratorOptions()
    @State private var generated: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Generate Password")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(SigilIconButtonStyle())
                .help("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    generatedDisplay

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("LENGTH")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .tracking(0.8)
                            Spacer()
                            Text("\(options.length)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        Slider(value: Binding(
                            get: { Double(options.length) },
                            set: { options.length = Int($0); regenerate() }
                        ), in: 8...64, step: 1)
                        .tint(.indigo)
                    }

                    VStack(spacing: 8) {
                        toggleRow("Uppercase (A-Z)", isOn: $options.includeUppercase)
                        toggleRow("Lowercase (a-z)", isOn: $options.includeLowercase)
                        toggleRow("Digits (0-9)", isOn: $options.includeDigits)
                        toggleRow("Symbols (!@#…)", isOn: $options.includeSymbols)
                        toggleRow("Avoid ambiguous (0/O, 1/l)", isOn: $options.avoidAmbiguous)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Divider().opacity(0.3)

            HStack(spacing: 10) {
                Button(action: regenerate) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Regenerate")
                    }
                }
                .buttonStyle(SigilCommandButtonStyle(variant: .secondary))

                Spacer()

                Button("Cancel") { isPresented = false }
                    .buttonStyle(SigilCommandButtonStyle(variant: .secondary))

                Button("Use") {
                    onUse(generated)
                    isPresented = false
                }
                .buttonStyle(SigilCommandButtonStyle(variant: .primary))
                .disabled(generated.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 340, height: 440)
        .onAppear { regenerate() }
    }

    private var generatedDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PASSWORD")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .tracking(0.8)
                Spacer()
                Button(action: copyGenerated) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(SigilIconButtonStyle())
                .help("Copy")
            }

            Text(generated.isEmpty ? " " : generated)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
                .textSelection(.enabled)

            StrengthMeterView(strength: StrengthEvaluator.evaluate(generated))
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { isOn.wrappedValue = $0; regenerate() }
        )) {
            Text(label)
                .font(.system(size: 12))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(.indigo)
    }

    private func regenerate() {
        generated = PasswordGenerator.generate(options)
    }

    private func copyGenerated() {
        guard !generated.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generated, forType: .string)
    }
}

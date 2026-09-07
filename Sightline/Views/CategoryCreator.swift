import SwiftUI

struct CategoryCreatorSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var icon = "🛒"
    @State private var colorHex = "0E7C66"
    @State private var budget: Double = 200
    @State private var keywordsText = ""
    @State private var errorText: String?
    @FocusState private var nameFocused: Bool

    private let icons = ["🛒","🍽️","🏠","🚗","🎬","💊","👕","✈️","🎁","📚","💪","🐶","☕️","⚡️","💅","🎮","🏋️","🍺"]
    private let colors = ["0E7C66","C07B00","3E6BB0","8A5BC7","C74B7A","2E9E8F","D2691E","5B8C5A","B0413E","6C6F93"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Live preview
                    HStack(spacing: 11) {
                        Text(icon).font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: colorHex).opacity(0.14),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "New category" : name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(name.isEmpty ? Theme.faint : Theme.ink)
                            Text("Budget \(Money.aud(budget)) / month")
                                .font(.system(size: 12)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))

                    field("Name") {
                        TextField("e.g. Health, Pets, Travel", text: $name)
                            .font(.system(size: 15)).focused($nameFocused)
                            .textInputAutocapitalization(.words)
                    }

                    label("Icon")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(icons, id: \.self) { e in
                                Text(e).font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(icon == e ? Color(hex: colorHex).opacity(0.18) : Theme.surface2,
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(icon == e ? Color(hex: colorHex) : Theme.line, lineWidth: icon == e ? 2 : 1))
                                    .onTapGesture { icon = e }
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    label("Colour")
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { c in
                            Circle().fill(Color(hex: c)).frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Theme.ink, lineWidth: colorHex == c ? 3 : 0).padding(-3))
                                .onTapGesture { colorHex = c }
                        }
                    }

                    field("Monthly budget") {
                        HStack {
                            Text("$").font(Theme.mono(20)).foregroundStyle(Theme.muted)
                            TextField("0", value: $budget, format: .number)
                                .font(Theme.mono(20)).keyboardType(.numberPad)
                        }
                    }

                    field("Match keywords") {
                        TextField("e.g. gym, chemist, fitness", text: $keywordsText)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    Text("Comma-separated. Live transactions whose merchant contains any of these land in this category.")
                        .font(.system(size: 11)).foregroundStyle(Theme.faint)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorText {
                        Text(errorText).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.bad)
                    }

                    Button {
                        let kws = keywordsText.split(separator: ",").map(String.init)
                        if let err = store.addCategory(name: name, icon: icon, colorHex: colorHex, budget: budget, keywords: kws) {
                            errorText = err
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Add category").frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.faint : Theme.accent,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("New category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { nameFocused = true } }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
    }

    @ViewBuilder private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(title)
            content()
                .padding(14)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
    }
}

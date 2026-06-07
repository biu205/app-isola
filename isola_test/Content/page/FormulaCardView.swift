// MARK: 公式資訊卡
import SwiftUI

struct FormulaCardView: View {
    let info: FormulaInfo
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton
            if isExpanded {
                Divider().padding(.horizontal, 16)
                contentBody
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.spring(duration: 0.3), value: isExpanded)
    }

    private var headerButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack {
                Image(systemName: "info.cir   cle.fill")
                    .foregroundStyle(.blue)
                Text(info.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(info.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let formula = info.formula {
                formulaBox(formula)
            }

            infoRow(icon: "chart.bar.fill", label: "正常範圍", value: info.normalRange)
            infoRow(icon: "lightbulb.fill", label: "解讀", value: info.interpretation)
        }
        .padding(16)
    }

    private func formulaBox(_ formula: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("計算公式", systemImage: "function")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            Text(formula)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

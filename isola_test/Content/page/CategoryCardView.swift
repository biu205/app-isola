import SwiftUI

struct CategoryCardView: View {
    let categoryScore: CategoryScore

    private var cat: HealthCategoryType { categoryScore.type }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(cat.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))

                Text(cat.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            ArcGaugeView(score: categoryScore.score, grade: categoryScore.grade)
                .frame(width: 80, height: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(cat.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

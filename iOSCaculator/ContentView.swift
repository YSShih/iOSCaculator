import SwiftUI

/// iPhone 內建計算機樣式：深色背景、灰色數字鍵、橙色運算鍵。
struct ContentView: View {
    @State private var viewModel = CalculatorViewModel()

    private enum Palette {
        static let digit = Color(red: 0.165, green: 0.165, blue: 0.176)
        static let utility = Color(red: 0.659, green: 0.659, blue: 0.667)
        static let operatorFill = Color(red: 1.0, green: 0.624, blue: 0.039)
        static let operatorText = Color(red: 1.0, green: 0.741, blue: 0.039)
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(viewModel.display)
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
                .accessibilityLabel("顯示：\(viewModel.display)")

            // 用 Grid 而非 LazyVGrid：只有 Grid 支援 gridCellColumns，
            // 「0」才能橫跨兩欄，排成真機的 4 欄 5 列。
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    key(viewModel.clearLabel, fill: Palette.utility, foreground: .black) {
                        viewModel.press(.clear)
                    }
                    key("±", fill: Palette.utility, foreground: .black) {
                        viewModel.press(.toggleSign)
                    }
                    key("%", fill: Palette.utility, foreground: .black) {
                        viewModel.press(.percent)
                    }
                    operatorKey("÷", .divide)
                }

                GridRow {
                    ForEach(7...9, id: \.self) { digit in
                        key("\(digit)", fill: Palette.digit) {
                            viewModel.press(.digit(digit))
                        }
                    }
                    operatorKey("×", .multiply)
                }

                GridRow {
                    ForEach(4...6, id: \.self) { digit in
                        key("\(digit)", fill: Palette.digit) {
                            viewModel.press(.digit(digit))
                        }
                    }
                    operatorKey("−", .subtract)
                }

                GridRow {
                    ForEach(1...3, id: \.self) { digit in
                        key("\(digit)", fill: Palette.digit) {
                            viewModel.press(.digit(digit))
                        }
                    }
                    operatorKey("+", .add)
                }

                GridRow {
                    key("0", fill: Palette.digit, wide: true) {
                        viewModel.press(.digit(0))
                    }
                    key(".", fill: Palette.digit) {
                        viewModel.press(.decimalPoint)
                    }
                    key("=", fill: Palette.operatorFill, foreground: Palette.operatorText) {
                        viewModel.press(.equals)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - 按鍵

    private func key(
        _ title: String,
        fill: Color,
        foreground: Color = .white,
        wide: Bool = false,
        active: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: title.count > 1 ? 28 : 36, weight: .regular))
                .foregroundStyle(active ? Palette.operatorFill : foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 84)
                .background(active ? Color.white : fill)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .gridCellColumns(wide ? 2 : 1)
    }

    private func operatorKey(_ title: String, _ op: CalculatorEngine.Operator) -> some View {
        key(
            title,
            fill: Palette.operatorFill,
            foreground: Palette.operatorText,
            active: viewModel.activeOperator == op
        ) {
            viewModel.press(.operator(op))
        }
    }
}

#Preview {
    ContentView()
}

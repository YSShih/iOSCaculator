import Foundation
import Observation

/// MVVM 的 ViewModel：把引擎狀態轉成可顯示字串與按鍵語意。
@MainActor
@Observable
final class CalculatorViewModel {

    enum Key: Equatable {
        case digit(Int)
        case decimalPoint
        case toggleSign
        case percent
        case `operator`(CalculatorEngine.Operator)
        case equals
        case clear
    }

    private(set) var display = "0"
    private(set) var clearLabel = "AC"
    private(set) var activeOperator: CalculatorEngine.Operator?

    private var engine = CalculatorEngine()

    func press(_ key: Key) {
        switch key {
        case .digit(let digit):
            engine.inputDigit(digit)
        case .decimalPoint:
            engine.inputDecimal()
        case .toggleSign:
            engine.toggleSign()
        case .percent:
            engine.percent()
        case .operator(let op):
            engine.setOperator(op)
        case .equals:
            engine.equals()
        case .clear:
            engine.clear()
        }
        display = Self.format(
            value: engine.displayValue,
            rawEntry: engine.entry,
            isTyping: engine.isTyping
        )
        clearLabel = engine.isTyping ? "C" : "AC"
        activeOperator = engine.activeOperator
    }

    // MARK: - 格式化

    /// 輸入中保留輸入字面（含尾隨小數點）並加分隔符；
    /// 其餘狀態以數值格式化；量級 ≥ 1e9 轉科學記號（與真機的簡化差異已記錄）。
    static func format(value: Double, rawEntry: String, isTyping: Bool) -> String {
        guard value.isFinite else { return "0" }
        if isTyping || rawEntry.hasSuffix(".") {
            return grouped(rawEntry)
        }
        if value == value.rounded() && abs(value) < 1e9 {
            let sign = value < 0 ? "-" : ""
            return sign + groupDigits(String(Int64(abs(value))))
        }
        if abs(value) >= 1e9 {
            return scientific(value)
        }
        return grouped(String(value))
    }

    private static func grouped(_ text: String) -> String {
        let negative = text.hasPrefix("-")
        let body = negative ? String(text.dropFirst()) : text
        let pieces = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intDigits = pieces.first.map(String.init) ?? "0"
        let fraction = pieces.count > 1 ? "." + pieces[1] : ""
        return (negative ? "-" : "") + groupDigits(intDigits) + fraction
    }

    private static func groupDigits(_ digits: String) -> String {
        var result = ""
        for (index, character) in digits.enumerated() {
            if index > 0 && (digits.count - index) % 3 == 0 {
                result.append(",")
            }
            result.append(character)
        }
        return result
    }

    private static func scientific(_ value: Double) -> String {
        String(format: "%.7g", value)
    }
}

import Foundation

/// 計算機核心：以明確狀態機表達（idle → typing → pending → result）。
/// 純 Swift、無 SwiftUI 相依，可獨立測試。
///
/// 行為假設（與真機的簡化差異，已記錄）：
/// - `%` ＝ 目前數字 ÷ 100（不做真機的 contextual percentage）
/// - 除以零顯示 0（可 AC 重置）
/// - 數字輸入上限 9 位
/// - 再按 `=` 重複上一次運算
/// - 連按運算子：直接取代待用運算子
struct CalculatorEngine {

    enum Operator: Equatable {
        case add, subtract, multiply, divide
    }

    enum Phase: Equatable {
        /// 全清後：顯示 0，下一個數字鍵會取代
        case idle
        /// 使用者正在輸入數字
        case typing
        /// 已按運算子，累積值在 accumulator
        case pending
        /// 按 `=` 得到結果
        case result
    }

    private(set) var phase: Phase = .idle
    /// 目前輸入（或結果）的原始字串
    private(set) var entry: String = "0"

    private var accumulator: Double = 0
    private var pendingOperator: Operator?
    private var lastOperation: (op: Operator, operand: Double)?

    /// UI：判斷 C / AC 按鈕標籤
    var isTyping: Bool { phase == .typing }

    /// UI：目前顯示的數值
    var displayValue: Double { Double(entry) ?? 0 }

    /// UI：需要高亮的運算子（僅 pending 狀態）
    var activeOperator: Operator? { phase == .pending ? pendingOperator : nil }

    // MARK: - 按鍵輸入

    mutating func inputDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        switch phase {
        case .idle, .pending:
            entry = digit == 0 ? "0" : String(digit)
            phase = .typing
        case .result:
            resetForNewCalculation()
            entry = digit == 0 ? "0" : String(digit)
            phase = .typing
        case .typing:
            guard digitCount(in: entry) < 9 else { return }
            if entry == "0" {
                entry = digit == 0 ? "0" : String(digit)
            } else {
                entry += String(digit)
            }
        }
    }

    mutating func inputDecimal() {
        switch phase {
        case .idle, .pending:
            entry = "0."
            phase = .typing
        case .result:
            resetForNewCalculation()
            entry = "0."
            phase = .typing
        case .typing:
            if !entry.contains(".") { entry += "." }
        }
    }

    mutating func toggleSign() {
        guard displayValue != 0 else { return }
        if entry.hasPrefix("-") {
            entry.removeFirst()
        } else {
            entry = "-" + entry
        }
    }

    mutating func percent() {
        entry = Self.string(from: displayValue / 100)
        if phase == .idle { phase = .typing }
    }

    mutating func setOperator(_ op: Operator) {
        switch phase {
        case .idle, .result:
            accumulator = displayValue
            pendingOperator = op
            phase = .pending
        case .typing:
            if let pending = pendingOperator {
                accumulator = apply(pending, accumulator, displayValue)
                entry = Self.string(from: accumulator)
            } else {
                accumulator = displayValue
            }
            pendingOperator = op
            phase = .pending
        case .pending:
            // 連按運算子：直接取代
            pendingOperator = op
        }
    }

    mutating func equals() {
        switch phase {
        case .pending:
            guard let op = pendingOperator else { return }
            let rhs = displayValue
            let result = apply(op, accumulator, rhs)
            lastOperation = (op, rhs)
            accumulator = result
            entry = Self.string(from: result)
            pendingOperator = nil
            phase = .result
        case .typing, .result:
            // 兩種子情境（與 setOperator 的 .typing 分支對稱）：
            // 1. 帶 pendingOperator：完成「按運算子後輸入第二運算元」的待算式
            // 2. 無 pending：以目前顯示值為左運算元，重複上次運算（lastOperation）
            let rhs = displayValue
            if let pending = pendingOperator {
                let result = apply(pending, accumulator, rhs)
                lastOperation = (pending, rhs)
                accumulator = result
                entry = Self.string(from: result)
                pendingOperator = nil
                phase = .result
            } else if let last = lastOperation {
                let result = apply(last.op, rhs, last.operand)
                accumulator = result
                entry = Self.string(from: result)
                phase = .result
            } else {
                return
            }
        case .idle:
            break
        }
    }

    /// 輸入中 → C：只清掉目前輸入；其他狀態 → AC：全部重置
    mutating func clear() {
        if phase == .typing {
            entry = "0"
            phase = .idle
        } else {
            self = CalculatorEngine()
        }
    }

    // MARK: - Private

    private func digitCount(in text: String) -> Int {
        text.filter(\.isNumber).count
    }

    private func apply(_ op: Operator, _ lhs: Double, _ rhs: Double) -> Double {
        switch op {
        case .add: return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return rhs == 0 ? 0 : lhs / rhs  // 除以零顯示 0（記錄的假設）
        }
    }

    private mutating func resetForNewCalculation() {
        accumulator = 0
        pendingOperator = nil
        lastOperation = nil
    }

    /// Double → 無浮點尾巴的最短字串（引擎內部儲存用）
    static func string(from value: Double) -> String {
        if value == value.rounded() && abs(value) < 1e15 {
            return String(Int64(value))
        }
        return String(value)
    }
}

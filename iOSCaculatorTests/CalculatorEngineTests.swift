import Testing
@testable import iOSCaculator

@Suite("CalculatorEngine 狀態機")
struct CalculatorEngineTests {

    private func type(_ text: String, into engine: inout CalculatorEngine) {
        for character in text {
            switch character {
            case "0"..."9":
                engine.inputDigit(character.wholeNumberValue ?? 0)
            case ".":
                engine.inputDecimal()
            default:
                break
            }
        }
    }

    @Test func 初始狀態顯示零() {
        var engine = CalculatorEngine()
        #expect(engine.entry == "0")
        #expect(engine.displayValue == 0)
        #expect(engine.isTyping == false)
    }

    @Test func 輸入數字累積() {
        var engine = CalculatorEngine()
        type("123", into: &engine)
        #expect(engine.entry == "123")
        #expect(engine.isTyping)
    }

    @Test func 基本加法() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 5)
        #expect(engine.phase == .result)
        #expect(engine.activeOperator == nil)
    }

    @Test func 連續運算依序計算() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        engine.setOperator(.multiply)
        #expect(engine.displayValue == 5)  // 2+3 先算出中間結果
        type("4", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 20)
    }

    @Test func 再按等號重複上次運算() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        engine.equals()  // 5
        engine.equals()  // 8
        #expect(engine.displayValue == 8)
    }

    @Test func 除以零顯示零() {
        var engine = CalculatorEngine()
        type("5", into: &engine)
        engine.setOperator(.divide)
        type("0", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 0)
    }

    @Test func 百分比為除以一百() {
        var engine = CalculatorEngine()
        type("50", into: &engine)
        engine.percent()
        #expect(engine.displayValue == 0.5)
    }

    @Test func 正負號切換() {
        var engine = CalculatorEngine()
        type("5", into: &engine)
        engine.toggleSign()
        #expect(engine.entry == "-5")
        engine.toggleSign()
        #expect(engine.entry == "5")
    }

    @Test func C只清目前輸入保留前次運算() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        #expect(engine.isTyping)
        engine.clear()  // C
        #expect(engine.entry == "0")
        #expect(engine.isTyping == false)
        type("4", into: &engine)
        engine.equals()  // 2 + 4 仍然成立
        #expect(engine.displayValue == 6)
    }

    @Test func AC全清後運算不殘留() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        engine.equals()      // 結果 5，此時按鈕為 AC
        engine.clear()       // AC 全清
        #expect(engine.entry == "0")
        #expect(engine.activeOperator == nil)
        type("3", into: &engine)
        engine.equals()      // 上次運算已清掉，不動作
        #expect(engine.displayValue == 3)
    }

    @Test func 超過九位數不再累加() {
        var engine = CalculatorEngine()
        type("1234567890", into: &engine)  // 第 10 位應被忽略
        #expect(engine.entry == "123456789")
    }

    @Test func 換按運算子直接取代() {
        var engine = CalculatorEngine()
        type("5", into: &engine)
        engine.setOperator(.add)
        engine.setOperator(.multiply)  // 取代 +
        #expect(engine.activeOperator == .multiply)
        type("4", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 20)
    }

    @Test func 結果後輸入數字開始新運算() {
        var engine = CalculatorEngine()
        type("2", into: &engine)
        engine.setOperator(.add)
        type("3", into: &engine)
        engine.equals()      // 5
        type("9", into: &engine)
        engine.setOperator(.add)
        type("1", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 10)
    }

    @Test func 小數輸入() {
        var engine = CalculatorEngine()
        type("1.5", into: &engine)
        engine.setOperator(.multiply)
        type("2", into: &engine)
        engine.equals()
        #expect(engine.displayValue == 3)
    }
}

@MainActor
@Suite("ViewModel 顯示格式化")
struct ViewModelFormatTests {

    @Test func 千分位分組() {
        #expect(CalculatorViewModel.format(value: 1234567, rawEntry: "1234567", isTyping: false) == "1,234,567")
    }

    @Test func 輸入中的小數點保留() {
        #expect(CalculatorViewModel.format(value: 0, rawEntry: "0.", isTyping: true) == "0.")
        #expect(CalculatorViewModel.format(value: 1234.5, rawEntry: "1234.5", isTyping: true) == "1,234.5")
    }

    @Test func 負數格式() {
        #expect(CalculatorViewModel.format(value: -1234, rawEntry: "-1234", isTyping: false) == "-1,234")
    }

    @Test func 大數轉科學記號() {
        let text = CalculatorViewModel.format(value: 1.5e9, rawEntry: "1500000000", isTyping: false)
        #expect(text.hasSuffix("e+09"))
    }
}

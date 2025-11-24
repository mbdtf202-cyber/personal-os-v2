import Foundation

/// Decimal 扩展 - 金融计算专用
public extension Decimal {
    /// 格式化为货币字符串
    func toCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
    
    /// 格式化为百分比
    func toPercentage(decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: (self / 100) as NSDecimalNumber) ?? "0%"
    }
    
    /// 四舍五入到指定小数位
    func rounded(_ scale: Int = 2) -> Decimal {
        var result = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, scale, .plain)
        return rounded
    }
}

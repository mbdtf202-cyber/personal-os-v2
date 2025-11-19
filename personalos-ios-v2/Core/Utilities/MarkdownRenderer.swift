import SwiftUI

struct MarkdownText: View {
    let content: String
    
    var body: some View {
        Text(attributedString)
            .textSelection(.enabled)
    }
    
    private var attributedString: AttributedString {
        var result = AttributedString(content)
        
        // Code blocks
        if let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) {
            let nsString = content as NSString
            let matches = codeRegex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    let codeText = String(content[range])
                    if let attrRange = Range(match.range, in: result) {
                        result[attrRange].font = .system(.body, design: .monospaced)
                        result[attrRange].backgroundColor = Color.gray.opacity(0.2)
                    }
                }
            }
        }
        
        // Bold text
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*", options: []) {
            let nsString = content as NSString
            let matches = boldRegex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    if let attrRange = Range(match.range, in: result) {
                        result[attrRange].font = .system(.body).bold()
                    }
                }
            }
        }
        
        // Headers
        if let headerRegex = try? NSRegularExpression(pattern: "^#{1,6}\\s+(.+)$", options: .anchorsMatchLines) {
            let nsString = content as NSString
            let matches = headerRegex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    let headerLevel = content[range].prefix(while: { $0 == "#" }).count
                    if let attrRange = Range(match.range, in: result) {
                        let fontSize: CGFloat = max(24 - CGFloat(headerLevel) * 2, 16)
                        result[attrRange].font = .system(size: fontSize).bold()
                    }
                }
            }
        }
        
        return result
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(highlightedCode)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(8)
        }
    }
    
    private var highlightedCode: AttributedString {
        var result = AttributedString(code)
        result.foregroundColor = .white
        
        // Simple syntax highlighting for Swift
        if language.lowercased() == "swift" {
            let keywords = ["func", "var", "let", "class", "struct", "enum", "import", "return", "if", "else", "for", "while", "guard", "switch", "case"]
            
            for keyword in keywords {
                if let regex = try? NSRegularExpression(pattern: "\\b\(keyword)\\b", options: []) {
                    let nsString = code as NSString
                    let matches = regex.matches(in: code, range: NSRange(location: 0, length: nsString.length))
                    
                    for match in matches {
                        if let range = Range(match.range, in: code) {
                            if let attrRange = Range(match.range, in: result) {
                                result[attrRange].foregroundColor = Color(hex: "FC6A5D")
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }
}

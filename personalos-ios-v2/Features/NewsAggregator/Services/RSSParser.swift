import Foundation

/// RSS 解析器 - 在后台线程执行
/// ✅ 避免阻塞主线程
class RSSParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var insideItem = false
    
    private var articles: [(title: String, link: String, description: String, pubDate: String)] = []
    
    func parse(data: Data) -> [(title: String, link: String, description: String, pubDate: String)] {
        articles = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, insideItem else { return }
        
        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "link":
            currentLink += trimmed
        case "description":
            currentDescription += trimmed
        case "pubDate":
            currentPubDate += trimmed
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            insideItem = false
            articles.append((
                title: currentTitle,
                link: currentLink,
                description: cleanHTML(currentDescription),
                pubDate: currentPubDate
            ))
        }
    }
    
    private func cleanHTML(_ html: String) -> String {
        // Remove HTML tags
        var cleaned = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


// ✅ P2 Fix: 删除废弃的同步代码，保持代码库整洁

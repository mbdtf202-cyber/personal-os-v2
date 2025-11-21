import SwiftUI

enum AppConstants {
    enum Icons {
        static let dashboard = "square.grid.2x2.fill"
        static let growth = "hammer.fill"
        static let social = "bubble.left.and.bubble.right.fill"
        static let wealth = "chart.line.uptrend.xyaxis"
        static let news = "newspaper.fill"
        static let settings = "gearshape.fill"
        
        static let add = "plus"
        static let search = "magnifyingglass"
        static let filter = "line.3.horizontal.decrease.circle"
        static let calendar = "calendar"
        static let checkmark = "checkmark.circle.fill"
        static let circle = "circle"
        static let trash = "trash"
        static let edit = "pencil"
        
        static let health = "heart.fill"
        static let steps = "figure.walk"
        static let sleep = "moon.stars.fill"
        static let mood = "face.smiling"
        static let energy = "bolt.fill"
        
        static let project = "folder.fill"
        static let code = "chevron.left.forwardslash.chevron.right"
        static let github = "link"
        static let star = "star.fill"
        
        static let trade = "chart.bar.xaxis"
        static let stock = "building.columns.fill"
        static let crypto = "bitcoinsign.circle.fill"
        static let forex = "dollarsign.arrow.circlepath"
        
        static let post = "doc.text.fill"
        static let draft = "lightbulb.fill"
        static let published = "checkmark.seal.fill"
        
        static let focus = "moon.stars.fill"
        static let timer = "timer"
        static let pause = "pause.fill"
        static let play = "play.fill"
    }
    
    enum Colors {
        static let mistBlue = Color(hex: "A8DADC")
        static let coral = Color(hex: "F4A261")
        static let almond = Color(hex: "E9C46A")
        static let matcha = Color(hex: "2A9D8F")
        static let lavender = Color(hex: "B8A4C9")
        
        static let background = Color(hex: "F8F9FA")
        static let cardBackground = Color.white
        static let primaryText = Color(hex: "1D3557")
        static let secondaryText = Color(hex: "6C757D")
        
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    enum FontSize {
        static let caption: CGFloat = 12
        static let body: CGFloat = 16
        static let title: CGFloat = 20
        static let largeTitle: CGFloat = 28
    }
    
    enum Animation {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Localization Keys
enum L10n {
    enum Dashboard {
        static let title = "Dashboard"
        static let greeting = "Good Morning"
        static let allCaughtUp = "All clear! Time to relax."
        static let pendingTasks = "You have %d tasks pending."
    }
    
    enum Tasks {
        static let title = "Tasks"
        static let addNew = "Add Task"
        static let completed = "Completed"
        static let pending = "Pending"
    }
    
    enum Social {
        static let title = "Social Command"
        static let newPost = "New Post"
        static let drafts = "Drafts & Ideas"
        static let published = "Published"
    }
    
    enum Trading {
        static let title = "Trading Journal"
        static let logTrade = "Log Trade"
        static let portfolio = "Portfolio"
        static let history = "History"
    }
    
    enum News {
        static let title = "News Feed"
        static let bookmarks = "Bookmarks"
        static let sources = "Sources"
    }
    
    enum Common {
        static let save = "Save"
        static let cancel = "Cancel"
        static let delete = "Delete"
        static let edit = "Edit"
        static let done = "Done"
        static let loading = "Loading..."
        static let error = "Error"
        static let retry = "Retry"
    }
}

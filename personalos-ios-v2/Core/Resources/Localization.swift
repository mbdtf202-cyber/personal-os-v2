import Foundation

enum L {
    enum Dashboard {
        static let title = NSLocalizedString("dashboard.title", comment: "Dashboard title")
        static let search = NSLocalizedString("dashboard.search", comment: "Search")
        static let focus = NSLocalizedString("dashboard.focus", comment: "Today's Focus")
        static let pending = NSLocalizedString("dashboard.pending", comment: "Pending")
        static let allClear = NSLocalizedString("dashboard.allClear", comment: "All clear message")
        
        enum Greeting {
            static let morning = NSLocalizedString("dashboard.greeting.morning", comment: "Good Morning")
            static let afternoon = NSLocalizedString("dashboard.greeting.afternoon", comment: "Good Afternoon")
            static let evening = NSLocalizedString("dashboard.greeting.evening", comment: "Good Evening")
            static let night = NSLocalizedString("dashboard.greeting.night", comment: "Good Night")
        }
    }
    
    enum Tasks {
        static let title = NSLocalizedString("tasks.title", comment: "Tasks")
        static let add = NSLocalizedString("tasks.add", comment: "Add Task")
        static let completed = NSLocalizedString("tasks.completed", comment: "Completed")
        static let pending = NSLocalizedString("tasks.pending", comment: "Pending")
        static let delete = NSLocalizedString("tasks.delete", comment: "Delete")
    }
    
    enum Social {
        static let title = NSLocalizedString("social.title", comment: "Social Command")
        static let newPost = NSLocalizedString("social.newPost", comment: "New Post")
        static let drafts = NSLocalizedString("social.drafts", comment: "Drafts & Ideas")
        static let published = NSLocalizedString("social.published", comment: "Published")
        static let scheduled = NSLocalizedString("social.scheduled", comment: "Scheduled")
    }
    
    enum Trading {
        static let title = NSLocalizedString("trading.title", comment: "Trading Journal")
        static let logTrade = NSLocalizedString("trading.logTrade", comment: "Log Trade")
        static let portfolio = NSLocalizedString("trading.portfolio", comment: "Portfolio")
        static let balance = NSLocalizedString("trading.balance", comment: "Total Balance")
    }
    
    enum News {
        static let title = NSLocalizedString("news.title", comment: "News Feed")
        static let bookmarks = NSLocalizedString("news.bookmarks", comment: "Bookmarks")
        static let sources = NSLocalizedString("news.sources", comment: "Sources")
    }
    
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings")
        static let sync = NSLocalizedString("settings.sync", comment: "Sync Settings")
        static let theme = NSLocalizedString("settings.theme", comment: "Theme")
        static let about = NSLocalizedString("settings.about", comment: "About")
    }
    
    enum Common {
        static let save = NSLocalizedString("common.save", comment: "Save")
        static let cancel = NSLocalizedString("common.cancel", comment: "Cancel")
        static let delete = NSLocalizedString("common.delete", comment: "Delete")
        static let edit = NSLocalizedString("common.edit", comment: "Edit")
        static let done = NSLocalizedString("common.done", comment: "Done")
        static let loading = NSLocalizedString("common.loading", comment: "Loading...")
        static let error = NSLocalizedString("common.error", comment: "Error")
        static let retry = NSLocalizedString("common.retry", comment: "Retry")
        static let ok = NSLocalizedString("common.ok", comment: "OK")
    }
}

# Personal OS v2

> Your life, organized. A comprehensive iOS life operating system built with SwiftUI.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Personal OS v2 is an all-in-one iOS application that helps you manage every aspect of your digital life. From health tracking to project management, from news aggregation to trading journals, everything you need in one elegant app.

## ✨ Features

### 🎯 Dashboard - Your Command Center
- **Smart Overview Cards** - Real-time stats for tasks, focus time, health score, and productivity
- **Health Score Algorithm** - Comprehensive scoring based on steps, sleep, energy, and heart rate
- **Personalized Insights** - AI-driven recommendations based on your behavior patterns
- **Focus Timer** - Professional Pomodoro technique implementation with 3 modes
- **Activity Heatmap** - Visual representation of your daily activities
- **Global Search** - Search across all modules instantly

### 💪 Health Center - HealthKit Integration
- **Real-time Health Data** - Steps, sleep, active energy, heart rate, exercise time, stand hours
- **Habit Tracking** - Build and maintain daily habits with visual progress
- **Data Visualization** - Beautiful charts and graphs for health metrics
- **Privacy First** - All health data stored locally on your device

### 📰 News Aggregator - Stay Informed
- **News API Integration** - Real-time news from multiple sources
- **RSS Feed Support** - Add custom RSS feeds for personalized content
- **Category Filtering** - Technology, Business, Health, Science, and more
- **Bookmark Management** - Save articles for later reading
- **Safari Integration** - Read articles in-app with Safari View Controller

### ✍️ Social Blog - Content Creation Platform
- **Markdown Editor** - Write with real-time preview
- **Content Calendar** - Plan and schedule your posts
- **Multi-Platform Support** - Twitter, Medium, Dev.to, LinkedIn
- **Draft System** - Auto-save and manage drafts
- **Export Options** - Export as Markdown or HTML
- **Statistics Dashboard** - Track articles, word count, and reading time

### 💰 Trading Journal - Investment Tracking
- **Trade Logging** - Record buy/sell transactions with detailed information
- **Portfolio Management** - Track multiple assets and their performance
- **Performance Analytics** - Win rate, average profit, best/worst trades
- **Asset Details** - Deep dive into individual asset performance
- **Data Visualization** - Portfolio pie charts and trend graphs

### 🚀 Project Hub - GitHub Integration
- **GitHub Sync** - Automatically sync repositories from GitHub
- **Project Management** - Track project status (Idea/Active/Done)
- **Progress Tracking** - Visual progress bars for active projects
- **Quick Actions** - Create tasks, open GitHub, edit details
- **Statistics Cards** - Active projects, shipped projects, total stars

### 📚 Training System - Knowledge Base
- **Code Snippets** - Store and organize code snippets
- **Multi-Language Support** - 12+ programming languages
- **Category System** - Swift, Python, DevOps, Bug Fixes, and more
- **Search Functionality** - Search by title, summary, or code content
- **Export & Share** - Share snippets or export as Markdown
- **Syntax Highlighting** - Beautiful code display with syntax colors

### 🛠️ Tools - Productivity Utilities
- **QR Code Generator** - Create QR codes from text or URLs
- **Password Generator** - Generate secure passwords with customizable options
- **Unit Converter** - Convert length, weight, temperature, and volume
- **Color Picker** - HEX/RGB/HSB color tool with quick colors
- **Quick Notes** - Capture ideas instantly
- **Timestamp Converter** - Unix timestamp utilities

### ⚙️ Settings - Customization
- **Theme Switching** - Glass, Vibrant, and Noir themes
- **API Configuration** - Set up News API and Stock API keys
- **Preferences** - Haptic feedback, notifications
- **Data Management** - Export all data as JSON or clear all data
- **Privacy Controls** - Full control over your data

## 🎨 Design System

### Morandi Color Palette
Personal OS v2 features a sophisticated Morandi color scheme that's easy on the eyes:

- **Matcha Green** - Success and completion states
- **Mist Blue** - Primary actions and information
- **Coral Orange** - Warnings and health alerts
- **Almond Yellow** - Highlights and emphasis
- **Lavender Purple** - Secondary actions

### Glass Morphism UI
- Semi-transparent backgrounds with blur effects
- Soft shadows and rounded corners
- Smooth animations and transitions
- Haptic feedback for all interactions

## 🏗️ Architecture

### Tech Stack
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Networking**: URLSession with async/await
- **Health Data**: HealthKit
- **Architecture**: MVVM with Observation framework

### Project Structure
```
personalos-ios-v2/
├── App/                    # App configuration and delegates
├── Core/                   # Core components
│   ├── DesignSystem/      # Colors, typography, components
│   ├── Navigation/        # Navigation and routing
│   └── Utilities/         # Helper classes and extensions
├── Data/                   # Data layer
│   ├── Models/            # SwiftData models
│   ├── Networking/        # API services
│   └── Persistence/       # Data persistence
└── Features/              # Feature modules
    ├── Dashboard/         # Smart dashboard
    ├── HealthCenter/      # Health tracking
    ├── NewsAggregator/    # News and RSS
    ├── SocialBlog/        # Content creation
    ├── TradingJournal/    # Investment tracking
    ├── ProjectHub/        # Project management
    ├── TrainingSystem/    # Knowledge base
    ├── Tools/             # Utility tools
    └── Settings/          # App settings
```

## 🚀 Getting Started

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/personal-os-v2.git
cd personal-os-v2
```

2. Open the project in Xcode:
```bash
open personalos-ios-v2.xcodeproj
```

3. Configure API keys (optional):
   - Get a free News API key from [newsapi.org](https://newsapi.org)
   - Get a free Stock API key from [alphavantage.co](https://www.alphavantage.co)
   - Add keys in Settings > API Configuration

4. Build and run:
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### HealthKit Setup
To use health tracking features:

1. Enable HealthKit capability in Xcode
2. The app will request permissions on first launch
3. Grant access to the health data types you want to track

## 📱 Usage

### Dashboard
The Dashboard is your central hub. It shows:
- Today's task completion rate
- Focus time accumulated
- Health score (0-100)
- Productivity level
- Personalized insights and recommendations

### Focus Timer
Use the Pomodoro technique to boost productivity:
1. Tap the Focus Timer button
2. Choose mode: Focus (25min), Short Break (5min), or Long Break (15min)
3. Start the timer and stay focused
4. The app automatically switches modes after completion

### News Aggregator
Stay informed with the latest news:
1. Browse news by category
2. Add custom RSS feeds
3. Bookmark articles for later
4. Read in-app with Safari integration

### Trading Journal
Track your investments:
1. Log trades with buy/sell details
2. View portfolio performance
3. Analyze win rate and profit metrics
4. Export data for tax purposes

### Project Hub
Manage your projects:
1. Sync repositories from GitHub
2. Track project progress
3. Create tasks directly from projects
4. Open projects in GitHub with one tap

## 🔒 Privacy & Security

Personal OS v2 takes your privacy seriously:

- **Local Storage**: All data stored locally using SwiftData
- **No Tracking**: No third-party analytics or tracking
- **HealthKit Privacy**: Health data never leaves your device
- **API Keys**: Stored securely in UserDefaults
- **Data Export**: Full control to export or delete your data

## 🎯 Roadmap

### Short Term (1-2 weeks)
- [ ] Widget support for home screen
- [ ] Siri shortcuts integration
- [ ] Dark mode optimization
- [ ] iPad layout improvements

### Medium Term (1-2 months)
- [ ] iCloud sync across devices
- [ ] Apple Watch companion app
- [ ] AI-powered insights enhancement
- [ ] Custom themes creator

### Long Term (3-6 months)
- [ ] macOS version with Mac Catalyst
- [ ] Automation workflows
- [ ] Team collaboration features
- [ ] App Store release

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [NewsAPI](https://newsapi.org) for news data
- [Alpha Vantage](https://www.alphavantage.co) for stock data
- [SF Symbols](https://developer.apple.com/sf-symbols/) for beautiful icons
- Apple's HealthKit for health data integration

## 📧 Contact

Project Link: [https://github.com/yourusername/personal-os-v2](https://github.com/yourusername/personal-os-v2)

---

**Built with ❤️ using SwiftUI**

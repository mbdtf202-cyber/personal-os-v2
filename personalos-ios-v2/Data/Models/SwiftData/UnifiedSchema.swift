// MARK: - Unified Schema (Re-exports for backward compatibility)
// This file re-exports all models from their new domain-specific locations
// Models have been refactored into separate files by domain for better modularity

@_exported import Foundation

// Re-export all domain models
// These are now located in their respective domain folders:
// - Social/SocialPost.swift, Social/SocialPlatform.swift
// - Todo/TodoItem.swift
// - Trading/AssetItem.swift, Trading/TradeRecord.swift
// - Health/HabitItem.swift, Health/HealthLog.swift
// - News/NewsItem.swift, News/RSSFeed.swift
// - Project/ProjectItem.swift
// - Knowledge/CodeSnippet.swift

import Foundation
import SwiftData

/// ✅ GOD-TIER OPTIMIZATION 1: Explicit Schema Migration Plan
/// Handles complex migrations for TradeRecord and other models with computed fields

// MARK: - Schema Versions

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [TradeRecordV1.self, AssetItemV1.self]
    }
    
    @Model
    final class TradeRecordV1 {
        var id: UUID
        var symbol: String
        var type: String  // "buy" or "sell"
        var quantity: Decimal
        var price: Decimal
        var date: Date
        var notes: String
        
        init(id: UUID, symbol: String, type: String, quantity: Decimal, price: Decimal, date: Date, notes: String) {
            self.id = id
            self.symbol = symbol
            self.type = type
            self.quantity = quantity
            self.price = price
            self.date = date
            self.notes = notes
        }
    }
    
    @Model
    final class AssetItemV1 {
        var id: UUID
        var symbol: String
        var name: String
        var quantity: Decimal
        var currentPrice: Decimal
        var avgCost: Decimal
        
        init(id: UUID, symbol: String, name: String, quantity: Decimal, currentPrice: Decimal, avgCost: Decimal) {
            self.id = id
            self.symbol = symbol
            self.name = name
            self.quantity = quantity
            self.currentPrice = currentPrice
            self.avgCost = avgCost
        }
    }
}

enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [TradeRecordV2.self, AssetItemV2.self]
    }
    
    @Model
    final class TradeRecordV2 {
        var id: UUID
        var symbol: String
        var type: String
        var quantity: Decimal
        var price: Decimal
        var priceScaled: Int64  // ✅ NEW: Scaled price for precise storage
        var date: Date
        var notes: String
        
        init(id: UUID, symbol: String, type: String, quantity: Decimal, price: Decimal, date: Date, notes: String) {
            self.id = id
            self.symbol = symbol
            self.type = type
            self.quantity = quantity
            self.price = price
            self.priceScaled = Int64((price as NSDecimalNumber).doubleValue * 10000)
            self.date = date
            self.notes = notes
        }
    }
    
    @Model
    final class AssetItemV2 {
        var id: UUID
        var symbol: String
        var name: String
        var quantity: Decimal
        var currentPrice: Decimal
        var avgCost: Decimal
        var type: String  // ✅ NEW: Asset type
        
        init(id: UUID, symbol: String, name: String, quantity: Decimal, currentPrice: Decimal, avgCost: Decimal, type: String) {
            self.id = id
            self.symbol = symbol
            self.name = name
            self.quantity = quantity
            self.currentPrice = currentPrice
            self.avgCost = avgCost
            self.type = type
        }
    }
}

// MARK: - Migration Plan

enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    /// Migration from V1 to V2: Add priceScaled and asset type
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self,
        willMigrate: { context in
            Logger.log("🔄 Starting migration V1 → V2", category: Logger.general)
            
            // Create backup before migration
            let backupService = DataBackupService()
            do {
                _ = try await backupService.createBackup()
                Logger.log("✅ Backup created before migration", category: Logger.general)
            } catch {
                Logger.error("⚠️ Failed to create backup: \(error)", category: Logger.general)
                // Continue anyway - migration is important
            }
        },
        didMigrate: { context in
            Logger.log("🔄 Executing migration V1 → V2", category: Logger.general)
            
            // Migrate TradeRecord: Calculate priceScaled from price
            let tradeDescriptor = FetchDescriptor<AppSchemaV2.TradeRecordV2>()
            let trades = try context.fetch(tradeDescriptor)
            
            var migratedCount = 0
            var errorCount = 0
            
            for trade in trades {
                do {
                    // Recalculate priceScaled from price
                    let priceDouble = (trade.price as NSDecimalNumber).doubleValue
                    trade.priceScaled = Int64(priceDouble * 10000)
                    migratedCount += 1
                } catch {
                    Logger.error("Failed to migrate trade \(trade.id): \(error)", category: Logger.general)
                    errorCount += 1
                }
            }
            
            Logger.log("✅ Migrated \(migratedCount) trades, \(errorCount) errors", category: Logger.general)
            
            // Migrate AssetItem: Set default type
            let assetDescriptor = FetchDescriptor<AppSchemaV2.AssetItemV2>()
            let assets = try context.fetch(assetDescriptor)
            
            var assetMigratedCount = 0
            
            for asset in assets {
                // Infer type from symbol (simple heuristic)
                if asset.symbol.hasSuffix("USD") || asset.symbol.contains("/") {
                    asset.type = "crypto"
                } else if asset.symbol.count <= 5 && asset.symbol.uppercased() == asset.symbol {
                    asset.type = "stock"
                } else {
                    asset.type = "other"
                }
                assetMigratedCount += 1
            }
            
            Logger.log("✅ Migrated \(assetMigratedCount) assets with type inference", category: Logger.general)
            
            try context.save()
            Logger.log("🎉 Migration V1 → V2 completed successfully", category: Logger.general)
        }
    )
}

// MARK: - Migration Helpers

extension SchemaMigrationPlan {
    /// Validate migration integrity
    static func validateMigration(context: ModelContext) async throws -> Bool {
        Logger.log("🔍 Validating migration integrity", category: Logger.general)
        
        // Check for data corruption
        let tradeDescriptor = FetchDescriptor<TradeRecord>()
        let trades = try context.fetch(tradeDescriptor)
        
        var validCount = 0
        var invalidCount = 0
        
        for trade in trades {
            if trade.price.isNaN || trade.price.isInfinite || trade.price < 0 {
                invalidCount += 1
                Logger.warning("Invalid trade found: \(trade.id)", category: Logger.general)
            } else if trade.quantity.isNaN || trade.quantity.isInfinite || trade.quantity <= 0 {
                invalidCount += 1
                Logger.warning("Invalid trade quantity: \(trade.id)", category: Logger.general)
            } else {
                validCount += 1
            }
        }
        
        let isValid = invalidCount == 0
        Logger.log("Validation: \(validCount) valid, \(invalidCount) invalid", category: Logger.general)
        
        return isValid
    }
}

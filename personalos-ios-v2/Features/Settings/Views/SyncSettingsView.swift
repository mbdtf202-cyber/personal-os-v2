import SwiftUI

struct SyncSettingsView: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    @State private var showSyncError = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: syncManager.iCloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud.fill")
                        .foregroundStyle(syncManager.iCloudAvailable ? .green : .red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Status")
                            .font(.headline)
                        Text(syncManager.iCloudAvailable ? "Connected" : "Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if case .syncing = syncManager.syncStatus {
                        ProgressView()
                    }
                }
            } header: {
                Text("Cloud Sync")
            }
            
            Section {
                if let lastSync = syncManager.lastSyncDate {
                    HStack {
                        Text("Last Synced")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    Task {
                        await syncManager.manualSync()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                }
                .disabled(!syncManager.iCloudAvailable || syncManager.syncStatus == .syncing)
            } header: {
                Text("Manual Sync")
            }
            
            Section {
                NavigationLink {
                    SyncStatusDetailView()
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Sync Details")
                    }
                }
            }
        }
        .navigationTitle("Sync Settings")
        .alert("Sync Error", isPresented: $showSyncError) {
            Button("OK") {}
        } message: {
            if case .failed(let error) = syncManager.syncStatus {
                Text(error.localizedDescription)
            }
        }
    }
}

struct SyncStatusDetailView: View {
    @StateObject private var syncManager = CloudSyncManager.shared
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    statusBadge
                }
            }
            
            Section("Information") {
                Text("PersonalOS uses iCloud to sync your data across all your devices. Make sure you're signed in to iCloud and have enough storage available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If sync is not working:")
                        .font(.headline)
                    
                    Text("• Check your iCloud settings")
                    Text("• Ensure you have internet connection")
                    Text("• Verify iCloud storage is not full")
                    Text("• Try signing out and back into iCloud")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Sync Details")
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch syncManager.syncStatus {
        case .idle:
            Text("Idle")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        case .syncing:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        case .synced:
            Text("Synced")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
        case .failed:
            Text("Failed")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

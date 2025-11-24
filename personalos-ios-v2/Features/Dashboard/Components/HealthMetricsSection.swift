import SwiftUI

struct HealthMetricsSection: View {
    let healthManager: HealthStoreManager
    @State private var showHealthPermission = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(AppTheme.coral)
                Text("Health Overview")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            
            if !healthManager.isHealthKitAvailable {
                healthUnavailableCard
            } else if healthManager.steps == 0 && healthManager.sleepHours == 0 {
                connectHealthCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        #if !targetEnvironment(macCatalyst)
                        ProgressRing(
                            progress: min(Double(healthManager.steps) / 10000.0, 1.0),
                            color: AppTheme.matcha,
                            icon: "figure.walk",
                            title: "Steps",
                            value: "\(healthManager.steps)",
                            unit: ""
                        )
                        #endif
                        
                        ProgressRing(
                            progress: min(healthManager.sleepHours / 8.0, 1.0),
                            color: AppTheme.mistBlue,
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: String(format: "%.1f", healthManager.sleepHours),
                            unit: "h"
                        )
                        ProgressRing(
                            progress: healthManager.energyLevel,
                            color: AppTheme.coral,
                            icon: "flame.fill",
                            title: "Energy",
                            value: "\(Int(healthManager.energyLevel * 100))",
                            unit: "%"
                        )
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .task {
            await healthManager.syncHealthData()
        }
    }
    
    private var connectHealthCard: some View {
        Button {
            Task {
                // ✅ P2 Fix: Request permission directly
                await healthManager.requestHealthKitAuthorization()
                
                // Show permission sheet if authorization failed
                if !healthManager.isAuthorized {
                    showHealthPermission = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.coral)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.coral.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Health Data")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(healthManager.authorizationError ?? "Track your steps, sleep, and energy levels")
                        .font(.caption)
                        .foregroundStyle(healthManager.authorizationError != nil ? AppTheme.coral : AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: AppTheme.shadow, radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showHealthPermission) {
            HealthPermissionView()
        }
    }
    
    private var healthUnavailableCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.almond)
            
            Text("Health data not available on this device")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding()
        .background(AppTheme.almond.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HealthPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthStoreManager.self) private var healthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.coral)
                
                VStack(spacing: 12) {
                    Text("Connect Health Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Allow PersonalOS to read your health data to provide personalized insights and track your wellness journey.")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(icon: "figure.walk", title: "Steps", description: "Track daily activity")
                    PermissionRow(icon: "bed.double.fill", title: "Sleep", description: "Monitor sleep quality")
                    PermissionRow(icon: "heart.fill", title: "Heart Rate", description: "Measure wellness")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                Spacer()
                
                Button {
                    Task {
                        await healthManager.requestHealthKitAuthorization()
                        dismiss()
                    }
                } label: {
                    Text("Allow Access")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.coral)
                        .cornerRadius(12)
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundStyle(AppTheme.secondaryText)
            }
            .padding()
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.mistBlue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

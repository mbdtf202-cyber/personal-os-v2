import SwiftUI

struct TasksSection: View {
    let tasks: [TodoItem]
    let onToggleTask: (TodoItem) async -> Void
    let onDeleteTask: (TodoItem) async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L.Tasks.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(tasks.filter { !$0.isCompleted }.count) \(L.Tasks.pending)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.coral.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.matcha)
                    Text(L.Dashboard.allClear)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tasks.prefix(5)) { task in
                        TaskRow(
                            task: task,
                            onToggle: { await onToggleTask(task) },
                            onDelete: { await onDeleteTask(task) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TaskRow: View {
    let task: TodoItem
    let onToggle: () async -> Void
    let onDelete: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { 
                Task { 
                    await onToggle()
                } 
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? AppTheme.matcha : AppTheme.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText)
                
                HStack(spacing: 8) {
                    if !task.category.isEmpty {
                        Text(task.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.almond.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    Text(task.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Button(action: { 
                Task { 
                    await onDelete()
                } 
            }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

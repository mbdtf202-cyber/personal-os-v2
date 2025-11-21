import SwiftUI

struct AddTaskSection: View {
    @Binding var newTaskTitle: String
    let onAddTask: () -> Void
    
    private var isNewTaskValid: Bool {
        !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add New Task")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText)
            
            HStack(spacing: 12) {
                TextField("What needs to be done?", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if isNewTaskValid {
                            onAddTask()
                        }
                    }
                
                Button(action: onAddTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isNewTaskValid ? AppTheme.matcha : AppTheme.secondaryText)
                }
                .disabled(!isNewTaskValid)
            }
        }
        .padding(.horizontal)
    }
}

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: ProjectItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Project Info")) {
                TextField("Name", text: $project.name)
                TextField("Description", text: $project.details)
                TextField("Language", text: $project.language)
            }
            
            Section(header: Text("Status")) {
                Picker("Status", selection: $project.status) {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress: \(Int(project.progress * 100))%")
                        .font(.subheadline)
                    Slider(value: $project.progress, in: 0...1)
                }
            }
            
            Section(header: Text("Stats")) {
                Stepper("Stars: \(project.stars)", value: $project.stars, in: 0...10000)
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

import SwiftUI

/// 输入框组件
struct InputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Typography.labelLarge)
                .foregroundColor(MorandiColors.textPrimary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Typography.bodyMedium)
            .foregroundColor(MorandiColors.textPrimary)
            .padding(12)
            .background(MorandiColors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .keyboardType(keyboardType)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(Typography.labelSmall)
                    .foregroundColor(MorandiColors.error)
            }
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return MorandiColors.error
        }
        return MorandiColors.border
    }
}

#Preview {
    VStack(spacing: 16) {
        InputField(title: "用户名", text: .constant(""), placeholder: "请输入用户名")
        InputField(title: "密码", text: .constant(""), placeholder: "请输入密码", isSecure: true)
        InputField(title: "邮箱", text: .constant("test@example.com"), placeholder: "请输入邮箱", keyboardType: .emailAddress, errorMessage: "邮箱格式不正确")
    }
    .padding()
    .background(MorandiColors.background)
}

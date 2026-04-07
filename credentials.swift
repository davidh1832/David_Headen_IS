import SwiftUI

struct LoginView: View {
    // State variables to store user input
    @State private var username = ""
    @State private var password = ""
    
    // Custom Color Constants
    private let backgroundColor = Color(hex: "63C8F2")
    private let fieldColor = Color(hex: "06D6A0")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background Color
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    // 2. Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 3. Input Fields
                    VStack(spacing: 15) {
                        TextField("Email", text: $username)
                            .padding()
                            .background(fieldColor) // Updated Hex
                            .cornerRadius(12)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(fieldColor) // Updated Hex
                            .cornerRadius(12)
                            .textContentType(.oneTimeCode) // Prevents the "Strong Password" overlay
                    }
                    .padding(.horizontal)
                    
                    // 4. Forgot Password
                    Button(action: { /* Add Action */ }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    
                    // 5. Sign In Button
                    NavigationLink(destination: MentalHealthChatbotUI().navigationBarBackButtonHidden(true)) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black) // High contrast for the main button
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // 6. Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.black.opacity(0.2))
                        Text("or").font(.footnote).foregroundColor(.black.opacity(0.6))
                        Rectangle().frame(height: 1).foregroundColor(.black.opacity(0.2))
                    }
                    .padding(.horizontal)
                    
                    // 7. Google Sign In Button
                    Button(action: { }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.red)
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.9)) // Slight transparency to blend
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 8. Footer
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.black)
                        NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)){
                            Text("Sign Up")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .font(.footnote)
                }
            }
        }
    }
}

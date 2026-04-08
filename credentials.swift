import SwiftUI
// This code is the Login page for the Echo app. Users can submit their username and password to login to their account
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
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    //  Header
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
                    
                    // Input Fields
                    VStack(spacing: 15) {
                        TextField("Email", text: $username)
                            .padding()
                            .background(fieldColor) //  Hex
                            .cornerRadius(12)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(fieldColor) // Hex
                            .cornerRadius(12)
                            .textContentType(.oneTimeCode) //AI generated line, this fixed an error with not being able to enter password in the UI
                    }
                    .padding(.horizontal)
                    
                   
                    
                    // Sign In Button
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
                    
                    
                    
                    Spacer()
                    
                    // Back to sign-up page
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

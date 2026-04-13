import SwiftUI
// This code is the Login page for the Echo app. Users can submit their username and password to login to their account.
struct LoginView: View {
    // store user credentials
    @State private var username = ""
    @State private var password = ""
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue_color //Blue baxkground
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
                            .background(Color.green_color) 
                            .cornerRadius(12)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.green_color) 
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
                            .background(Color.black)
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

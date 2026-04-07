import SwiftUI
struct SignUpView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var navigateToMain: Bool = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) var dismiss

    // Custom Color Constants
    private let backgroundColor = Color(hex: "63C8F2")
    private let fieldColor = Color(hex: "06D6A0")

    var isEmailValid: Bool {
        // Regex code from Maxim Shoustin on Stack Overflow.  Link:https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let regexEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", regexEmail)
        return emailPredicate.evaluate(with: email)
    }
    
    var passwordsMatch: Bool { !password.isEmpty && password == confirmPassword }
    
    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && isEmailValid && passwordsMatch && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
               
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        VStack(spacing: 15) {
                            nameFields
                            emailField
                            passwordFields
                        }

                        validationMessages
                        signUpButton
                        backToLoginButton
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MentalHealthChatbotUI()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// Components
extension SignUpView {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Fill in your details to get started")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7)) // Darkened for visibility against blue
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
    }

    private var nameFields: some View {
        HStack(spacing: 15) {
            TextField("First Name", text: $firstName)
                .padding()
                .background(fieldColor) // Updated Hex
                .cornerRadius(12)
            
            TextField("Last Name", text: $lastName)
                .padding()
                .background(fieldColor) // Updated Hex
                .cornerRadius(12)
        }
    }

    private var emailField: some View {
        TextField("Email Address", text: $email)
            .padding()
            .background(fieldColor) // Updated Hex
            .cornerRadius(12)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(email.isEmpty || isEmailValid ? Color.clear : Color.red, lineWidth: 2)
            )
    }

    private var passwordFields: some View {
        VStack(spacing: 15) {
            SecureField("Password (min 6 chars)", text: $password)
                .padding()
                .background(fieldColor) //  Hex
                .cornerRadius(12)
                .textContentType(.oneTimeCode)
                
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(fieldColor) // Hex
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(!confirmPassword.isEmpty && !passwordsMatch ? Color.red : Color.clear, lineWidth: 2)
                )
                .textContentType(.oneTimeCode)
        }
    }

    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !email.isEmpty && !isEmailValid {
                Text("Please enter a valid email").foregroundColor(.red)
            }
            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match").foregroundColor(.red)
            }
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters").foregroundColor(.red)
            }
        }
        .font(.caption)
        .fontWeight(.bold) // Bolded to stand out against the blue background
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var signUpButton: some View {
        Button(action: {
            isLoggedIn = true
            navigateToMain = true
        }) {
            Text("Create Account")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.black : Color.gray) //  Black for contrast
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
    }

    private var backToLoginButton: some View {
        NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true)) {
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.black)
                Text("Sign In")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .font(.footnote)
        }
        .padding(.top, 10)
    }
}

// Hex code from https://medium.com/@ant.lucchini/swiftui-hex-color-made-easy-a-simple-extension-for-your-projects-189d200ec915
// Extensions that allows for hex colors to be used in application
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

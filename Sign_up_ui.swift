import SwiftUI
//This is the sign up page where users can enter their credentials to create an account.
struct SignUpView: View {
    
    @State private var to_main: Bool = false
    // Input fields
    @State private var first_name = ""
    @State private var last_name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm_pass = ""
    

    
    

    var valid_email: Bool {
        // Regex code from Maxim Shoustin on Stack Overflow.  Link:https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let regexEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", regexEmail)
        return emailPredicate.evaluate(with: email)
    }
    
    var password_match: Bool { !password.isEmpty && password == confirm_pass }
    
    var valid_form: Bool {
        !first_name.isEmpty && !last_name.isEmpty && valid_email && password_match && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
               
                Color.blue_color
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        header_section
                            .padding(.bottom, 10)
                        
                        VStack(spacing: 12) {
                            name_fields
                            email_field
                            password_fields
                        }

                        error_messages
                            .padding(.top, 5)
                        sign_up_button
                        back_to_login
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(isPresented: $to_main) {
                MentalHealthChatbotUI()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// Components
extension SignUpView {
    // Header
    private var header_section: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Fill in your details to get started")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7)) // Darkened for visibility
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
    }
    // First and last name fields
    private var name_fields: some View {
        HStack(spacing: 15) {
            TextField("First Name", text: $first_name)
                .padding()
                .background(Color.green_color) //  Hex
                .cornerRadius(12)
            
            TextField("Last Name", text: $last_name)
                .padding()
                .background(Color.green_color) //  Hex
                .cornerRadius(12)
        }
    }
    // Email box
    private var email_field: some View {
        TextField("Email Address", text: $email)
            .padding()
            .background(Color.green_color) //  Hex
            .cornerRadius(12)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(email.isEmpty || valid_email ? Color.clear : Color.red, lineWidth: 2)
            )
    }
    
    //Password and confirm password boxes
    private var password_fields: some View {
        VStack(spacing: 15) {
            SecureField("Password (min 6 chars)", text: $password)
                .padding()
                .background(Color.green_color) //  Hex
                .cornerRadius(12)
                .textContentType(.oneTimeCode)
                
            
            SecureField("Confirm Password", text: $confirm_pass)
                .padding()
                .background(Color.green_color) // Hex
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(!confirm_pass.isEmpty && !password_match ? Color.red : Color.clear, lineWidth: 2)
                )
                .textContentType(.oneTimeCode)
        }
    }
    
    // Checks for proper credentials (Valid email, password and confirm password must be greater than 6 characters and need to mach)
    private var error_messages: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !email.isEmpty && !valid_email {
                Text("Please enter a valid email").foregroundColor(.red)
            }
            if !confirm_pass.isEmpty && !password_match {
                Text("Passwords do not match").foregroundColor(.red)
            }
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters").foregroundColor(.red)
            }
        }
        .font(.caption)
        .fontWeight(.bold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    // submit button to navigate to main page with credentials
    private var sign_up_button: some View {
        Button(action: {
            to_main = true
        }) {
            Text("Create Account")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(valid_form ? Color.black : Color.gray)
                .cornerRadius(12)
        }
        .disabled(valid_form)
    }
    // if already have an account, navigate back to login page
    private var back_to_login: some View {
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
    static let blue_color = Color(hex: "63C8F2") // AI generated hex color
    static let green_color = Color(hex: "06D6A0")// AI generated hex color
}



    

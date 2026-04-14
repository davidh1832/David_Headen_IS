
import SwiftUI
import Foundation
// This is the main chat inferface for the Echo mobile application, where users czn submit queries and recieve theraputic advice and/or religious quotes from sacred texts to address their struggles

enum MessageRole {
    case user
    case bot
}
struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let role: MessageRole
    let timestamp: Date = Date()
    
    var isUser: Bool { role == .user }
    
}
struct quote_response: Codable {
    let quote: String
    let chapter: String
    let source: String
}
//Main Page
// Structure of the container
struct MentalHealthChatbotUI: View {
    
    // Request Handling
    private let api_service = ChatbotAPI()
    
    private let userID = UUID().uuidString
    
    
    
    //  chat history
    @State private var messages: [Message] = [
        Message(text: "Hello! My name is Echo, and i'm here to listen and offer support. How are you feeling today?", role: .bot)
    ]
    
    @State private var current_input: String = ""
    @State private var sending = false // Loading indicator
    @State private var selected_source: String = "None"
    private let sources = ["None", "Bible", "Quran", "Torah"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Main Chat Scrolling Area
                chat_history
                    .background(Color(.systemGray6))
                
                // Input Bar
                inputBar
            }
            // Header Area
            .navigationTitle("Chat with Echo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blue_color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Echo")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text("What's on your mind today?")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    //Allows scrolling and loops through message array to view all previous chats
    private var chat_history: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
            }
            // scrolls to the bottom when new message is entered
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // User Input field
    private var inputBar: some View {
        HStack(alignment: .bottom) {
            Menu {      // Menu to pick source
                        Picker("Select Source", selection: $selected_source) {
                            ForEach(sources, id: \.self) { source in
                                Text(source).tag(source)
                            }
                        }
                    // Book icon for religious quotes
                    } label: {
                        Image(systemName: "book.closed.fill") // AI generated book image
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selected_source == "None" ? .gray : Color.green_color)
                    }
                    .padding(.bottom, 4)
            
            TextField("Type your message...", text: $current_input, axis: .vertical)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .lineLimit(1...5) // As the user types, if the number of lines exceeds 5, scrolling in input bar occurs
           
            if sending {
                ProgressView() //API loading
                    .frame(width: 32, height: 32)
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill") // AI generated image
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(current_input.isEmpty ? Color(.systemGray) : Color.blue_color)
                }
                // Send button is disabled if text field is empty
                .disabled(current_input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        // Fitting input bar into container
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: Color(.systemGray4).opacity(0.5), radius: 3, x: 0, y: -1)
    }
    
    
    private func sendMessage() {
        guard !current_input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return } // Exit if input field is empty
        
       
        let input = current_input
        let sourceToUse = selected_source
        current_input = "" // Clears input box
        
        let user_message = Message(text: input, role: .user)
        messages.append(user_message) //Add user Message
        
        Task {
            await MainActor.run { sending = true } // Loading indicator
            
            // Backend call
            do {
                var bot_response = try await api_service.getChatbotResponse(
                    userInput: input,
                    userID: self.userID
                )
                //QUote request
                if sourceToUse != "None" {
                if let quoteData = try? await api_service.ReligiousQuote(userInput: input, source: sourceToUse.lowercased()) {
                    let quoteSection = "\n\n\n**The \(quoteData.source) (\(quoteData.chapter)):**\n*\"\(quoteData.quote)\"* "
                    bot_response += quoteSection // append quotes to bot response
                                    }
                                }
                // I was getting //n in the bot response text, this code removes it
                let cleaned = bot_response
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "\n\n", with: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                
                let botMessage = Message(text: cleaned, role: .bot)
                
            // Add message from the backend to the UI
                await MainActor.run {
                    messages.append(botMessage)
                    selected_source = "None" // Reset the book icon after initial run
                }
                //Error Handling
            } catch {
                let errorMessage: String
                if let nsError = error as? NSError {
                    errorMessage = "Server Error (\(nsError.code)): \(nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? "Unknown problem")."
                } else {
                    errorMessage = "Network connection failed. Check server status."
                }
                
                let botMessage = Message(text: errorMessage, role: .bot)
                
                await MainActor.run {
                    messages.append(botMessage)
                }
            }
            
            await MainActor.run { sending = false }
        }
    }
}


// Displays chats as message bubbles
struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            // Moves "user" messages to the right
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) { // User message on right side, bot on left.
                
                Text(LocalizedStringKey(message.text)) //Makes text markdown, allows bold and italized text
                                    .font(.body)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading) // text always starts on left side
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(12)
                                    .background(message.isUser ? Color.blue_color : Color.green_color) //user blue, bot green
                                    .clipShape(bubbleShape(isUser: message.isUser))
              
                
                // Display timestamps of messages
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            //Aligning text bubbles
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading) // messages longer than 300 pixels are moved to a new line
            
            // Moves Bot responses to the left
            if !message.isUser {
                Spacer()
            }
        }
    }
    // Creates rectangular shaped message bubbles
    private func bubbleShape(isUser: Bool) -> some Shape {
        let radius: CGFloat = 15 // 15 pixels for rounded corners
        return UnevenRoundedRectangle(
            topLeadingRadius: radius, //15 pixels for top-left corner
            bottomLeadingRadius: isUser ? radius : 5, //If bot, make bottom left corner 5 pixels
            bottomTrailingRadius: isUser ? 5 : radius,// If user, make bottom right corner 5 pixels
            topTrailingRadius: radius
        )
    }
}






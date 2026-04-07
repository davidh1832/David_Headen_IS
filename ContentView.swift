
import SwiftUI
import Foundation

// User or Bot
enum MessageRole {
    case user
    case bot
}
// Messages with user id, role, and timestamp of the message
struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let role: MessageRole
    let timestamp: Date = Date()
    
    var isUser: Bool { role == .user }
    
}
//Quotes with chapter and source (Bible, Quran, Torah)
struct QuoteResponse: Codable {
    let quote: String
    let chapter: String
    let source: String
}
//Main Page
// Structure of the container
struct MentalHealthChatbotUI: View {
    
    // Handle requests to python backend
    private let apiService = ChatbotAPI()
    
    // track conversation history with python backend
    private let userID = UUID().uuidString
    
    // holds the array of the chat history
    @State private var messages: [Message] = [
        Message(text: "Hello! My name is Echo, and i'm here to listen and offer support. How are you feeling today?", role: .bot)
    ]
    
    @State private var currentInput: String = "" //state for current user input
    @State private var isSending = false // Loading indicator
    @State private var selectedSource: String = "None" //default source to none
    private let sources = ["None", "Bible", "Quran", "Torah"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Main Chat Scrolling Area
                chatHistory
                    .background(Color(.systemGray6))
                
                // Input Bar
                inputBar
            }
            // Header Area
            .navigationTitle("Chat with Echo")
            .navigationBarTitleDisplayMode(.inline)
            //.toolbarBackground(Color(hex: "4F9D9D"), for: .navigationBar) green
            .toolbarBackground(Color(hex: "63C8F2"), for: .navigationBar) //light blue, AI generated hex color
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
    
    // Previous Chats
    //Allows scrolling and loops through message array to view all previous chats
    private var chatHistory: some View {
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
                        Picker("Select Source", selection: $selectedSource) {
                            ForEach(sources, id: \.self) { source in
                                Text(source).tag(source)
                            }
                        }
                    // Book icon for religious quotes
                    } label: {
                        Image(systemName: "book.closed.fill") // AI generated book image
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedSource == "None" ? .gray : Color(hex: "06D6A0")) // Green when active, AI generated hex color
                    }
                    .padding(.bottom, 4)
            TextField("Type your message...", text: $currentInput, axis: .vertical)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .lineLimit(1...5) // As the user types, if the number of lines exceeds 5, scrolling in input bar occurs
            // Send Button
            if isSending {
                ProgressView() //API loading
                    .frame(width: 32, height: 32)
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill") // AI generated image
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(currentInput.isEmpty ? Color(.systemGray) : Color(hex: "63C8F2"))
                }
                // Send button is disabled if text field is empty
                .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        // Fitting input bar into container
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: Color(.systemGray4).opacity(0.5), radius: 3, x: 0, y: -1)// Seperates input from chat history
    }
    
    //Calling Backend
    private func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return } // Exit if input field is empty
        
       
        let userMessageText = currentInput
        let sourceToUse = selectedSource
        currentInput = "" // Clears input box
        
        let userMessage = Message(text: userMessageText, role: .user)
        messages.append(userMessage) //Add user Message
        
        Task {
            await MainActor.run { isSending = true } // Loading indicator
            
            // Backend call
            do {
                var botResponseText = try await apiService.getChatbotResponse(
                    userInput: userMessageText,
                    userID: self.userID
                )
                //QUote request
                if sourceToUse != "None" {
                if let quoteData = try? await apiService.getReligiousQuote(userInput: userMessageText, source: sourceToUse.lowercased()) {
                    let quoteSection = "\n\n\n**The \(quoteData.source) (\(quoteData.chapter)):**\n*\"\(quoteData.quote)\"* "
                    botResponseText += quoteSection // append quotes to bot response
                                    }
                                }
                // I was getting //n in the bot response text, this code removes it
                let cleaned = botResponseText
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "\n\n", with: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                
                let botMessage = Message(text: cleaned, role: .bot)
                
            // Add message from the backend to the UI
                await MainActor.run {
                    messages.append(botMessage)
                    selectedSource = "None" // Reset the book icon after initial run
                }
                //Error Handling
            } catch {
                let errorMessage: String
                if let nsError = error as? NSError {
                    errorMessage = "Server Error (\(nsError.code)): \(nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? "Unknown issue")."
                } else {
                    errorMessage = "Network connection failed. Check server status and IP address."
                }
                
                let botMessage = Message(text: errorMessage, role: .bot)
                
                await MainActor.run {
                    messages.append(botMessage)
                }
            }
            
            await MainActor.run { isSending = false }
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
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) { // User message on right side, bot on left. 4 pixel gap between message and timestamp.
                
                Text(LocalizedStringKey(message.text)) //Makes text markdown, allows bold and italized text
                                    .font(.body)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading) // text always starts on left side
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(12) 
                                    .background(message.isUser ? Color(hex: "63C8F2") : Color(hex: "06D6A0")) //user blue, bot green
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
            bottomLeadingRadius: isUser ? radius : 5, //If bot, make bottom left corner 5 pixels to create the tail
            bottomTrailingRadius: isUser ? 5 : radius,// If user, make bottom right corner 5 pixels to create the tail
            topTrailingRadius: radius
        )
    }
}
#Preview {
    MentalHealthChatbotUI()
}






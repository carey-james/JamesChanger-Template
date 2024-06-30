//
//  ContentView.swift
//  JamesChanger Template
//
//  Created by James Carey on 6/30/24.
//

// Imports
import SwiftUI
import AVFoundation

// Setup for playing audio
var audioPlayer: AVAudioPlayer?

// Setup slide struct
struct Slide: Codable, Equatable {
    let question: String
    let image: String?
    let option_a: String?
    let option_b: String?
    let option_c: String?
    let option_d: String?
    let answer: String?
    let audio: String?
}

// Main ContentView struct
struct ContentView: View {
    // Indexes and containers for slides
    @State private var currentIndex = 0
    @State private var currentMainIndex = 0
    @State private var slides = [Slide]()
    @State private var specialSlides = [Slide]()
    // Flags
    @State private var showAnswer = false
    @State private var showingSpecialSlide = false
    @State private var showSplashScreen = true

    var body: some View {
        VStack {
            if slides.isEmpty {
                Text("Loading...")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    if !showAnswer {
                        if showingSpecialSlide {
                            slideContent(for: specialSlides[currentIndex])
                        } else {
                            slideContent(for: slides[currentMainIndex])
                        }
                    } else {
                        if let answer = slides[currentMainIndex].answer {
                            Text(answer)
                                .font(.custom("Trade Gothic LT Std", size: 72))
                                .fontWidth(.condensed)
                                .baselineOffset(-10)
                                .fontWeight(.bold)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(100)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadSlides()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyEvent(event)
                return nil // Prevent key press feedback
            }
        }
        .background(Color.white)
        .foregroundStyle(Color.black)
    }
    
    private func slideContent(for slide: Slide) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let imageName = slide.image {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                Text(slide.question)
                    .font(.custom("Trade Gothic LT Std", size: 72))
                    .fontWidth(.condensed)
                    .baselineOffset(-10)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                
                if !showAnswer {
                    if let optionA = slide.option_a {
                        Text("A: \(optionA)")
                            .font(.custom("Trade Gothic LT Std", size: 52))
                            .fontWidth(.condensed)
                            .baselineOffset(-10)
                            .fontWeight(.bold)
                            .padding(.leading) // Left justify with padding
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let optionB = slide.option_b {
                        Text("B: \(optionB)")
                            .font(.custom("Trade Gothic LT Std", size: 52))
                            .fontWidth(.condensed)
                            .baselineOffset(-10)
                            .fontWeight(.bold)
                            .padding(.leading) // Left justify with padding
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let optionC = slide.option_c {
                        Text("C: \(optionC)")
                            .font(.custom("Trade Gothic LT Std", size: 52))
                            .fontWidth(.condensed)
                            .baselineOffset(-10)
                            .fontWeight(.bold)
                            .padding(.leading) // Left justify with padding
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let optionD = slide.option_d {
                        Text("D: \(optionD)")
                            .font(.custom("Trade Gothic LT Std", size: 52))
                            .fontWidth(.condensed)
                            .baselineOffset(-10)
                            .fontWeight(.bold)
                            .padding(.leading) // Left justify with padding
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func loadSlides() {
        guard let fileURL = Bundle.main.url(forResource: "slides", withExtension: "json") else {
            print("File not found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedData = try JSONDecoder().decode([String: [String: Slide]].self, from: data)
            
            // Load main slides and sort them by their keys
            let mainSlides = (decodedData["main_slides"] ?? [:]).sorted { Int($0.key)! < Int($1.key)! }.map { $0.value }
            self.slides = mainSlides
            
            // Load special slides and sort them by their keys
            let specialSlides = (decodedData["special_slides"] ?? [:]).sorted { Int($0.key)! < Int($1.key)! }.map { $0.value }
            self.specialSlides = specialSlides
            
        } catch {
            print("Error reading JSON file:", error)
        }
    }

    func playAudio(_ assetName : String) {
        guard let audioData = NSDataAsset(name: assetName)?.data else {
            fatalError("Unable to find asset \(assetName)")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func advanceToNextQuestion() {
        if showingSpecialSlide {
            if currentIndex < specialSlides.count - 1 {
                currentIndex += 1
            } else {
                showSplashScreen = true // Show the splash screen instead of looping
            }
        } else {
            if currentMainIndex < slides.count - 1 {
                currentMainIndex += 1
                // Check if the current slide has audio and play it if available
                if let audioFileName = slides[currentMainIndex].audio {
                    playAudio(audioFileName)
                }
            } else {
                showSplashScreen = true // Show the splash screen instead of looping
            }
        }
        showAnswer = false // Reset to hide answer when moving to the next question
    }
    
    func moveToPreviousSlide() {
        if showingSpecialSlide {
            if currentIndex > 0 {
                currentIndex -= 1
            }
        } else {
            if currentMainIndex > 0 {
                currentMainIndex -= 1
            }
        }
        showAnswer = false // Reset to hide answer when moving to the previous slide
        showSplashScreen = false // Ensure splash screen is hidden
    }
    
    func toggleShowAnswer() {
        if slides[currentMainIndex].answer != nil {
            showAnswer.toggle()
        }
    }
    
    func handleKeyEvent(_ event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers else { return }
        switch characters {
        case "q":
            advanceToNextQuestion()
            showingSpecialSlide = false // Reset to main slides after moving to next question
            showSplashScreen = false // Hide the splash screen
        case "a":
            toggleShowAnswer()
        case "1", "2", "3", "4", "5", "6", "7", "8", "9": // Check for number keys
            showSpecialSlide(forKey: characters)
        case "\u{8}", "\u{7F}": // Handle delete/backspace key
                moveToPreviousSlide()
        default:
            break
        }
    }
    
    func showSpecialSlide(forKey key: String) {
        playAudio("Alarm")
        let keyIndex = Int(key)! - 1 // Convert key to array index (zero-based)
        if keyIndex < specialSlides.count {
            currentIndex = keyIndex
            showingSpecialSlide = true // Set flag to indicate special slide is being shown
            showAnswer = false // Reset to hide answer when showing special slide
        }
    }
}

// Preview for XCode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#Preview {
    ContentView()
}

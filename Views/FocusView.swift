import SwiftUI

struct FocusView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedTask: Task?
    @State private var focusTime: TimeInterval = 25 * 60 // 25 minutes by default
    @State private var isTimerRunning = false
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingTime / focusTime))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text(timeString(from: remainingTime))
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let task = selectedTask {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Select a task to focus on")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Control Buttons
                HStack(spacing: 30) {
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: toggleTimer) {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        // Skip to next task or break
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                // Task Selection
                VStack(alignment: .leading, spacing: 15) {
                    Text("Select a task to focus on:")
                        .font(.headline)
                    
                    List {
                        ForEach(taskStore.getIncompleteTasks()) { task in
                            Button(action: {
                                selectedTask = task
                                resetTimer()
                            }) {
                                HStack {
                                    Text(task.title)
                                    
                                    Spacer()
                                    
                                    if selectedTask?.id == task.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(minHeight: 200)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Focus")
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                // Handle timer completion here
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        remainingTime = focusTime
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusView_Previews: PreviewProvider {
    static var previews: some View {
        FocusView()
            .environmentObject(TaskStore())
    }
} 
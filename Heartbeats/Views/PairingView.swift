import SwiftUI

/// View for pairing with another user via connection code
struct PairingView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    @State private var connectionCode: String = ""
    @State private var myConnectionCode: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // My Connection Code Section
                VStack(spacing: 12) {
                    Text("Your Code")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if myConnectionCode.isEmpty {
                        Button("Generate Code") {
                            Task {
                                await generateMyCode()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isLoading)
                    } else {
                        Text(myConnectionCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(4)
                            .onTapGesture(count: 2) {
                                Task {
                                    myConnectionCode = ""
                                    await generateMyCode()
                                }
                            }

                        Text("Share with partner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                Divider()
                    .padding(.horizontal)

                // Enter Partner's Code Section
                VStack(spacing: 12) {
                    // Code display
                    Text(connectionCode.isEmpty ? "------" : formatCode(connectionCode))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(4)
                        .frame(height: 36)
                        .animation(.easeInOut(duration: 0.1), value: connectionCode)

                    // Numpad
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(1...9, id: \.self) { number in
                            Button(action: { addDigit(String(number)) }) {
                                Text("\(number)")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray5))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(connectionCode.count >= 6 || isLoading)
                        }
                        
                        // Delete button
                        Button(action: { deleteDigit() }) {
                            Image(systemName: "delete.left.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.15))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(connectionCode.isEmpty || isLoading)
                        
                        // Zero
                        Button(action: { addDigit("0") }) {
                            Text("0")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(connectionCode.count >= 6 || isLoading)
                        
                        // Connect button
                        Button(action: { Task { await pairWithPartner() } }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    connectionCode.count == 6 ?
                                    LinearGradient(
                                        colors: [.green, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [.gray, .gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .buttonStyle(PlainButtonStyle())
                        .disabled(connectionCode.count != 6 || isLoading)
                    }
                    .padding(.horizontal, 8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Pair")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully paired with your partner!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func formatCode(_ code: String) -> String {
        let padded = code.padding(toLength: 6, withPad: "-", startingAt: 0)
        return padded
    }
    
    private func addDigit(_ digit: String) {
        guard connectionCode.count < 6 else { return }
        connectionCode += digit
    }
    
    private func deleteDigit() {
        guard !connectionCode.isEmpty else { return }
        connectionCode.removeLast()
    }

    // MARK: - Methods
    private func generateMyCode() async {
        isLoading = true
        myConnectionCode = await firebaseService.getOrGenerateConnectionCode()
        isLoading = false
    }

    private func pairWithPartner() async {
        guard connectionCode.count == 6 else { return }
        
        isLoading = true

        firebaseService.pairWithUser(code: connectionCode, name: "Partner") { success in
            isLoading = false

            if success {
                showSuccessAlert = true
            } else {
                errorMessage = "Could not find a user with that connection code. Please check and try again."
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    PairingView()
        .environmentObject(FirebaseService.shared)
}

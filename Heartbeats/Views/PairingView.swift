import SwiftUI

/// View for pairing with another user via connection code
struct PairingView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    @State private var connectionCode: String = ""
    @State private var partnerName: String = ""
    @State private var myConnectionCode: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon/Logo
                    Image(systemName: "heart.beat.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 40)

                    Text("Heartbeats")
                        .font(.title)
                        .fontWeight(.bold)

                    // My Connection Code Section
                    VStack(spacing: 15) {
                        Text("Your Connection Code")
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
                        } else {
                            Text(myConnectionCode)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(15)
                                .onTapGesture(count: 2) {
                                    // Double tap to regenerate
                                    Task {
                                        myConnectionCode = ""
                                        await generateMyCode()
                                    }
                                }

                            Text("Share this code with your partner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                    Divider()

                    // Enter Partner's Code Section
                    VStack(spacing: 20) {
                        Text("Enter Partner's Code")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        TextField("6-character code", text: $connectionCode)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .textCase(.uppercase)
                            .onChange(of: connectionCode) { _, newValue in
                                connectionCode = String(newValue.prefix(6)).uppercased()
                            }

                        TextField("Partner's name", text: $partnerName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)

                        Button {
                            Task {
                                await pairWithPartner()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Connect")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(connectionCode.count != 6 || partnerName.isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Pair")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully paired with \(partnerName)!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Methods
    private func generateMyCode() async {
        isLoading = true
        myConnectionCode = await firebaseService.getOrGenerateConnectionCode()
        isLoading = false
    }

    private func pairWithPartner() async {
        isLoading = true

        firebaseService.pairWithUser(code: connectionCode, name: partnerName) { success in
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

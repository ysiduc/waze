import SwiftUI

public struct SearchSheetView: View {
    @ObservedObject var searchService: SearchService
    let onSelectDestination: (SearchResult) -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(searchService: SearchService, onSelectDestination: @escaping (SearchResult) -> Void) {
        self.searchService = searchService
        self.onSelectDestination = onSelectDestination
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search address, place, or landmark", text: $searchService.query)
                        .autocorrectionDisabled()
                    if !searchService.query.isEmpty {
                        Button(action: { searchService.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                if searchService.isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if let error = searchService.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if searchService.searchResults.isEmpty && !searchService.query.isEmpty {
                    Text("No results found.")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(searchService.searchResults) { result in
                        Button(action: {
                            onSelectDestination(result)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

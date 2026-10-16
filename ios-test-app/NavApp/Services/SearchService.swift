import Foundation
import MapKit
import Combine

public class SearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published public var query: String = ""
    @Published public var searchResults: [SearchResult] = []
    @Published public var isSearching: Bool = false
    @Published public var errorMessage: String?
    
    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newQuery in
                guard let self = self else { return }
                if newQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.searchResults = []
                } else {
                    self.searchPlaces(query: newQuery)
                }
            }
            .store(in: &cancellables)
    }
    
    public func searchPlaces(query: String, region: MKCoordinateRegion? = nil) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isSearching = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let response = response else {
                    self.searchResults = []
                    return
                }
                self.searchResults = response.mapItems.map { SearchResult.fromMKMapItem($0) }
            }
        }
    }
    
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Can be used for autocomplete query strings
    }
    
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}

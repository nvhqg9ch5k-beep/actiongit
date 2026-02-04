import Foundation
import Combine

enum ResolverOutcome: Equatable {
    case success
    case error(Error)
    case loading
    case throttled

    static func == (lhs: ResolverOutcome, rhs: ResolverOutcome) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success),
            (.loading, .loading),
            (.throttled, .throttled):
            return true
        case (.error(let a), .error(let b)):
            return (a as NSError) == (b as NSError)
        default:
            return false
        }
    }
}

struct EndpointPayload: Codable {
    let url: String?
}

final class RemoteEndpointResolver: ObservableObject {
    static let shared = RemoteEndpointResolver()

    private let endpointAddress = "https://url-server-money-ritual-builder-production.up.railway.app/"

    private init() {}

    func resolveDestination() async -> (url: String?, state: ResolverOutcome) {
        guard let endpoint = URL(string: endpointAddress) else {
            let err = NSError(
                domain: "RemoteEndpointResolver",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid configuration URL"]
            )
            return (nil, .error(err))
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.timeoutInterval = 10
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            guard let http = response as? HTTPURLResponse else {
                let err = NSError(
                    domain: "RemoteEndpointResolver",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]
                )
                return (nil, .error(err))
            }

            if http.statusCode == 429 {
                return (nil, .throttled)
            }

            guard (200...299).contains(http.statusCode) else {
                let err = NSError(
                    domain: "RemoteEndpointResolver",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(http.statusCode)"]
                )
                return (nil, .error(err))
            }

            let decoder = JSONDecoder()
            let payload = try decoder.decode(EndpointPayload.self, from: data)

            if let link = payload.url, !link.isEmpty {
                return (link, .success)
            } else {
                return (nil, .success)
            }

        } catch let decodingError as DecodingError {
            let err = NSError(
                domain: "RemoteEndpointResolver",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON: \(decodingError.localizedDescription)"]
            )
            return (nil, .error(err))
        } catch {
            return (nil, .error(error))
        }
    }
}

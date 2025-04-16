import ArgumentParser
import Foundation
import SwiftArmcknight

struct UltimateGuitar: ParsableCommand {
    @Argument(help: "The URL of the tab to scrape.")
    var tabURL: String

    @Argument(help: "The base path where tabs are saved.")
    var path: String

    private var urlSession: URLSession { URLSession(configuration: .default) }
}

extension UltimateGuitar {
    enum Error: Swift.Error {
        case decodingResponseDataFailed
        case convertingContentToDataFailed
        case jsonObjectOfUnexpectedType
        case fileExistsWhereDirectoryNeedsToBeCreated
    }

    struct UGTab: Codable {
        struct Store: Codable {
            struct Page: Codable {
                struct Data: Codable {
                    struct Tab: Codable {
                        var artist_name: String
                        var song_name: String
                    }
                    struct TabView: Codable {
                        struct WikiTab: Codable {
                            var content: String
                        }
                        var wiki_tab: WikiTab
                    }
                    var tab_view: TabView
                    var tab: Tab
                }
                var data: Data
            }
            var page: Page
        }
        var store: Store
    }

    func run() throws {
        guard let url = URL(string: tabURL) else {
            return
        }
        switch synchronouslyRequest(request: URLRequest(url: url)) {
        case .failure(let error): fatalError(String(describing: error))
        case .success(let data):
            guard let html = String(data: data, encoding: .utf8) else { throw Error.decodingResponseDataFailed }
            let dataContent = html.substring(from: "data-content=\"", to: "\"")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#039;", with: "'")
                .replacingOccurrences(of: "&mdash;", with: "–")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")

            guard let dataForJSONDecoding = dataContent.data(using: .utf8) else { throw Error.convertingContentToDataFailed }
            let tab = try JSONDecoder().decode(UGTab.self, from: dataForJSONDecoding)
            let tabContent = tab.store.page.data.tab_view.wiki_tab.content
                .replacingOccurrences(of: "[tab]", with: "\n")
                .replacingOccurrences(of: "[/tab]", with: "\n")
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\n\n\n\n\n\n", with: "\n\n")
                .replacingOccurrences(of: "\n\n\n\n\n", with: "\n\n")
                .replacingOccurrences(of: "\n\n\n\n", with: "\n\n")
                .replacingOccurrences(of: "\n\n\n", with: "\n\n")

            let artistDirectory = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).appendingPathComponent(tab.store.page.data.tab.artist_name)
            var isDirectory: ObjCBool = false
            if !FileManager.default.fileExists(atPath: artistDirectory.absoluteString, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: artistDirectory, withIntermediateDirectories: true)
            } else if !isDirectory.boolValue {
                throw Error.fileExistsWhereDirectoryNeedsToBeCreated
            }
            let fileURL = artistDirectory.appendingPathComponent(tab.store.page.data.tab.song_name).appendingPathExtension("txt")
            try tabContent.write(to: fileURL, atomically: false, encoding: .utf8)
        }

    }
}

private extension UltimateGuitar {
    enum RequestError: Swift.Error, CustomStringConvertible {
        case clientError(Swift.Error)
        case httpError(URLResponse)
        case noData
        case invalidData
        case resultError

        public var description: String {
            switch self {
            case .clientError(let error): return "Request failed in client stack with error: \(error)."
            case .httpError(let response): return "Request failed with HTTP status \((response as! HTTPURLResponse).statusCode)."
            case .noData: return "Response contained no data."
            case .invalidData: return "Response data couldn't be decoded."
            case .resultError: return "The request completed successfully but a problem occurred returning the decoded response."
            }
        }
    }

     func synchronouslyRequest(request: URLRequest) -> Result<Data, RequestError> {
        var result: Data?
        var requestError: RequestError?

        let group = DispatchGroup()
        group.enter()
        urlSession.dataTask(with: request) { data, response, error in
            defer {
                group.leave()
            }

            guard error == nil else {
                requestError = RequestError.clientError(error!)
                return
            }

            let status = (response as! HTTPURLResponse).statusCode

            guard status >= 200 && status < 300 else {
                requestError = RequestError.httpError(response!)
                return
            }

            guard let data else {
                requestError = RequestError.noData
                return
            }

            result = data
        }.resume()
        group.wait()

        if let requestError {
            return .failure(requestError)
        }

        guard let result else {
            return .failure(RequestError.resultError)
        }

        return .success(result)
    }
}

import ArgumentParser
import Foundation

struct IndieGuitarTabs: ParsableCommand {
    @Argument(help: "The URL of the tab to scrape.")
    var url: String

    @Argument(help: "The base path where output is saved.")
    var path: String
}

extension IndieGuitarTabs {
    func run() throws {
        
        // original code to adapt:
        let session = URLSession(configuration: .default)

        let contents = try! String(contentsOfFile: "/Users/andrew/Library/Mobile Documents/com~apple~CloudDocs/Library/Guitar/_scraping/indieguitartabs_webarchive_sufjan_stevens_clean.txt", encoding: String.Encoding.utf8)
        contents.split(separator: "\n").forEach { line in
            let elements = line.split(separator: "|")
            let title = String(elements.first!)
            let url = String(elements.last!)

            let semaphore = DispatchSemaphore(value: 1)
            print("downloading")
            let task = session.dataTask(with: URL(string: url)!) { (data, response, error) in
                let newURL = (response as! HTTPURLResponse).allHeaderFields["location"] as! String
                let newTask = session.dataTask(with: URL(string: newURL)!) { (newData, newResponse, newError) in
                    let html = String(data: newData!, encoding: String.Encoding.utf8)!
                    let firstPreTag = (html as NSString).range(of: "<pre>")
                    let firstPreTagClose = (html as NSString).range(of: "</pre>")
                    let rangeStart = firstPreTag.location + firstPreTag.length
                    let tabRange = NSMakeRange(rangeStart, firstPreTagClose.location - rangeStart)
                    let tabContents = (html as NSString).substring(with: tabRange)
                    try! tabContents.write(toFile: "/Users/andrew/Library/Mobile Documents/com~apple~CloudDocs/Library/Guitar/_scraping/\(title).txt", atomically: true, encoding: String.Encoding.utf8)
                    print("done")
                    semaphore.signal()
                }
                newTask.resume()
            }
            task.resume()
            semaphore.wait()
        }
    }
}

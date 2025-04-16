import ArgumentParser
import Foundation

struct WWDC: ParsableCommand {
    @Argument(help: "The URL of the WWDC session to scrape.")
    var url: String

    @Argument(help: "The base path where output is saved.")
    var path: String
}

extension WWDC {

}

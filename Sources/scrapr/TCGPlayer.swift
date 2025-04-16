import ArgumentParser
import Foundation

struct TCGPlayer: ParsableCommand {
    @Argument(help: "The URL of the card to scrape.")
    var url: String

    @Argument(help: "The base path where output is saved.")
    var path: String
}

extension TCGPlayer {

}

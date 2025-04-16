#!/usr/bin/env swift

import Foundation
import ArgumentParser

struct Scrapr: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [UltimateGuitar.self, WWDC.self, IndieGuitarTabs.self, TCGPlayer.self])
}

Scrapr.main()

import Foundation
import Testing
@testable import SkyJump

@MainActor
struct RadioStationMapperTests {

    /// Скорочена відповідь Radio Browser: робоча станція, дубль, http-потік, OGG і непройдена перевірка.
    private let json = """
    [
      {"stationuuid": "a", "name": "Neon FM", "url": "http://neon.example/stream",
       "url_resolved": "https://neon.example/stream.mp3", "country": "United States", "countrycode": "us",
       "tags": "Synthwave, 80s,  retro", "favicon": "https://neon.example/logo.png",
       "codec": "MP3", "bitrate": 128, "lastcheckok": 1, "clickcount": 50},
      {"stationuuid": "b", "name": "neon fm ", "url": "https://copy.example/stream",
       "codec": "MP3", "lastcheckok": 1, "clickcount": 10},
      {"stationuuid": "c", "name": "Plain HTTP", "url": "http://plain.example/stream",
       "codec": "MP3", "lastcheckok": 1, "clickcount": 90},
      {"stationuuid": "d", "name": "Ogg Waves", "url": "https://ogg.example/stream",
       "codec": "OGG", "lastcheckok": 1, "clickcount": 80},
      {"stationuuid": "e", "name": "Broken", "url": "https://broken.example/stream",
       "codec": "AAC", "lastcheckok": 0, "clickcount": 70},
      {"stationuuid": "f", "name": "Palm AAC", "url": "https://palm.example/stream",
       "favicon": "http://palm.example/logo.png", "codec": "AAC", "lastcheckok": 1, "clickcount": 20}
    ]
    """

    private func decode() throws -> [RadioBrowserStationDTO] {
        try JSONDecoder().decode([RadioBrowserStationDTO].self, from: Data(json.utf8))
    }

    @Test func keepsOnlyPlayableUniqueStations() throws {
        let stations = RadioStationMapper().map(try decode())

        #expect(stations.map(\.id) == ["a", "f"])   // за популярністю, без дубля, http, OGG і зламаної
    }

    @Test func mapsFields() throws {
        let station = try #require(RadioStationMapper().map(try decode()).first)

        #expect(station.streamURL.absoluteString == "https://neon.example/stream.mp3")
        #expect(station.tags == ["synthwave", "80s", "retro"])
        #expect(station.countryCode == "US")
        #expect(station.flag == "🇺🇸")
        #expect(station.bitrate == 128)
        #expect(station.faviconURL != nil)
    }

    @Test func insecureFaviconIsDropped() throws {
        let palm = try #require(RadioStationMapper().map(try decode()).last)
        #expect(palm.faviconURL == nil)
    }

    @Test func requestAsksForGenreSortedByPopularity() throws {
        let client = URLSessionHTTPClient(baseURL: URL(string: "https://de1.api.radio-browser.info")!)
        let request = try #require(client.makeURLRequest(RadioBrowserClient(clients: []).request(tag: "synthwave")))
        let url = request.url?.absoluteString ?? ""

        #expect(url.hasPrefix("https://de1.api.radio-browser.info/json/stations/bytag/synthwave"))
        #expect(url.contains("hidebroken=true"))
        #expect(url.contains("order=clickcount"))
        #expect(url.contains("limit=25"))
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "SkyJump/1.0")
    }
}

@MainActor
struct RadioPlayerTests {

    private func makePlayer() -> (RadioPlayer, SpyStreamer, UserDefaults) {
        let defaults = UserDefaults(suiteName: "tests.radio.\(UUID().uuidString)")!
        let streamer = SpyStreamer()
        return (RadioPlayer(streamer: streamer, defaults: defaults), streamer, defaults)
    }

    @Test func playRemembersStation() {
        let (player, streamer, defaults) = makePlayer()
        let station = StubRadioProvider.stations[0]

        player.play(station)

        #expect(player.current == station)
        #expect(player.state == .playing)
        #expect(streamer.playedURLs == [station.streamURL])

        // новий програвач з тим самим сховищем пам'ятає останню станцію, але сам не вмикається
        let restored = RadioPlayer(streamer: SpyStreamer(), defaults: defaults)
        #expect(restored.current == station)
        #expect(restored.state == .idle)
    }

    @Test func nextCyclesThroughQueue() {
        let (player, _, _) = makePlayer()
        let stations = StubRadioProvider.stations
        player.setQueue(stations)

        player.playNext()
        #expect(player.current == stations[0])
        player.play(stations[2])
        player.playNext()
        #expect(player.current == stations[0])   // по колу
    }

    @Test func toggleStopsAndResumes() {
        let (player, streamer, _) = makePlayer()
        player.play(StubRadioProvider.stations[1])

        player.toggle()
        #expect(player.state == .idle)
        #expect(streamer.stopCount == 1)

        player.toggle()
        #expect(player.state == .playing)
        #expect(streamer.playedURLs.count == 2)
    }

    @Test func duckingLowersChosenVolume() {
        let (player, streamer, _) = makePlayer()
        player.setVolume(0.5)
        player.play(StubRadioProvider.stations[0])
        #expect(streamer.volume == 0.5)

        player.setDucked(true)
        #expect(streamer.volume == 0.5 * RadioPlayer.duckFactor)

        player.setDucked(false)
        #expect(streamer.volume == 0.5)
    }

    @Test func volumeIsClampedAndRemembered() {
        let (player, streamer, defaults) = makePlayer()
        #expect(player.volume == RadioPlayer.defaultVolume)

        player.setVolume(1.7)
        #expect(player.volume == 1)
        #expect(streamer.volume == 1)

        player.setVolume(0.3)
        let restored = RadioPlayer(streamer: SpyStreamer(), defaults: defaults)
        #expect(restored.volume == 0.3)
    }
}

@MainActor
struct RadioViewModelTests {

    private func makePlayer() -> RadioPlayer {
        RadioPlayer(streamer: SpyStreamer(),
                    defaults: UserDefaults(suiteName: "tests.radio.\(UUID().uuidString)")!)
    }

    @Test func loadShowsStationsAndFillsQueue() async {
        let player = makePlayer()
        let viewModel = RadioViewModel(provider: StubStationsProvider(result: .success(StubRadioProvider.stations)),
                                       player: player)

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.stations.count == 3)
        #expect(player.queue.count == 3)
    }

    @Test func networkErrorShowsMessage() async {
        let viewModel = RadioViewModel(provider: StubStationsProvider(result: .failure(URLError(.notConnectedToInternet))),
                                       player: makePlayer())

        await viewModel.load()

        guard case .failed(let message) = viewModel.loadState else {
            Issue.record("Очікувався стан помилки")
            return
        }
        #expect(message.contains("інтернету"))
    }

    @Test func genreFilter() async {
        let viewModel = RadioViewModel(provider: StubStationsProvider(result: .success(StubRadioProvider.stations)),
                                       player: makePlayer())
        await viewModel.load()

        viewModel.selectedGenre = .vaporwave
        #expect(viewModel.visibleStations.map(\.id) == ["stub-3"])

        viewModel.selectedGenre = nil
        #expect(viewModel.visibleStations.count == 3)
    }

    @Test func selectingCurrentStationStopsIt() async {
        let player = makePlayer()
        let viewModel = RadioViewModel(provider: StubStationsProvider(result: .success(StubRadioProvider.stations)),
                                       player: player)
        await viewModel.load()
        let station = viewModel.stations[0]

        viewModel.select(station)
        #expect(player.state == .playing)
        viewModel.select(station)
        #expect(player.state == .idle)
    }

    @Test func alreadyLoadedQueueSkipsNetwork() {
        let player = makePlayer()
        player.setQueue(StubRadioProvider.stations)

        let viewModel = RadioViewModel(provider: StubStationsProvider(result: .failure(URLError(.timedOut))),
                                       player: player)

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.stations.count == 3)
    }
}

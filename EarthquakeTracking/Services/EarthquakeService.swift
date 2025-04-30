import Foundation

class EarthquakeService {
    static let shared = EarthquakeService()
    
    private let urlString = "http://localhost:5001/earthquakes"

    func fetchEarthquakes(completion: @escaping ([Earthquake]?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received.")
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let earthquakes = try decoder.decode([Earthquake].self, from: data)
                completion(earthquakes)
            } catch {
                print("Error decoding: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }
}

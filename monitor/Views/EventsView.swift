import SwiftUI

// Debug structures for events API testing
struct EventDebug: Identifiable, Codable {
    let id: Int
    let uuid: String
    let title: String
    let summary: String
    let status: String
    let created_at: String
    let updated_at: String
    let posts_count: Int
    
    var formattedCreatedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) else { return created_at }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    var statusColor: String {
        switch status.lowercased() {
        case "open": return "#10b981"
        case "archived": return "#6b7280"
        case "dismissed": return "#ef4444"
        default: return "#8b5cf6"
        }
    }
}

struct EventsResponseDebug: Codable {
    let events: [EventDebug]
    let total: Int
}

class EventsServiceDebug: ObservableObject {
    @Published var events: [EventDebug] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchEvents() {
        print("🔄 Starting Events API fetch...")
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://api.monitor.gaulatti.com/events") else {
            print("❌ Invalid URL")
            isLoading = false
            return
        }
        
        print("🔄 Fetching from: \(url.absoluteString)")
        let decoder = JSONDecoder()
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                print("📡 Headers: \(httpResponse.allHeaderFields)")
            }
            
            if let error = error {
                print("❌ Network Error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No data received"
                }
                return
            }
            
            print("📊 Received \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(500))
                print("📄 Response preview: \(preview)")
            }
            
            // Try to parse as JSON first
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ Successfully parsed as JSON")
                    print("🔍 Top-level keys: \(jsonObject.keys.sorted())")
                    
                    if let events = jsonObject["events"] as? [[String: Any]] {
                        print("📊 Found 'events' array with \(events.count) items")
                        if let firstEvent = events.first {
                            print("🎯 First event keys: \(firstEvent.keys.sorted())")
                        }
                    }
                    
                    if let total = jsonObject["total"] {
                        print("📊 Total: \(total)")
                    }
                }
                
                // Now try to decode with our structures
                let response = try decoder.decode(EventsResponseDebug.self, from: data)
                print("✅ Successfully decoded \(response.events.count) events")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.events = response.events
                }
                
            } catch {
                print("❌ Decoding error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct EventsView: View {
    @StateObject private var eventsService = EventsServiceDebug()
    @State private var selectedEvent: EventDebug?
    @State private var showingEventDetail = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.10), // #0f1419
                        Color(red: 0.10, green: 0.12, blue: 0.18)  // #1a1f2e
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    EventsHeaderView(
                        eventCount: eventsService.events.count,
                        isLoading: eventsService.isLoading
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if eventsService.isLoading && eventsService.events.isEmpty {
                        // Loading state
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("Loading events...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else if let errorMessage = eventsService.errorMessage {
                        // Error state
                        VStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Error loading events")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button("Retry") {
                                eventsService.fetchEvents()
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 16)
                            Spacer()
                        }
                    } else if eventsService.events.isEmpty {
                        // Empty state
                        VStack {
                            Spacer()
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No events available")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            Text("Events will appear here when they are created")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                    } else {
                        // Events grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 300), spacing: 16)
                            ], spacing: 16) {
                                ForEach(eventsService.events) { event in
                                    EventCardView(event: event)
                                        .onTapGesture {
                                            selectedEvent = event
                                            showingEventDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Account for tab bar
                        }
                    }
                }
            }
        }
        .onAppear {
            eventsService.fetchEvents()
        }
        // Temporarily commented out until EventDetailView is updated for TempEvent
        /*
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, eventsService: eventsService)
            }
        }
        */
    }
}

struct EventsHeaderView: View {
    let eventCount: Int
    let isLoading: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("EVENTS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("(\(eventCount))")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                }
            }
            
            Spacer()
            
            // Refresh button
            Button(action: {
                // TODO: Add refresh functionality
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }
}

struct EventCardView: View {
    let event: EventDebug
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event header
            eventHeaderSection
            
            // Event summary
            Text(event.summary)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Post count
            eventFooterSection
        }
        .padding(16)
        .background(eventCardBackground)
    }
    
    private var eventHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(event.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Status badge
            Text(event.status.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: event.statusColor) ?? .purple)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }
    
    private var eventFooterSection: some View {
        HStack {
            Image(systemName: "doc.text")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("\(event.posts_count) posts")
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var eventCardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// Color extension for hex colors
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#if DEBUG
struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
    }
}
#endif

import SwiftUI

struct EventDetailView: View {
    let event: Event
    let eventsService: EventsService
    @Environment(\.dismiss) private var dismiss
    @State private var expandedPost: String?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    backgroundGradient
                    mainContent
                }
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.06, green: 0.08, blue: 0.10), // #0f1419
                Color(red: 0.10, green: 0.12, blue: 0.18)  // #1a1f2e
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                eventHeaderView
                postsSection
            }
            .padding(.bottom, 40)
        }
    }
    
    private var eventHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            eventStatusHeader
            
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(event.summary)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            
            postsCountInfo
        }
        .padding(20)
        .background(eventHeaderBackground)
    }
    
    private var eventStatusHeader: some View {
        HStack {
            Text(event.status.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: event.statusColor) ?? .purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            
            Spacer()
            
            Text(event.formattedCreatedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var postsCountInfo: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
            
            Text("\(event.posts_count) posts")
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    private var eventHeaderBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var postsSection: some View {
        Group {
            if let posts = event.posts, !posts.isEmpty {
                postsListView(posts: posts)
            } else {
                emptyPostsView
            }
        }
    }
    
    private func postsListView(posts: [EventPost]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Posts")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ForEach(posts) { post in
                EventPostCardView(
                    post: post,
                    isExpanded: expandedPost == String(post.id)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let postIdString = String(post.id)
                        if expandedPost == postIdString {
                            expandedPost = nil
                        } else {
                            expandedPost = postIdString
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyPostsView: some View {
        VStack {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No posts available")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            Text("Posts related to this event will appear here")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct EventPostCardView: View {
    let post: EventPost
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post header
            HStack(spacing: 12) {
                // Author avatar placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author_name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("@\(post.author_handle)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Score
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("\(post.score)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.yellow)
                }
            }
            
            // Post content
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            // Image preview (if available)
            if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                .frame(maxHeight: isExpanded ? .infinity : 200)
                .clipped()
            }
            
            // Post metadata
            HStack {
                if let url = post.url {
                    Text("External Link")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Post")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(formatPostDate(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if isExpanded {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0, green: 0, blue: 0, opacity: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1, green: 1, blue: 1, opacity: 0.1), lineWidth: 1)
                )
        )
    }
    
    private func formatPostDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatPostDateFromDate(_ date: Date) -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(
            event: Event.mockEvent(),
            eventsService: EventsService()
        )
    }
}
#endif

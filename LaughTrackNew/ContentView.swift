import SwiftUI
import CoreData
import AVKit
import PhotosUI
import WebKit

// MARK: - Video Data Models
struct ComedianVideo: Identifiable, Codable {
    var id = UUID()
    let comedianId: String
    let title: String
    let description: String?
    let duration: TimeInterval
    let thumbnailURL: String
    let playbackURL: String
    let videoType: VideoType
    let uploadDate: Date
    let isPublic: Bool
    
    enum VideoType: String, Codable, CaseIterable {
        case nativeUpload = "native"
        case youtube = "youtube"
        case tiktok = "tiktok"
        case instagram = "instagram"
        
        var displayName: String {
            switch self {
            case .nativeUpload: return "Upload"
            case .youtube: return "YouTube"
            case .tiktok: return "TikTok"
            case .instagram: return "Instagram"
            }
        }
    }
}

// MARK: - Video Upload Service
class VideoUploadService: ObservableObject {
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    func uploadVideo(comedianId: String, title: String, description: String?) async throws -> ComedianVideo {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0
        }
        
        // Simulate upload progress for demo
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                uploadProgress = Double(i) / 10.0
            }
        }
        
        let video = ComedianVideo(
            comedianId: comedianId,
            title: title,
            description: description,
            duration: 45.0,
            thumbnailURL: "https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=300&h=200&fit=crop",
            playbackURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            videoType: .nativeUpload,
            uploadDate: Date(),
            isPublic: true
        )
        
        await MainActor.run {
            isUploading = false
        }
        return video
    }
    
    func addSocialMediaLink(url: String, comedianId: String, platform: ComedianVideo.VideoType) -> ComedianVideo {
        let videoId = extractVideoId(from: url, platform: platform)
        
        return ComedianVideo(
            comedianId: comedianId,
            title: "Comedy Clip",
            description: nil,
            duration: 0,
            thumbnailURL: generateThumbnailURL(videoId: videoId, platform: platform),
            playbackURL: url,
            videoType: platform,
            uploadDate: Date(),
            isPublic: true
        )
    }
    
    private func extractVideoId(from url: String, platform: ComedianVideo.VideoType) -> String {
        switch platform {
        case .youtube:
            if let range = url.range(of: "v=") {
                return String(url[range.upperBound...].prefix(11))
            } else if url.contains("youtu.be/") {
                return String(url.split(separator: "/").last?.prefix(11) ?? "")
            }
        case .tiktok:
            return String(url.split(separator: "/").last?.prefix(19) ?? "")
        case .instagram:
            return String(url.split(separator: "/").dropLast().last ?? "")
        case .nativeUpload:
            break
        }
        return ""
    }
    
    private func generateThumbnailURL(videoId: String, platform: ComedianVideo.VideoType) -> String {
        switch platform {
        case .youtube:
            return "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg"
        case .tiktok, .instagram:
            return "https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=300&h=200&fit=crop"
        case .nativeUpload:
            return ""
        }
    }
}

// MARK: - Supporting Data Models
struct SampleReview {
    let id: Int
    let rating: Int
    let comment: String
    let username: String
}

struct SampleEvent {
    let id: Int
    let title: String
    let venue: String
    let date: Date
    let ticketURL: String
}

// MARK: - Main App Structure
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            BookTalentView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Book Talent")
                }
            
            EventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.orange)
        .preferredColorScheme(.dark)
        .onAppear {
            createSampleComedians()
        }
    }
    
    private func createSampleComedians() {
        let request: NSFetchRequest<Comedian> = Comedian.fetchRequest()
        let count = try? viewContext.count(for: request)
        
        if count ?? 0 < 5 {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Comedian"))
            do {
                try viewContext.execute(deleteRequest)
            } catch {
                print("Error deleting existing comedians: \(error)")
            }
            
            let sampleComedians = [
                ("Sarah Chen", "Rising star in observational comedy with sharp wit about tech life", "San Francisco, CA", "observational"),
                ("Marcus Johnson", "High-energy storyteller mixing personal experiences with social commentary", "Austin, TX", "storytelling"),
                ("Elena Rodriguez", "Quick-witted improviser known for crowd work and spontaneous humor", "Brooklyn, NY", "improv"),
                ("Jake Thompson", "Political satirist with a knack for making complex issues hilarious", "Chicago, IL", "political"),
                ("Amy Park", "Stand-up comedian specializing in millennial struggles and dating disasters", "Los Angeles, CA", "standup"),
                ("Carlos Mendez", "Storytelling comedian sharing tales from his family's restaurant business", "Miami, FL", "storytelling"),
                ("Rachel Kim", "Observational comedian finding humor in everyday awkward situations", "Seattle, WA", "observational"),
                ("Tony Ricci", "Improv veteran bringing spontaneous laughs to any crowd", "Boston, MA", "improv")
            ]
            
            for (name, bio, location, style) in sampleComedians {
                let comedian = Comedian(context: viewContext)
                comedian.name = name
                comedian.bio = bio
                comedian.location = location
                comedian.comedyStyle = style
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving comedians: \(error)")
            }
        }
    }
}

// MARK: - Comedy Style Tag
struct ComedyStyleTag: View {
    let style: String
    let size: TagSize
    
    enum TagSize {
        case small, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .large: return 14
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }
    
    var backgroundColor: Color {
        switch style.lowercased() {
        case "observational": return .blue
        case "storytelling": return .green
        case "improv": return .purple
        case "political": return .red
        case "standup": return .orange
        default: return .orange
        }
    }
    
    var body: some View {
        Text(style.capitalized)
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(backgroundColor.opacity(0.9))
            .clipShape(Capsule())
    }
}

// MARK: - Home View
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Comedian.name, ascending: true)],
        animation: .default)
    private var comedians: FetchedResults<Comedian>
    
    @StateObject private var followService: FollowService
    @State private var showingFollowingList = false
    init() {
        _followService = StateObject(wrappedValue: FollowService(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    HeroSection(
                        comedianCount: comedians.count,
                        followingCount: followService.followedComedianNames.count,
                        onFollowingTapped: { showingFollowingList = true }
                    )
                    
                    VStack(spacing: 32) {
                        // Trending Section
                        TrendingSection(
                            comedians: Array(comedians.prefix(4)),
                            followService: followService
                        )
                        
                        // All Comedians Section
                        AllComediansSection(
                            comedians: Array(comedians),
                            followService: followService
                        )
                    }
                    .padding(.top, 24)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFollowingList) {
                FollowingListView(
                    followedComedians: comedians.filter { followService.isFollowing($0.name ?? "") },
                    followService: followService
                )
            }
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    let comedianCount: Int
    let followingCount: Int
    let onFollowingTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                HStack {
                    Text("🎭")
                        .font(.system(size: 48))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LaughTrack")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                        
                        Text("Discover Rising Comedy Talent")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text("📍 New York, NY")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Stats Cards
            HStack(spacing: 12) {
                StatsCard(number: "\(comedianCount)", label: "Comedians", color: .orange)
                StatsCard(number: "12", label: "Shows Today", color: .blue)
                Button(action: onFollowingTapped) {
                    VStack(spacing: 8) {
                        Text("\(followingCount)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.pink)
                        
                        Text("Following")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [.orange, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let number: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Trending Section
struct TrendingSection: View {
    let comedians: [Comedian]
    @ObservedObject var followService: FollowService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("🔥 Trending Now")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("See All")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(comedians.enumerated()), id: \.element) { index, comedian in
                        NavigationLink(destination: ComedianDetailView(comedian: comedian, photoIndex: index, followService: followService)) {
                            TrendingComedianCard(
                                comedian: comedian,
                                photoIndex: index,
                                isFollowed: followService.isFollowing(comedian.name ?? "")
                            ) {
                                followService.toggleFollow(comedian.name ?? "")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
    
    
// MARK: - All Comedians Section
struct AllComediansSection: View {
    let comedians: [Comedian]
    @ObservedObject var followService: FollowService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("🎤 All Comedians")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(comedians.count) total")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            LazyVStack(spacing: 16) {
                ForEach(Array(comedians.enumerated()), id: \.element) { index, comedian in
                    NavigationLink(destination: ComedianDetailView(comedian: comedian, photoIndex: index, followService: followService)) {
                        ComedianRowCard(
                            comedian: comedian,
                            photoIndex: index,
                            isFollowed: followService.isFollowing(comedian.name ?? "")
                        ) {
                            followService.toggleFollow(comedian.name ?? "")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
    


// MARK: - Trending Comedian Card
struct TrendingComedianCard: View {
    let comedian: Comedian
    let photoIndex: Int
    let isFollowed: Bool
    let onFollowToggle: () -> Void
    
    private var gradientColors: [Color] {
        switch comedian.comedyStyle?.lowercased() ?? "" {
        case "observational": return [.blue, .cyan]
        case "storytelling": return [.green, .mint]
        case "improv": return [.purple, .pink]
        case "political": return [.red, .orange]
        case "standup": return [.orange, .yellow]
        default: return [.orange, .cyan]
        }
    }
    
    private var profileImageURL: String {
        let urls = [
            "https://randomuser.me/api/portraits/women/44.jpg",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&h=200&fit=crop&crop=face"
        ]
        return urls[min(photoIndex, urls.count - 1)]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                        .overlay(
                            Text(String(comedian.name?.prefix(2) ?? "??"))
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onFollowToggle) {
                            Image(systemName: isFollowed ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isFollowed ? .red : .white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(comedian.name ?? "Unknown")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(comedian.location ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                ComedyStyleTag(style: comedian.comedyStyle ?? "", size: .small)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 160)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Comedian Row Card
struct ComedianRowCard: View {
    let comedian: Comedian
    let photoIndex: Int
    let isFollowed: Bool
    let onFollowToggle: () -> Void
    
    private var gradientColors: [Color] {
        switch comedian.comedyStyle?.lowercased() ?? "" {
        case "observational": return [.blue, .cyan]
        case "storytelling": return [.green, .mint]
        case "improv": return [.purple, .pink]
        case "political": return [.red, .orange]
        case "standup": return [.orange, .yellow]
        default: return [.orange, .cyan]
        }
    }
    
    private var profileImageURL: String {
        let urls = [
            "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&h=200&fit=crop&crop=face"
        ]
        return urls[min(photoIndex, urls.count - 1)]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: profileImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                case .failure(_), .empty:
                    if comedian.name == "Amy Park" {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("AP")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(comedian.name?.prefix(2) ?? "??"))
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    }
                @unknown default:
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(comedian.name?.prefix(2) ?? "??"))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(comedian.name ?? "Unknown")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(comedian.bio ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // NEW LAYOUT: Location and tag stacked vertically
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text(comedian.location ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    ComedyStyleTag(style: comedian.comedyStyle ?? "", size: .small)
                }
            }
            
            Spacer()
            
            Button(action: onFollowToggle) {
                Text(isFollowed ? "FOLLOWING" : "FOLLOW")
                    .font(.system(size: 11, weight: .bold))  // Reduced from 12 to 11
                    .foregroundColor(isFollowed ? .white : .black)
                    .padding(.horizontal, 12)  // Reduced from 16 to 12
                    .padding(.vertical, 8)
                    .background(isFollowed ? Color(.systemGray4) : .orange)
                    .clipShape(Capsule())
                    .fixedSize()  // ADDED: Prevents text wrapping
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


// MARK: - Enhanced Comedian Detail View
struct ComedianDetailView: View {
    let comedian: Comedian
    let photoIndex: Int
    @ObservedObject var followService: FollowService
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingReviewSheet = false
    @State private var userRating = 5
    @State private var userComment = ""
    @State private var showingVideos = false
    @State private var featuredVideo: ComedianVideo?
    
    private var gradientColors: [Color] {
        switch comedian.comedyStyle?.lowercased() ?? "" {
        case "observational": return [.blue, .cyan]
        case "storytelling": return [.green, .mint]
        case "improv": return [.purple, .pink]
        case "political": return [.red, .orange]
        case "standup": return [.orange, .yellow]
        default: return [.orange, .cyan]
        }
    }
    
    private var profileImageURL: String {
        let urls = [
            "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=300&h=300&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=300&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=300&h=300&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300&h=300&fit=crop&crop=face",
            "https://randomuser.me/api/portraits/women/44.jpg",
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&h=300&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=300&h=300&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=300&h=300&fit=crop&crop=face"
        ]
        return urls[min(photoIndex, urls.count - 1)]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 280)
                    
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: profileImageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            case .failure(_), .empty:
                                if comedian.name == "Amy Park" {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Text("AP")
                                                .font(.system(size: 40, weight: .black, design: .rounded))
                                                .foregroundColor(.white)
                                        )
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Text(String(comedian.name?.prefix(2) ?? "??"))
                                                .font(.system(size: 40, weight: .black, design: .rounded))
                                                .foregroundColor(.white)
                                        )
                                }
                            @unknown default:
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(String(comedian.name?.prefix(2) ?? "??"))
                                            .font(.system(size: 40, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text(comedian.name ?? "Unknown")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(comedian.location ?? "")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            ComedyStyleTag(style: comedian.comedyStyle ?? "", size: .large)
                        }
                    }
                }
                
                VStack(spacing: 32) {
                    // Bio Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(comedian.bio ?? "")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    // Featured Video Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Video")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let video = featuredVideo {
                            VStack(spacing: 0) {
                                Button(action: { showingVideos = true }) {
                                    ZStack {
                                        AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 220)
                                                .clipped()
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                                .frame(height: 220)
                                                .overlay(
                                                    Image(systemName: "video")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.secondary)
                                                )
                                        }
                                        
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "play.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 24))
                                                    .offset(x: 2)
                                            )
                                    }
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(video.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        VideoPlatformBadge(type: video.videoType)
                                        Spacer()
                                        Text(video.uploadDate, style: .relative)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No videos yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    // Social Media Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Connect")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            SocialMediaButton(platform: "Instagram", icon: "camera.circle.fill", color: .purple)
                            SocialMediaButton(platform: "TikTok", icon: "music.note.circle.fill", color: .pink)
                            SocialMediaButton(platform: "YouTube", icon: "play.circle.fill", color: .red)
                            SocialMediaButton(platform: "Twitter", icon: "bird.circle.fill", color: .blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: { showingVideos = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 16))
                                
                                Text("🎬 View More")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: { showingReviewSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                    
                                    Text("Write Review")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            Button(action: {
                                followService.toggleFollow(comedian.name ?? "")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: followService.isFollowing(comedian.name ?? "") ? "heart.fill" : "heart")
                                        .font(.system(size: 16))
                                    
                                    Text(followService.isFollowing(comedian.name ?? "") ? "Following" : "Follow")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(followService.isFollowing(comedian.name ?? "") ? .red : .blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Reviews Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recent Reviews")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(sampleReviews, id: \.id) { review in
                                ReviewCard(review: review)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 32)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReviewSheet) {
            ReviewSubmissionView(
                comedian: comedian,
                rating: $userRating,
                comment: $userComment,
                onSubmit: submitReview
            )
        }
        .sheet(isPresented: $showingVideos) {
            ComedianVideoListView(
                comedianId: comedian.name ?? "",
                comedianName: comedian.name ?? "Comedian"
            )
        }
        .onAppear {
            loadFeaturedVideo()
        }
    }
    
    private var sampleReviews: [SampleReview] {
        [
            SampleReview(id: 1, rating: 5, comment: "Absolutely hilarious! Best show I've seen all year.", username: "ComedyFan123"),
            SampleReview(id: 2, rating: 4, comment: "Great storytelling and perfect timing.", username: "LaughLover"),
            SampleReview(id: 3, rating: 5, comment: "Had me laughing from start to finish!", username: "StandupFan")
        ]
    }
    
    private func submitReview() {
        let review = Review(context: viewContext)
        review.rating = Int16(userRating)
        review.comment = userComment
        
        do {
            try viewContext.save()
            showingReviewSheet = false
            userComment = ""
            userRating = 5
        } catch {
            print("Error saving review: \(error)")
        }
    }
    private func loadFeaturedVideo() {
        featuredVideo = ComedianVideo(
            comedianId: comedian.name ?? "",
            title: "Office Life Observations",
            description: "My take on working from home",
            duration: 120,
            thumbnailURL: "https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=300&h=200&fit=crop",
            playbackURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            videoType: .nativeUpload,
            uploadDate: Date().addingTimeInterval(-86400),
            isPublic: true
        )
    }}
// MARK: - Search View
struct SearchView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Comedian.name, ascending: true)])
    private var allComedians: FetchedResults<Comedian>
    
    @StateObject private var followService: FollowService
    
    @State private var searchText = ""
    @State private var selectedStyle = "All"
    @State private var selectedLocation = "All"
    
    private let comedyStyles = ["All", "Observational", "Storytelling", "Improv", "Political", "Standup"]
    private let locations = ["All", "San Francisco, CA", "Austin, TX", "Brooklyn, NY", "Chicago, IL", "Los Angeles, CA", "Miami, FL", "Seattle, WA", "Boston, MA"]
    
    init() {
        _followService = StateObject(wrappedValue: FollowService(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    private var filteredComedians: [Comedian] {
        allComedians.filter { comedian in
            let matchesSearch = searchText.isEmpty ||
                               (comedian.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                               (comedian.bio?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesStyle = selectedStyle == "All" ||
                              comedian.comedyStyle?.capitalized == selectedStyle
            
            let matchesLocation = selectedLocation == "All" ||
                                 comedian.location == selectedLocation
            
            return matchesSearch && matchesStyle && matchesLocation
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search comedians...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterMenu(title: "Style", selection: $selectedStyle, options: comedyStyles)
                            FilterMenu(title: "Location", selection: $selectedLocation, options: locations)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.black)
                
                if filteredComedians.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No comedians found")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Try adjusting your search or filters")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredComedians.enumerated()), id: \.element) { index, comedian in
                                NavigationLink(destination: ComedianDetailView(comedian: comedian, photoIndex: index, followService: followService)) {
                                    SearchResultCard(comedian: comedian, photoIndex: index)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Search")
        }
    }
}

struct FilterMenu: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(selection == "All" ? "All" : selection)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
    }
}

struct SearchResultCard: View {
    let comedian: Comedian
    let photoIndex: Int
    
    private var gradientColors: [Color] {
        switch comedian.comedyStyle?.lowercased() ?? "" {
        case "observational": return [.blue, .cyan]
        case "storytelling": return [.green, .mint]
        case "improv": return [.purple, .pink]
        case "political": return [.red, .orange]
        case "standup": return [.orange, .yellow]
        default: return [.orange, .cyan]
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(comedian.name?.prefix(1) ?? "?"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(comedian.name ?? "Unknown")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(comedian.location ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ComedyStyleTag(style: comedian.comedyStyle ?? "", size: .small)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                Text("4.5")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
// MARK: - Book Talent View
struct BookTalentView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Comedian.name, ascending: true)],
        animation: .default)
    private var comedians: FetchedResults<Comedian>
    
    @StateObject private var followService: FollowService
    @State private var selectedStyle = "All"
    @State private var selectedLocation = "All"
    
    private let comedyStyles = ["All", "Observational", "Storytelling", "Improv", "Political", "Standup"]
    private let locations = ["All", "San Francisco, CA", "Austin, TX", "Brooklyn, NY", "Chicago, IL", "Los Angeles, CA", "Miami, FL", "Seattle, WA", "Boston, MA"]
    
    init() {
        _followService = StateObject(wrappedValue: FollowService(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    private var filteredComedians: [Comedian] {
        comedians.filter { comedian in
            let matchesStyle = selectedStyle == "All" ||
                              comedian.comedyStyle?.capitalized == selectedStyle
            
            let matchesLocation = selectedLocation == "All" ||
                                 comedian.location == selectedLocation
            
            return matchesStyle && matchesLocation
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("💼")
                                .font(.system(size: 48))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Book Talent")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Browse and book rising comedians")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterMenu(title: "Style", selection: $selectedStyle, options: comedyStyles)
                                FilterMenu(title: "Location", selection: $selectedLocation, options: locations)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Results count
                    HStack {
                        Text("\(filteredComedians.count) comedian\(filteredComedians.count == 1 ? "" : "s") available")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Comedians List
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredComedians.enumerated()), id: \.element) { index, comedian in
                            NavigationLink(destination: ComedianDetailView(comedian: comedian, photoIndex: index, followService: followService)) {
                                BookTalentCard(
                                    comedian: comedian,
                                    photoIndex: index
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Book Talent Card
struct BookTalentCard: View {
    let comedian: Comedian
    let photoIndex: Int
    
    private var gradientColors: [Color] {
        switch comedian.comedyStyle?.lowercased() ?? "" {
        case "observational": return [.blue, .cyan]
        case "storytelling": return [.green, .mint]
        case "improv": return [.purple, .pink]
        case "political": return [.red, .orange]
        case "standup": return [.orange, .yellow]
        default: return [.orange, .cyan]
        }
    }
    
    private var profileImageURL: String {
        let urls = [
            "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200&h=200&fit=crop&crop=face",
            "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&h=200&fit=crop&crop=face"
        ]
        return urls[min(photoIndex, urls.count - 1)]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: profileImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure(_), .empty:
                    if comedian.name == "Amy Park" {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("AP")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(comedian.name?.prefix(2) ?? "??"))
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    }
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comedian.name ?? "Unknown")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(comedian.bio ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text(comedian.location ?? "")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    ComedyStyleTag(style: comedian.comedyStyle ?? "", size: .small)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
// MARK: - Events View
struct EventsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("📅 Upcoming Shows")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Comedy events near you")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    LazyVStack(spacing: 20) {
                        ForEach(sampleEvents, id: \.id) { event in
                            EventCard(event: event)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
    
    private var sampleEvents: [SampleEvent] {
        [
            SampleEvent(id: 1, title: "Sarah Chen Live", venue: "Comedy Club SF", date: Date().addingTimeInterval(86400), ticketURL: "https://tickets.example.com"),
            SampleEvent(id: 2, title: "Marcus Johnson: Stories", venue: "Laugh Track Austin", date: Date().addingTimeInterval(172800), ticketURL: "https://tickets.example.com"),
            SampleEvent(id: 3, title: "Open Mic Night", venue: "Brooklyn Comedy Bar", date: Date().addingTimeInterval(259200), ticketURL: "https://tickets.example.com")
        ]
    }
}

struct EventCard: View {
    let event: SampleEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(.orange)
                .frame(height: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text(event.venue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text(event.date, style: .date)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Get Tickets") {
                        print("Opening tickets for \(event.title)")
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.orange)
                    .clipShape(Capsule())
                    
                    Button(action: {
                        print("Adding \(event.title) to calendar")
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14))
                            
                            Text("Add to Calendar")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray4))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Profile View
struct ProfileView: View {
    
    @State private var showsAttended = 8
    @State private var reviewsWritten = 25
    @State private var notificationsEnabled = true
    @StateObject private var followService: FollowService

    init() {
        _followService = StateObject(wrappedValue: FollowService(viewContext: PersistenceController.shared.container.viewContext))
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 20) {
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&h=200&fit=crop&crop=face")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text("U")
                                        .font(.system(size: 40, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Comedy Fan")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Discovering the best comedy talent")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 16) {
                        ProfileStat(number: "\(followService.followedComedianNames.count)", label: "Following", color: .orange)
                        ProfileStat(number: "\(showsAttended)", label: "Shows Attended", color: .blue)
                        ProfileStat(number: "\(reviewsWritten)", label: "Reviews", color: .purple)
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Settings")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Push Notifications",
                                subtitle: "Get notified about new shows",
                                isToggle: true,
                                isEnabled: $notificationsEnabled
                            )
                            
                            SettingsRow(
                                icon: "location.fill",
                                title: "Location Services",
                                subtitle: "Find shows near you"
                            )
                            
                            SettingsRow(
                                icon: "star.fill",
                                title: "Rate App",
                                subtitle: "Share your feedback"
                            )
                            
                            SettingsRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                subtitle: "Get help using LaughTrack"
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
}

struct ProfileStat: View {
    let number: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var isToggle: Bool = false
    @Binding var isEnabled: Bool
    
    init(icon: String, title: String, subtitle: String? = nil, isToggle: Bool = false, isEnabled: Binding<Bool> = .constant(false)) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isToggle = isToggle
        self._isEnabled = isEnabled
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.system(size: 18))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isToggle {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Review System
struct ReviewCard: View {
    let review: SampleReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(review.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                    }
                }
            }
            
            Text(review.comment)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ReviewSubmissionView: View {
    let comedian: Comedian
    @Binding var rating: Int
    @Binding var comment: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Text("Rate \(comedian.name ?? "Comedian")")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 32))
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Review")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    TextField("Write your review...", text: $comment, axis: .vertical)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .lineLimit(3...6)
                }
                
                Button("Submit Review") {
                    onSubmit()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Spacer()
            }
            .padding(24)
            .background(Color.black)
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Video System Components
struct ComedianVideoListView: View {
    let comedianId: String
    let comedianName: String
    @StateObject private var videoService = VideoUploadService()
    @State private var videos: [ComedianVideo] = []
    @State private var showingAddVideo = false
    @State private var selectedVideo: ComedianVideo?
    @Environment(\.dismiss) private var dismiss
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    AddVideoButton {
                        showingAddVideo = true
                    }
                    
                    ForEach(videos.sorted(by: { $0.uploadDate > $1.uploadDate })) { video in
                        VideoThumbnailView(video: video) {
                            selectedVideo = video
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("\(comedianName)'s Videos")
            .background(Color.black)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddVideo) {
            SimpleAddVideoView(
                comedianId: comedianId,
                videoService: videoService
            ) { video in
                videos.insert(video, at: 0)
            }
        }
        .sheet(item: $selectedVideo) { video in
            SimpleVideoPlayerView(video: video)
        }
        .onAppear {
            loadSampleVideos()
        }
    }
    
    private func loadSampleVideos() {
        videos = [
            ComedianVideo(
                comedianId: comedianId,
                title: "Office Life Observations",
                description: "My take on working from home",
                duration: 120,
                thumbnailURL: "https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=300&h=200&fit=crop",
                playbackURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                videoType: .nativeUpload,
                uploadDate: Date().addingTimeInterval(-86400),
                isPublic: true
            ),
            ComedianVideo(
                comedianId: comedianId,
                title: "Stand-up Highlights",
                description: nil,
                duration: 0,
                thumbnailURL: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
                playbackURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                videoType: .youtube,
                uploadDate: Date().addingTimeInterval(-172800),
                isPublic: true
            )
        ]
    }
}

// MARK: - Video Components
struct AddVideoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .frame(width: 60, height: 60)
                    .foregroundColor(.orange)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.orange)
                    )
                
                Text("Add Clip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VideoThumbnailView: View {
    let video: ComedianVideo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: "video")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                }
                .overlay(
                    VStack {
                        HStack {
                            VideoPlatformBadge(type: video.videoType)
                            Spacer()
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            )
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            if video.duration > 0 {
                                Text(formatDuration(video.duration))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(8)
                            }
                        }
                    }
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(video.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(video.uploadDate, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VideoPlatformBadge: View {
    let type: ComedianVideo.VideoType
    
    var body: some View {
        Text(type.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var badgeColor: Color {
        switch type {
        case .nativeUpload: return .orange
        case .youtube: return .red
        case .tiktok: return .pink
        case .instagram: return .purple
        }
    }
}

// MARK: - Add Video Flow
struct SimpleAddVideoView: View {
    let comedianId: String
    let videoService: VideoUploadService
    let onVideoAdded: (ComedianVideo) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: VideoOption?
    @State private var videoTitle = ""
    @State private var socialURL = ""
    @State private var selectedPlatform: ComedianVideo.VideoType = .youtube
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var isUploading = false
    
    enum VideoOption: CaseIterable {
        case upload, socialLink
        
        var title: String {
            switch self {
            case .upload: return "Upload Video"
            case .socialLink: return "Add Social Link"
            }
        }
        
        var icon: String {
            switch self {
            case .upload: return "video.badge.plus"
            case .socialLink: return "link"
            }
        }
        
        var color: Color {
            switch self {
            case .upload: return .orange
            case .socialLink: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if selectedOption == nil {
                    optionSelectionView
                } else if selectedOption == .upload {
                    uploadFlowView
                } else {
                    socialLinkFlowView
                }
                
                Spacer()
            }
            .padding(24)
            .background(Color.black)
            .navigationTitle("Add Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.orange)
                }
                
                if selectedOption != nil && !isUploading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") { addVideo() }
                            .foregroundColor(.orange)
                            .disabled(!canAdd)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var optionSelectionView: some View {
        VStack(spacing: 24) {
            Text("How would you like to add your video?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(VideoOption.allCases, id: \.self) { option in
                    Button(action: { selectedOption = option }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.icon)
                                .font(.system(size: 24))
                                .foregroundColor(option.color)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(option == .upload ? "Select from your library" : "YouTube, TikTok, Instagram")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var uploadFlowView: some View {
        VStack(spacing: 24) {
            Text("Upload Video")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                VStack(spacing: 16) {
                    Image(systemName: selectedVideoItem == nil ? "video.badge.plus" : "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(selectedVideoItem == nil ? .orange : .green)
                    
                    Text(selectedVideoItem == nil ? "Select Video" : "Video Selected")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Choose from your photo library")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Enter video title...", text: $videoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if isUploading {
                uploadProgressView
            }
        }
    }
    
    private var socialLinkFlowView: some View {
        VStack(spacing: 24) {
            Text("Add Social Media Link")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Platform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Picker("Platform", selection: $selectedPlatform) {
                    ForEach([ComedianVideo.VideoType.youtube, .tiktok, .instagram], id: \.self) { platform in
                        Text(platform.displayName).tag(platform)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Video URL")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Paste your video link here...", text: $socialURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Enter video title...", text: $videoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var uploadProgressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: videoService.uploadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            
            Text("Uploading... \(Int(videoService.uploadProgress * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    private var canAdd: Bool {
        switch selectedOption {
        case .upload:
            return selectedVideoItem != nil
        case .socialLink:
            return !socialURL.isEmpty && socialURL.contains("http")
        case .none:
            return false
        }
    }
    
    private func addVideo() {
        guard let option = selectedOption else { return }
        
        isUploading = true
        
        Task {
            do {
                let video: ComedianVideo
                
                if option == .socialLink {
                    video = videoService.addSocialMediaLink(
                        url: socialURL,
                        comedianId: comedianId,
                        platform: selectedPlatform
                    )
                } else {
                    video = try await videoService.uploadVideo(
                        comedianId: comedianId,
                        title: videoTitle.isEmpty ? "Comedy Clip" : videoTitle,
                        description: nil
                    )
                }
                
                await MainActor.run {
                    onVideoAdded(video)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - Video Player
struct SimpleVideoPlayerView: View {
    let video: ComedianVideo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if video.videoType == .nativeUpload {
                    if let url = URL(string: video.playbackURL) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 250)
                    }
                } else {
                    SimpleWebVideoPlayer(url: video.playbackURL)
                        .frame(height: 250)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let description = video.description {
                            Text(description)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            VideoPlatformBadge(type: video.videoType)
                            Spacer()
                            Text(video.uploadDate, style: .relative)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .navigationTitle("Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SimpleWebVideoPlayer: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let videoURL = URL(string: url) {
            if url.contains("youtube.com") || url.contains("youtu.be") {
                let embedURL = convertToEmbedURL(url)
                if let embedURL = URL(string: embedURL) {
                    webView.load(URLRequest(url: embedURL))
                }
            } else {
                webView.load(URLRequest(url: videoURL))
            }
        }
    }
    
    private func convertToEmbedURL(_ url: String) -> String {
        if url.contains("youtube.com/watch?v=") {
            let videoId = url.components(separatedBy: "v=")[1].components(separatedBy: "&")[0]
            return "https://www.youtube.com/embed/\(videoId)"
        } else if url.contains("youtu.be/") {
            let videoId = url.components(separatedBy: "youtu.be/")[1].components(separatedBy: "?")[0]
            return "https://www.youtube.com/embed/\(videoId)"
        }
        return url
    }
}
// MARK: - Social Media Button
struct SocialMediaButton: View {
    let platform: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            print("Tapped \(platform)")
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(platform)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
// MARK: - Following List View
struct FollowingListView: View {
    let followedComedians: [Comedian]
    @ObservedObject var followService: FollowService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if followedComedians.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Not following anyone yet")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Follow comedians to see them here")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(followedComedians.enumerated()), id: \.element) { index, comedian in
                            NavigationLink(destination: ComedianDetailView(comedian: comedian, photoIndex: index, followService: followService)) {
                                ComedianRowCard(
                                    comedian: comedian,
                                    photoIndex: index,
                                    isFollowed: true
                                ) {
                                    followService.toggleFollow(comedian.name ?? "")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .background(Color.black)
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#Preview {
    ContentView()
}

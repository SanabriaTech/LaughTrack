//
//  FollowService.swift
//  LaughTrackNew
//
//  Created by Charles R. Skaar on 10/1/25.
//

import Foundation
import CoreData

class FollowService: ObservableObject {
    @Published var followedComedianNames: Set<String> = []
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        loadFollows()
    }
    
    // MARK: - Load all follows from Core Data
    func loadFollows() {
        let request: NSFetchRequest<Follow> = Follow.fetchRequest()
        
        do {
            let follows = try viewContext.fetch(request)
            followedComedianNames = Set(follows.compactMap { $0.comedianName })
        } catch {
            print("Error loading follows: \(error)")
        }
    }
    
    // MARK: - Check if a comedian is followed
    func isFollowing(_ comedianName: String) -> Bool {
        return followedComedianNames.contains(comedianName)
    }
    
    // MARK: - Follow a comedian
    func follow(_ comedianName: String) {
        // Don't create duplicate
        guard !isFollowing(comedianName) else { return }
        
        let follow = Follow(context: viewContext)
        follow.id = UUID()
        follow.comedianName = comedianName
        follow.followedDate = Date()
        
        do {
            try viewContext.save()
            followedComedianNames.insert(comedianName)
        } catch {
            print("Error saving follow: \(error)")
        }
    }
    
    // MARK: - Unfollow a comedian
    func unfollow(_ comedianName: String) {
        let request: NSFetchRequest<Follow> = Follow.fetchRequest()
        request.predicate = NSPredicate(format: "comedianName == %@", comedianName)
        
        do {
            let follows = try viewContext.fetch(request)
            for follow in follows {
                viewContext.delete(follow)
            }
            try viewContext.save()
            followedComedianNames.remove(comedianName)
        } catch {
            print("Error unfollowing: \(error)")
        }
    }
    
    // MARK: - Toggle follow status
    func toggleFollow(_ comedianName: String) {
        if isFollowing(comedianName) {
            unfollow(comedianName)
        } else {
            follow(comedianName)
        }
    }
}

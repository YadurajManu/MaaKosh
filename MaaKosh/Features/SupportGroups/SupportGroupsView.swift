//
//  SupportGroupsView.swift
//  MaaKosh
//
//  Created by Yaduraj Singh on 11/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SupportGroupsView: View {
    @State private var supportGroups: [SupportGroup] = []
    @State private var myGroups: [SupportGroup] = []
    @State private var isLoading = false
    @State private var selectedCategory: GroupCategory = .all
    @State private var showCreateGroupSheet = false
    @State private var showGroupDetail: SupportGroup? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.maakoshLightPink, Color.maakoshMediumLightPink.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header Card
                        headerCard
                        
                        // Search Bar
                        searchBar
                        
                        // Category Filter
                        categoryFilter
                        
                        // My Groups Section
                        if !myGroups.isEmpty {
                            myGroupsSection
                        }
                        
                        // Available Groups
                        availableGroupsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Support Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(AppFont.body())
                        }
                        .foregroundColor(.pink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateGroupSheet = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.pink)
                    }
                }
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                CreateGroupSheet(groups: $supportGroups)
            }
            .sheet(item: $showGroupDetail) { group in
                GroupDetailView(group: group, myGroups: $myGroups)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadSupportGroups()
                loadMyGroups()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerCard: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.pink)
            
            Text("Find Your Community")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Text("Connect with other moms and families on similar journeys")
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search groups...", text: $searchText)
                .font(AppFont.body())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GroupCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.rawValue)
                            .font(AppFont.caption())
                            .foregroundColor(selectedCategory == category ? .white : .pink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.pink : Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var myGroupsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("My Groups")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(myGroups) { group in
                        MyGroupCard(group: group) {
                            showGroupDetail = group
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var availableGroupsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Available Groups")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(filteredGroups.count) groups")
                    .font(AppFont.caption())
                    .foregroundColor(.gray)
            }
            
            if filteredGroups.isEmpty {
                emptyGroupsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGroups) { group in
                        GroupCard(group: group) {
                            showGroupDetail = group
                        }
                    }
                }
            }
        }
    }
    
    private var emptyGroupsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No groups found")
                .font(AppFont.body())
                .foregroundColor(.gray)
            
            Text("Try adjusting your search or create a new group")
                .font(AppFont.caption())
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showCreateGroupSheet = true
            }) {
                Text("Create Group")
                    .font(AppFont.buttonText())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.pink)
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var filteredGroups: [SupportGroup] {
        var groups = supportGroups
        
        // Filter by category
        if selectedCategory != .all {
            groups = groups.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            groups = groups.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return groups
    }
    
    // MARK: - Data Methods
    
    private func loadSupportGroups() {
        isLoading = true
        
        // Simulate loading groups
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            supportGroups = [
                SupportGroup(
                    id: "1",
                    name: "First Time Moms",
                    description: "Support group for first-time mothers sharing experiences and advice",
                    category: .prePregnancy,
                    memberCount: 1247,
                    isPrivate: false,
                    tags: ["first-time", "support", "advice"],
                    createdBy: "Sarah M.",
                    createdAt: Date().addingTimeInterval(-86400 * 30)
                ),
                SupportGroup(
                    id: "2",
                    name: "High-Risk Pregnancy Support",
                    description: "A safe space for moms with high-risk pregnancies to share and support each other",
                    category: .pregnancy,
                    memberCount: 892,
                    isPrivate: true,
                    tags: ["high-risk", "support", "medical"],
                    createdBy: "Dr. Johnson",
                    createdAt: Date().addingTimeInterval(-86400 * 15)
                ),
                SupportGroup(
                    id: "3",
                    name: "Newborn Care Tips",
                    description: "Share tips, tricks, and experiences about caring for newborns",
                    category: .newbornCare,
                    memberCount: 2156,
                    isPrivate: false,
                    tags: ["newborn", "tips", "care"],
                    createdBy: "Emma L.",
                    createdAt: Date().addingTimeInterval(-86400 * 45)
                ),
                SupportGroup(
                    id: "4",
                    name: "Working Moms",
                    description: "Balancing work and motherhood - share your experiences and tips",
                    category: .general,
                    memberCount: 1834,
                    isPrivate: false,
                    tags: ["working-moms", "balance", "career"],
                    createdBy: "Lisa K.",
                    createdAt: Date().addingTimeInterval(-86400 * 20)
                ),
                SupportGroup(
                    id: "5",
                    name: "Fertility Journey",
                    description: "Support for those on their fertility journey and trying to conceive",
                    category: .prePregnancy,
                    memberCount: 967,
                    isPrivate: false,
                    tags: ["fertility", "trying-to-conceive", "support"],
                    createdBy: "Maria R.",
                    createdAt: Date().addingTimeInterval(-86400 * 60)
                )
            ]
            isLoading = false
        }
    }
    
    private func loadMyGroups() {
        // Simulate loading user's groups
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            myGroups = [
                SupportGroup(
                    id: "1",
                    name: "First Time Moms",
                    description: "Support group for first-time mothers sharing experiences and advice",
                    category: .prePregnancy,
                    memberCount: 1247,
                    isPrivate: false,
                    tags: ["first-time", "support", "advice"],
                    createdBy: "Sarah M.",
                    createdAt: Date().addingTimeInterval(-86400 * 30)
                )
            ]
        }
    }
}

// MARK: - Supporting Views

struct GroupCard: View {
    let group: SupportGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(AppFont.titleSmall())
                            .foregroundColor(.black)
                        
                        Text(group.description)
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: group.isPrivate ? "lock.fill" : "globe")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Text("\(group.memberCount)")
                            .font(AppFont.small())
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Text(group.category.rawValue)
                        .font(AppFont.small())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForCategory(group.category))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("Created by \(group.createdBy)")
                        .font(AppFont.small())
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCategory(_ category: GroupCategory) -> Color {
        switch category {
        case .prePregnancy: return .pink
        case .pregnancy: return .purple
        case .newbornCare: return .cyan
        case .general: return .gray
        case .all: return .blue
        }
    }
}

struct MyGroupCard: View {
    let group: SupportGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.pink)
                
                Text(group.name)
                    .font(AppFont.caption())
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("\(group.memberCount) members")
                    .font(AppFont.small())
                    .foregroundColor(.gray)
            }
            .frame(width: 120, height: 100)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateGroupSheet: View {
    @Binding var groups: [SupportGroup]
    @Environment(\.presentationMode) var presentationMode
    @State private var createdGroup: SupportGroup? = nil
    
    @State private var groupName = ""
    @State private var description = ""
    @State private var selectedCategory: GroupCategory = .general
    @State private var isPrivate = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                        
                        Text("Create Support Group")
                            .font(AppFont.titleMedium())
                            .foregroundColor(.black)
                        
                        Text("Create a community for moms to connect and support each other")
                            .font(AppFont.body())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Group Name
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Group Name")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            TextField("Enter group name", text: $groupName)
                                .font(AppFont.body())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Description")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            TextField("Describe your group...", text: $description, axis: .vertical)
                                .font(AppFont.body())
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                ForEach(GroupCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        Text(category.rawValue)
                                            .font(AppFont.caption())
                                            .foregroundColor(selectedCategory == category ? .white : .pink)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == category ? Color.pink : Color.white)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Privacy Setting
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Privacy")
                                .font(AppFont.titleSmall())
                                .foregroundColor(.black)
                            
                            HStack {
                                Button(action: {
                                    isPrivate = false
                                }) {
                                    HStack {
                                        Image(systemName: "globe")
                                            .foregroundColor(!isPrivate ? .white : .gray)
                                        
                                        Text("Public")
                                            .font(AppFont.caption())
                                            .foregroundColor(!isPrivate ? .white : .gray)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(!isPrivate ? Color.pink : Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    isPrivate = true
                                }) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(isPrivate ? .white : .gray)
                                        
                                        Text("Private")
                                            .font(AppFont.caption())
                                            .foregroundColor(isPrivate ? .white : .gray)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isPrivate ? Color.pink : Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6).opacity(0.5))
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || description.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func createGroup() {
        isLoading = true
        
        let newGroup = SupportGroup(
            id: UUID().uuidString,
            name: groupName,
            description: description,
            category: selectedCategory,
            memberCount: 1,
            isPrivate: isPrivate,
            tags: [],
            createdBy: "You",
            createdAt: Date()
        )
        
        // Simulate creating group
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            groups.insert(newGroup, at: 0)
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct GroupDetailView: View {
    let group: SupportGroup
    @Binding var myGroups: [SupportGroup]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isJoined = false
    @State private var recentPosts: [GroupPost] = []
    @State private var showCreatePostSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Group Header
                    groupHeader
                    
                    // Join/Leave Button
                    joinButton
                    
                    // Recent Posts
                    recentPostsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGray6).opacity(0.5))
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreatePostSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.pink)
                    }
                }
            }
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostSheet(group: group, posts: $recentPosts)
            }
            .onAppear {
                loadRecentPosts()
                checkJoinStatus()
            }
        }
    }
    
    private var groupHeader: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.pink)
            
            Text(group.name)
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text(group.description)
                .font(AppFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(group.memberCount)")
                        .font(AppFont.titleSmall())
                        .foregroundColor(.pink)
                    
                    Text("Members")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("Created by")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                    
                    Text(group.createdBy)
                        .font(AppFont.body())
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var joinButton: some View {
        Button(action: {
            toggleJoinStatus()
        }) {
            Text(isJoined ? "Leave Group" : "Join Group")
                .font(AppFont.buttonText())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isJoined ? Color.red : Color.pink)
                .cornerRadius(15)
                .shadow(color: (isJoined ? Color.red : Color.pink).opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
    
    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Posts")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            if recentPosts.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "message")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No posts yet")
                        .font(AppFont.body())
                        .foregroundColor(.gray)
                    
                    Text("Be the first to share something with the group")
                        .font(AppFont.caption())
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentPosts) { post in
                        PostCard(post: post)
                    }
                }
            }
        }
    }
    
    private func loadRecentPosts() {
        // Simulate loading posts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentPosts = [
                GroupPost(
                    id: "1",
                    content: "Just had my first ultrasound today! Baby is doing great 💕",
                    author: "Sarah M.",
                    timestamp: Date().addingTimeInterval(-3600),
                    likes: 12
                ),
                GroupPost(
                    id: "2",
                    content: "Any tips for morning sickness? I'm struggling with it",
                    author: "Emma L.",
                    timestamp: Date().addingTimeInterval(-7200),
                    likes: 8
                )
            ]
        }
    }
    
    private func checkJoinStatus() {
        // Check if user is already a member
        isJoined = myGroups.contains { $0.id == group.id }
    }
    
    private func toggleJoinStatus() {
        if isJoined {
            // Leave group
            myGroups.removeAll { $0.id == group.id }
        } else {
            // Join group
            myGroups.append(group)
        }
        isJoined.toggle()
    }
}

struct PostCard: View {
    let post: GroupPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.author.prefix(1)).uppercased())
                            .font(AppFont.caption())
                            .foregroundColor(.pink)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(AppFont.body())
                        .foregroundColor(.black)
                    
                    Text(formatTime(post.timestamp))
                        .font(AppFont.small())
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Text(post.content)
                .font(AppFont.body())
                .foregroundColor(.black)
            
            HStack {
                Button(action: {
                    // Like post
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                        Text("\(post.likes)")
                            .font(AppFont.small())
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CreatePostSheet: View {
    let group: SupportGroup
    @Binding var posts: [GroupPost]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var content = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Share with \(group.name)")
                        .font(AppFont.titleSmall())
                        .foregroundColor(.black)
                    
                    TextField("What's on your mind?", text: $content, axis: .vertical)
                        .font(AppFont.body())
                        .lineLimit(5...10)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(content.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func createPost() {
        isLoading = true
        
        let newPost = GroupPost(
            id: UUID().uuidString,
            content: content,
            author: "You",
            timestamp: Date(),
            likes: 0
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            posts.insert(newPost, at: 0)
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Data Models

struct SupportGroup: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: GroupCategory
    let memberCount: Int
    let isPrivate: Bool
    let tags: [String]
    let createdBy: String
    let createdAt: Date
}

enum GroupCategory: String, CaseIterable, Codable {
    case all = "All"
    case prePregnancy = "Pre-Pregnancy"
    case pregnancy = "Pregnancy"
    case newbornCare = "Newborn Care"
    case general = "General"
}

struct GroupPost: Identifiable, Codable {
    let id: String
    let content: String
    let author: String
    let timestamp: Date
    let likes: Int
}

#Preview {
    SupportGroupsView()
}

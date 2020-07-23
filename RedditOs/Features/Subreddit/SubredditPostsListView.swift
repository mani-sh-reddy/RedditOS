//
//  SubredditPostsListView.swift
//  RedditOs
//
//  Created by Thomas Ricouard on 09/07/2020.
//

import SwiftUI
import Backend

struct SubredditPostsListView: View {
    let posts = Array(repeating: 0, count: 20)
    
    private let loadingPlaceholders = Array(repeating: static_listing, count: 10)
    
    @EnvironmentObject private var userData: PersistedContent
    @StateObject private var viewModel: SubredditViewModel
    @AppStorage("postDisplayMode") private var displayMode = SubredditPostRow.DisplayMode.large
    @State private var isSearchSheetOpen = false
    @State private var selectedPost: SubredditPost?
    
    init(name: String) {
        _viewModel = StateObject(wrappedValue: SubredditViewModel(name: name))
    }
    
    var isDefaultChannel: Bool {
        SidebarViewModel.MainSubreddits.allCases.map{ $0.rawValue }.contains(viewModel.name)
    }
    
    var subtitle: String {
        if isDefaultChannel {
            return ""
        }
        if let subscribers = viewModel.subreddit?.subscribers, let connected = viewModel.subreddit?.accountsActive {
            return "\(subscribers.toRoundedSuffixAsString()) subscribers - \(connected.toRoundedSuffixAsString()) active"
        }
        return ""
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.listings ?? loadingPlaceholders) { listing in
                    SubredditPostRow(post: listing,
                                     displayMode: displayMode,
                                     selectedPost: $selectedPost)
                        .redacted(reason: viewModel.listings == nil ? .placeholder : [])
                }
                if viewModel.listings != nil {
                    LoadingRow(text: "Loading next page")
                        .onAppear(perform: viewModel.fetchListings)
                }
            }
            .listStyle(InsetListStyle())
            .frame(width: 500)
        }
        .navigationTitle(viewModel.name.capitalized)
        .navigationSubtitle(subtitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker(selection: $displayMode,
                       label: Text("Display"),
                       content: {
                        ForEach(SubredditPostRow.DisplayMode.allCases, id: \.self) { mode in
                            HStack {
                                Text(mode.rawValue.capitalized)
                                Image(systemName: mode.iconName())
                                    .tag(mode)
                            }
                        }
                })
            }
            
            ToolbarItem(placement: .primaryAction) {
                if !isDefaultChannel {
                    Picker(selection: $viewModel.sortOrder,
                           label: Text("Sorting"),
                           content: {
                            ForEach(SubredditViewModel.SortOrder.allCases, id: \.self) { sort in
                                Text(sort.rawValue.capitalized).tag(sort)
                            }
                           })
                } else {
                    EmptyView()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isSearchSheetOpen = true
                }) {
                    Image(systemName: "magnifyingglass")
                }.popover(isPresented: $isSearchSheetOpen) {
                    SearchSubredditsPopover().environmentObject(userData)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    
                }) {
                    Image(systemName: "info")
                }
                .keyboardShortcut("i", modifiers: .command)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .onAppear(perform: viewModel.fetchListings)
        .onAppear {
            if !isDefaultChannel {
                viewModel.fetchAbout()
            }
        }
    }
}

struct Listing_Previews: PreviewProvider {
    static var previews: some View {
        SubredditPostsListView(name: "Best")
    }
}

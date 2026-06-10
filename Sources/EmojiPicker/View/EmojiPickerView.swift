//
//  EmojiPickerView.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// Reports the vertical offset of each section header within the scroll view,
/// used to keep the category tab bar in sync while scrolling.
private struct CategoryOffsetKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

/// A self-contained, embeddable emoji picker.
///
/// Use this directly inside your own layout, or present it via the
/// ``SwiftUI/View/emojiPicker(isPresented:configuration:store:onSelection:)``
/// modifier.
public struct EmojiPickerView: View {

    /// Called with the concrete emoji string (including skin tone) on selection.
    private let onSelection: (String) -> Void
    private let configuration: EmojiPickerConfiguration

    @StateObject private var viewModel: EmojiPickerViewModel
    @State private var currentCategory: EmojiCategory = .smileysAndPeople
    @State private var toneTarget: EmojiPickerViewModel.Item?
    // The category a tab tap is scrolling toward. While set, scroll-driven
    // updates are ignored so the selection doesn't flicker through the
    // intermediate categories the animation passes over. It is cleared the
    // moment that target's header actually reaches the top.
    @State private var pendingCategory: EmojiCategory?
    // Measured size of the skin-tone callout, used to clamp it within the
    // container. Emoji glyphs render wider than their point size, so estimating
    // the width undershoots and the bubble gets clipped at the edges.
    @State private var toneBarSize: CGSize = .zero
    // Dynamic Type scale: cells must grow with the glyphs (which scale in
    // EmojiGridCell), otherwise large text sizes clip inside fixed-size cells.
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
    @Environment(\.dismiss) private var dismiss

    private let scrollSpace = "emojiPickerScroll"

    /// Creates an emoji picker.
    ///
    /// - Note: `configuration` and `store` are captured once when the picker
    ///   first appears; mutating them afterwards on an already-presented picker
    ///   has no effect. Recreate the picker to apply a new configuration.
    public init(
        configuration: EmojiPickerConfiguration = .default,
        store: EmojiPreferenceStore = .shared,
        onSelection: @escaping (String) -> Void
    ) {
        self.configuration = configuration
        self.onSelection = onSelection
        _viewModel = StateObject(wrappedValue: EmojiPickerViewModel(store: store, config: configuration))
    }

    public var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if configuration.showsSearchBar {
                    EmojiSearchBar(text: $viewModel.searchText, accent: configuration.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }

                grid

                if !viewModel.isSearching && viewModel.tabCategories.count > 1 {
                    EmojiCategoryBar(
                        categories: viewModel.tabCategories,
                        selected: currentCategory,
                        accent: configuration.accentColor,
                        translucent: !isSolidBackground,
                        onSelect: { scroll(to: $0, proxy: proxy) }
                    )
                }
            }
        }
        .emojiPickerBackground(configuration.background)
        .overlayPreferenceValue(SkinToneAnchorKey.self) { anchor in
            toneOverlay(anchor: anchor)
        }
    }

    // MARK: Grid

    @ViewBuilder
    private var grid: some View {
        if viewModel.sections.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: configuration.cellSpacing, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.items) { item in
                                cell(for: item)
                            }
                        } header: {
                            // Search results are a flat list, not a category, so
                            // no category header (matches the system keyboard).
                            if !viewModel.isSearching {
                                sectionHeader(section.category)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .coordinateSpace(name: scrollSpace)
            .onPreferenceChange(CategoryOffsetKey.self) { offsets in
                updateCurrentCategory(from: offsets)
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: configuration.minimumCellSize * typeScale), spacing: configuration.cellSpacing)]
    }

    private func cell(for item: EmojiPickerViewModel.Item) -> some View {
        EmojiGridCell(
            emoji: item.emoji,
            tone: item.tone,
            configuration: configuration,
            isToneTarget: toneTarget == item,
            onTap: { handleSelection(item) },
            onLongPress: { beginToneSelection(item) }
        )
        .aspectRatio(1, contentMode: .fill)
    }

    private func sectionHeader(_ category: EmojiCategory) -> some View {
        HStack {
            Text(category.title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                // Header trait so VoiceOver users can jump between categories
                // with the rotor instead of swiping through every cell.
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Pinned headers blur the emoji scrolling underneath, matching the
        // translucent panel rather than punching an opaque strip through it.
        .background(headerBackground)
        .id(category.id)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: CategoryOffsetKey.self,
                    value: [category.id: geo.frame(in: .named(scrollSpace)).minY]
                )
            }
        )
    }

    private var isSolidBackground: Bool {
        if case .solid = configuration.background { return true }
        return false
    }

    @ViewBuilder
    private var headerBackground: some View {
        if isSolidBackground {
            Color(.systemBackground)
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(NSLocalizedString("search.empty", bundle: .module, comment: ""))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Skin-tone overlay

    @ViewBuilder
    private func toneOverlay(anchor: Anchor<CGRect>?) -> some View {
        if let toneTarget, let anchor {
            GeometryReader { proxy in
                let rect = proxy[anchor]
                let caretTargetX = rect.midX + proxy.frame(in: .global).minX
                let layout = barLayout(for: rect, barSize: toneBarSize, in: proxy.size)
                ZStack {
                    // Tap-catcher to dismiss the bar.
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture { dismissToneBar() }

                    SkinToneBar(
                        emoji: toneTarget.emoji,
                        selected: toneTarget.tone,
                        configuration: configuration,
                        caretEdge: layout.caretEdge,
                        caretTargetX: caretTargetX,
                        onSelect: { tone in commitTone(tone, for: toneTarget.emoji) }
                    )
                    .fixedSize()
                    .background(
                        GeometryReader { g in
                            Color.clear
                                .onAppear { toneBarSize = g.size }
                                .onChange(of: g.size) { toneBarSize = $0 }
                        }
                    )
                    // Hidden until measured, so it never flashes at a position
                    // computed from a wrong (estimated) size.
                    .opacity(toneBarSize == .zero ? 0 : 1)
                    .position(layout.position)
                }
            }
            .transition(.opacity)
        }
    }

    /// Places the callout above the emoji (caret down) when there is room,
    /// otherwise flips it below (caret up), and clamps it within the container
    /// using the bubble's *measured* size so it is never cropped on any edge.
    private func barLayout(
        for rect: CGRect,
        barSize: CGSize,
        in size: CGSize
    ) -> (position: CGPoint, caretEdge: Edge) {
        let halfWidth = barSize.width / 2
        let halfHeight = barSize.height / 2
        let gap: CGFloat = 2
        let margin: CGFloat = 4

        let x = min(max(rect.midX, halfWidth + margin), size.width - halfWidth - margin)

        // Prefer above; flip below if the bubble wouldn't fully fit there.
        let aboveCenterY = rect.minY - gap - halfHeight
        if aboveCenterY - halfHeight >= margin {
            return (CGPoint(x: x, y: aboveCenterY), .bottom)
        }
        let belowCenterY = min(rect.maxY + gap + halfHeight, size.height - halfHeight - margin)
        return (CGPoint(x: x, y: belowCenterY), .top)
    }

    // MARK: Actions

    private func handleSelection(_ item: EmojiPickerViewModel.Item) {
        let glyph = viewModel.select(item)
        onSelection(glyph)
        if configuration.dismissesOnSelection {
            dismiss()
        }
    }

    private func beginToneSelection(_ item: EmojiPickerViewModel.Item) {
        Haptics.impact()
        withAnimation(.easeOut(duration: 0.15)) {
            toneTarget = item
        }
    }

    private func commitTone(_ tone: EmojiSkinTone?, for emoji: Emoji) {
        viewModel.setPreferredTone(tone, for: emoji)
        dismissToneBar()
    }

    private func dismissToneBar() {
        withAnimation(.easeOut(duration: 0.15)) {
            toneTarget = nil
        }
    }

    // MARK: Scroll syncing

    private func updateCurrentCategory(from offsets: [String: CGFloat]) {
        guard !viewModel.isSearching, !offsets.isEmpty else { return }
        let threshold: CGFloat = 8
        // The current category is the last header at or above the top edge.
        let aboveTop = offsets.filter { $0.value <= threshold }
        let resolvedID: String?
        if let top = aboveTop.max(by: { $0.value < $1.value }) {
            resolvedID = top.key
        } else {
            resolvedID = offsets.min(by: { $0.value < $1.value })?.key
        }
        guard let resolvedID, let resolved = EmojiCategory(rawValue: resolvedID) else { return }

        // A tab tap is still scrolling toward its target: keep the tapped tab
        // selected and ignore the categories the animation passes over. Release
        // the lock only once the target's header has reached the top.
        if let pending = pendingCategory {
            if resolved == pending { pendingCategory = nil }
            return
        }

        if resolved != currentCategory { currentCategory = resolved }
    }

    private func scroll(to category: EmojiCategory, proxy: ScrollViewProxy) {
        currentCategory = category
        pendingCategory = category
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(category.id, anchor: .top)
        }
    }
}

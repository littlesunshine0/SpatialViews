//
//  SpatialViewsContainer.swift
//  HIG
//
//  Unified container for Spatial & Topological Views
//  Visual paradigms that shift how data is perceived
//

import SwiftUI

// MARK: - Spatial View Mode

enum SpatialViewMode: String, CaseIterable, Identifiable {
    case constellation = "Constellation"
    case voronoi = "Voronoi Tessellation"
    case cityscape = "Isometric Cityscape"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .constellation: return "star.fill"
        case .voronoi: return "square.grid.3x3.topleft.filled"
        case .cityscape: return "building.2.fill"
        }
    }
    
    var description: String {
        switch self {
        case .constellation:
            return "3D star-map with semantic proximity"
        case .voronoi:
            return "Organic cellular grid by importance"
        case .cityscape:
            return "Data as buildings in a city"
        }
    }
    
    var color: Color {
        switch self {
        case .constellation: return .yellow
        case .voronoi: return .cyan
        case .cityscape: return .orange
        }
    }
}

// MARK: - Spatial Views Container

struct SpatialViewsContainer: View {
    @State private var selectedMode: SpatialViewMode = .constellation
    @State private var showModeSelector = true
    @State private var isFullscreen = false
    
    var body: some View {
        ZStack {
            visualizationContent
            
            if showModeSelector {
                VStack {
                    spatialModeSelectorBar
                    Spacer()
                }
            }
            
            if !showModeSelector {
                VStack {
                    HStack {
                        floatingModeButton
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .ignoresSafeArea(isFullscreen ? .all : [])
    }
    
    @ViewBuilder
    private var visualizationContent: some View {
        switch selectedMode {
        case .constellation:
            ConstellationView()
        case .voronoi:
            VoronoiTessellationView()
        case .cityscape:
            IsometricCityscapeView()
        }
    }
    
    private var spatialModeSelectorBar: some View {
        HStack(spacing: 0) {
            ForEach(SpatialViewMode.allCases) { mode in
                SpatialModeTab(
                    mode: mode,
                    isSelected: selectedMode == mode
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    withAnimation { showModeSelector.toggle() }
                } label: {
                    Image(systemName: showModeSelector ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button {
                    withAnimation { isFullscreen.toggle() }
                } label: {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private var floatingModeButton: some View {
        Menu {
            ForEach(SpatialViewMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                }
            }
            Divider()
            Button {
                withAnimation { showModeSelector = true }
            } label: {
                Label("Show Mode Bar", systemImage: "chevron.down")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedMode.icon)
                Text(selectedMode.rawValue)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

// MARK: - Spatial Mode Tab

struct SpatialModeTab: View {
    let mode: SpatialViewMode
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: mode.icon)
                        .font(.body)
                        .foregroundStyle(isSelected ? mode.color : .secondary)
                    
                    Text(mode.rawValue)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                }
                
                if isSelected || isHovered {
                    Text(mode.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? mode.color.opacity(0.1) : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(mode.color)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SpatialViewsContainer()
        .frame(width: 1400, height: 900)
}

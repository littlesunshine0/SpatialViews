//
//  VoronoiTessellationView.swift
//  HIG
//
//  Voronoi Tessellation: Organic cellular grid where item size is determined
//  by importance or activity frequency - "stained glass" interface
//  Prioritizes signal over noise
//

import SwiftUI

// MARK: - Voronoi Cell

struct VoronoiCell: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var center: CGPoint
    var importance: Double // 0-1, determines cell size
    var activityFrequency: Int
    let category: CellCategory
    let color: Color
    var vertices: [CGPoint] = []
    var isSelected: Bool = false
    
    enum CellCategory: String, CaseIterable {
        case code = "Code"
        case document = "Document"
        case media = "Media"
        case data = "Data"
        case config = "Config"
        
        var color: Color {
            switch self {
            case .code: return .blue
            case .document: return .green
            case .media: return .pink
            case .data: return .purple
            case .config: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .document: return "doc.text"
            case .media: return "photo"
            case .data: return "cylinder"
            case .config: return "gearshape"
            }
        }
    }
}

// MARK: - Voronoi Engine

@Observable
class VoronoiEngine {
    var cells: [VoronoiCell] = []
    var selectedCell: VoronoiCell?
    var hoveredCell: VoronoiCell?
    var sizeMode: SizeMode = .importance
    var colorMode: ColorMode = .category
    var showLabels = true
    var animateTransitions = true
    var categoryFilter: VoronoiCell.CellCategory?
    var labelScale: Double = 1.0
    var showCenters = true
    var borderThickness: Double = 2.0
    
    enum SizeMode: String, CaseIterable {
        case importance = "Importance"
        case activity = "Activity"
        case fileSize = "File Size"
        case equal = "Equal"
    }
    
    enum ColorMode: String, CaseIterable {
        case category = "Category"
        case age = "Age"
        case activity = "Activity"
        case custom = "Custom"
    }
    
    func generateVoronoi(in size: CGSize) {
        // Calculate cell positions based on importance
        let totalImportance = cells.reduce(0) { $0 + $1.importance }
        
        // Use weighted random placement
        for i in 0..<cells.count {
            let weight = cells[i].importance / totalImportance
            
            // Place more important items more centrally
            let angle = CGFloat(i) / CGFloat(cells.count) * 2 * .pi
            let radius = size.width * 0.3 * (1 - CGFloat(weight))
            
            cells[i].center = CGPoint(
                x: size.width / 2 + cos(angle) * radius + CGFloat.random(in: -50...50),
                y: size.height / 2 + sin(angle) * radius + CGFloat.random(in: -50...50)
            )
        }
        
        // Calculate Voronoi vertices for each cell
        calculateVoronoiVertices(in: size)
    }
    
    private func calculateVoronoiVertices(in size: CGSize) {
        // Simplified Voronoi calculation using nearest-neighbor approach
        let gridSize = 20
        let _ = size.width / CGFloat(gridSize) // Cell width for grid
        let _ = size.height / CGFloat(gridSize) // Cell height for grid
        
        for i in 0..<cells.count {
            var vertices: [CGPoint] = []
            
            // Find boundary points
            for angle in stride(from: 0, to: 360, by: 15) {
                let radians = CGFloat(angle) * .pi / 180
                var maxDist: CGFloat = min(size.width, size.height) / 2
                
                // Ray march to find boundary
                for dist in stride(from: 10, to: maxDist, by: 5) {
                    let testPoint = CGPoint(
                        x: cells[i].center.x + cos(radians) * dist,
                        y: cells[i].center.y + sin(radians) * dist
                    )
                    
                    // Check if another cell is closer
                    var isClosest = true
                    let myDist = distance(testPoint, cells[i].center)
                    
                    for j in 0..<cells.count where j != i {
                        let otherDist = distance(testPoint, cells[j].center)
                        if otherDist < myDist {
                            isClosest = false
                            maxDist = dist - 5
                            break
                        }
                    }
                    
                    if !isClosest { break }
                }
                
                vertices.append(CGPoint(
                    x: cells[i].center.x + cos(radians) * maxDist,
                    y: cells[i].center.y + sin(radians) * maxDist
                ))
            }
            
            cells[i].vertices = vertices
        }
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    
    func loadSampleData() {
        cells = [
            VoronoiCell(name: "ContentView.swift", path: "/HIG/ContentView.swift", center: .zero, importance: 0.95, activityFrequency: 45, category: .code, color: .blue),
            VoronoiCell(name: "AIKnowledgeBase.swift", path: "/HIG/Models/AIKnowledgeBase.swift", center: .zero, importance: 0.88, activityFrequency: 32, category: .code, color: .purple),
            VoronoiCell(name: "README.md", path: "/README.md", center: .zero, importance: 0.75, activityFrequency: 15, category: .document, color: .green),
            VoronoiCell(name: "AnimationSystem.swift", path: "/HIG/Views/AnimationSystem.swift", center: .zero, importance: 0.82, activityFrequency: 28, category: .code, color: .cyan),
            VoronoiCell(name: "config.json", path: "/config.json", center: .zero, importance: 0.45, activityFrequency: 8, category: .config, color: .orange),
            VoronoiCell(name: "data.json", path: "/Data/data.json", center: .zero, importance: 0.55, activityFrequency: 12, category: .data, color: .purple),
            VoronoiCell(name: "AppIcon.png", path: "/Assets/AppIcon.png", center: .zero, importance: 0.35, activityFrequency: 3, category: .media, color: .pink),
            VoronoiCell(name: "LiquidGlass.swift", path: "/HIG/Views/LiquidGlass.swift", center: .zero, importance: 0.78, activityFrequency: 22, category: .code, color: .blue),
            VoronoiCell(name: "Tests.swift", path: "/HIGTests/Tests.swift", center: .zero, importance: 0.65, activityFrequency: 18, category: .code, color: .blue),
            VoronoiCell(name: "ARCHITECTURE.md", path: "/docs/ARCHITECTURE.md", center: .zero, importance: 0.50, activityFrequency: 5, category: .document, color: .green),
        ]
    }
}

// MARK: - Voronoi Tessellation View

struct VoronoiTessellationView: View {
    @State private var engine = VoronoiEngine()
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            GeometryReader { geo in
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        // Stained glass background
                        stainedGlassBackground

                        // Voronoi cells
                        Canvas { context, size in
                            drawVoronoiCells(context: context, size: size, time: time)
                            rippleOverlay(context: context, time: time)
                        }
                        .gesture(tapGesture(in: geo.size))

                        // Labels overlay
                        if engine.showLabels {
                            labelsOverlay
                        }
                    }
                    .onAppear {
                        viewSize = geo.size
                        engine.loadSampleData()
                        engine.generateVoronoi(in: geo.size)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        viewSize = newSize
                        engine.generateVoronoi(in: newSize)
                    }
                }
            }
            
            // Detail panel
            if let selected = engine.selectedCell {
                Divider()
                cellDetailBar(selected)
            }
        }
    }
    
    // MARK: - Background
    
    private var stainedGlassBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Drawing
    
    private func drawVoronoiCells(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let visibleCells = engine.cells.filter { cell in
            engine.categoryFilter == nil || cell.category == engine.categoryFilter
        }

        for cell in visibleCells {
            guard cell.vertices.count >= 3 else { continue }
            
            // Create cell path
            var path = Path()
            path.move(to: cell.vertices[0])
            for vertex in cell.vertices.dropFirst() {
                path.addLine(to: vertex)
            }
            path.closeSubpath()
            
            // Determine color based on mode
            let fillColor: Color
            switch engine.colorMode {
            case .category:
                fillColor = cell.category.color
            case .age:
                fillColor = Color(hue: cell.importance, saturation: 0.7, brightness: 0.8)
            case .activity:
                let hue = Double(cell.activityFrequency) / 50.0
                fillColor = Color(hue: min(hue, 1.0), saturation: 0.8, brightness: 0.7)
            case .custom:
                fillColor = cell.color
            }

            let shimmer = 0.05 * sin(time * 0.9 + Double(cell.center.x + cell.center.y) * 0.02)
            let breathing = 1 + 0.06 * sin(time * 1.2 + Double(cell.importance) * 4)

            let isSelected = engine.selectedCell?.id == cell.id
            let isHovered = engine.hoveredCell?.id == cell.id

            // Fill
            context.fill(
                path,
                with: .color(fillColor.opacity(isSelected ? 0.9 : (isHovered ? 0.7 : 0.5)))
            )

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        fillColor.opacity(0.18 + shimmer),
                        fillColor.opacity(0.45 * breathing)
                    ]),
                    startPoint: cell.center,
                    endPoint: CGPoint(x: cell.center.x + 40, y: cell.center.y + 40)
                )
            )

            // Border (stained glass lead)
            context.stroke(
                path,
                with: .color(.black.opacity(0.8)),
                lineWidth: (isSelected ? engine.borderThickness + 1 : engine.borderThickness) * (0.95 + breathing * 0.1)
            )

            // Inner glow for selected
            if isSelected {
                context.stroke(
                    path,
                    with: .color(fillColor),
                    lineWidth: 1
                )
            }

            if engine.showCenters {
                context.fill(
                    Path(ellipseIn: CGRect(x: cell.center.x - 3, y: cell.center.y - 3, width: 6, height: 6)),
                    with: .color(.white.opacity(0.8))
                )
            }
        }
    }

    private func rippleOverlay(context: GraphicsContext, time: TimeInterval) {
        guard let selected = engine.selectedCell else { return }
        let ripple = 1 + sin(time * 1.4) * 0.4
        let radius = 14.0 * ripple

        let ringRect = CGRect(
            x: selected.center.x - radius,
            y: selected.center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        var ring = Path(ellipseIn: ringRect)
        ring = ring.strokedPath(.init(lineWidth: 3, dash: [6, 10], dashPhase: CGFloat(time * 8)))

        context.stroke(
            ring,
            with: .color(selected.color.opacity(0.4)),
            lineWidth: 2
        )
    }
    
    // MARK: - Labels Overlay
    
    private var labelsOverlay: some View {
        ForEach(engine.cells.filter { engine.categoryFilter == nil || $0.category == engine.categoryFilter }) { cell in
            Text(cell.name)
                .font(.system(size: 10 * engine.labelScale))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 2)
                .position(cell.center)
        }
    }
    
    // MARK: - Gestures
    
    private func tapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let location = value.location
                
                // Find tapped cell
                for cell in engine.cells {
                    if isPoint(location, insideCell: cell) {
                        engine.selectedCell = cell
                        return
                    }
                }
                engine.selectedCell = nil
            }
    }
    
    private func isPoint(_ point: CGPoint, insideCell cell: VoronoiCell) -> Bool {
        guard cell.vertices.count >= 3 else { return false }
        
        // Simple point-in-polygon test
        var inside = false
        var j = cell.vertices.count - 1
        
        for i in 0..<cell.vertices.count {
            let vi = cell.vertices[i]
            let vj = cell.vertices[j]
            
            if ((vi.y > point.y) != (vj.y > point.y)) &&
                (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x) {
                inside.toggle()
            }
            j = i
        }
        
        return inside
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.topleft.filled")
                    .foregroundStyle(.cyan)
                Text("Voronoi Tessellation")
                    .font(.headline)
            }
            
            Divider().frame(height: 20)
            
            Picker("Size", selection: $engine.sizeMode) {
                ForEach(VoronoiEngine.SizeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .frame(width: 120)
            .onChange(of: engine.sizeMode) { _, _ in
                engine.generateVoronoi(in: viewSize)
            }
            
            Picker("Color", selection: $engine.colorMode) {
                ForEach(VoronoiEngine.ColorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .frame(width: 100)

            Toggle(isOn: $engine.showLabels) {
                Label("Labels", systemImage: "textformat")
            }
            .toggleStyle(.button)

            Toggle(isOn: $engine.showCenters) {
                Label("Centers", systemImage: "dot.circle")
            }
            .toggleStyle(.button)

            Spacer()

            Button {
                engine.generateVoronoi(in: viewSize)
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Picker("Category", selection: Binding(
                get: { engine.categoryFilter },
                set: { engine.categoryFilter = $0 }
            )) {
                Text("All").tag(VoronoiCell.CellCategory?.none)
                ForEach(VoronoiCell.CellCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(VoronoiCell.CellCategory?.some(category))
                }
            }
            .frame(width: 140)

            VStack(alignment: .leading, spacing: 2) {
                Text("Labels x\(String(format: "%.1f", engine.labelScale))")
                    .font(.caption2)
                Slider(value: $engine.labelScale, in: 0.8...2.0)
                    .frame(width: 110)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Borders \(String(format: "%.1f", engine.borderThickness))")
                    .font(.caption2)
                Slider(value: $engine.borderThickness, in: 1...4)
                    .frame(width: 110)
            }

            Text("\(engine.cells.count) cells")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
    
    // MARK: - Detail Bar
    
    private func cellDetailBar(_ cell: VoronoiCell) -> some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: cell.category.icon)
                    .foregroundStyle(cell.category.color)
                Text(cell.name)
                    .font(.headline)
            }
            
            Text(cell.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack(alignment: .trailing) {
                    Text("Importance")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(Int(cell.importance * 100))%")
                        .font(.caption.weight(.semibold))
                }
                
                VStack(alignment: .trailing) {
                    Text("Activity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(cell.activityFrequency)")
                        .font(.caption.weight(.semibold))
                }
            }
            
            Button {
                engine.selectedCell = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

#Preview {
    VoronoiTessellationView()
        .frame(width: 1200, height: 800)
}

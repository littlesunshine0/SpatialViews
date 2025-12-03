//
//  IsometricCityscapeView.swift
//  HIG
//
//  Isometric Cityscape: Data as buildings in a city
//  Height = file size, Color = age, District = category
//  Fly over your database to spot outliers
//

import SwiftUI

// MARK: - Building

struct Building: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let fileSize: Int64
    let age: Date
    let category: String
    var gridPosition: (x: Int, y: Int)
    let floors: Int
    let color: Color
    
    var height: CGFloat {
        CGFloat(floors) * 15
    }
    
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: age, to: Date()).day ?? 0
    }
    
    var ageColor: Color {
        let days = ageInDays
        if days < 7 { return .green }
        if days < 30 { return .yellow }
        if days < 90 { return .orange }
        return .red
    }
}

// MARK: - District

struct District: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let gridRange: (xMin: Int, xMax: Int, yMin: Int, yMax: Int)
    var buildings: [Building] = []
}

// MARK: - Cityscape Engine

@Observable
class CityscapeEngine {
    var districts: [District] = []
    var buildings: [Building] = []
    var selectedBuilding: Building?
    var hoveredBuilding: Building?
    var cameraAngle: CGFloat = 45
    var cameraHeight: CGFloat = 30
    var zoom: CGFloat = 1.0
    var panOffset: CGSize = .zero
    var colorMode: ColorMode = .category
    var showGrid = true
    var showLabels = true
    var timeOfDay: TimeOfDay = .day
    var heightMultiplier: CGFloat = 1.0
    var fogDensity: Double = 0.0
    var showBeacons = true
    var districtFilter: String? = nil
    
    enum ColorMode: String, CaseIterable {
        case category = "Category"
        case age = "Age"
        case size = "Size"
    }
    
    enum TimeOfDay: String, CaseIterable {
        case day = "Day"
        case sunset = "Sunset"
        case night = "Night"
        
        var skyColors: [Color] {
            switch self {
            case .day: return [Color(red: 0.5, green: 0.7, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.8)]
            case .sunset: return [Color(red: 0.9, green: 0.5, blue: 0.3), Color(red: 0.6, green: 0.3, blue: 0.5)]
            case .night: return [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15)]
            }
        }
        
        var ambientLight: Double {
            switch self {
            case .day: return 1.0
            case .sunset: return 0.7
            case .night: return 0.3
            }
        }
    }
    
    func loadSampleData() {
        // Define districts
        districts = [
            District(name: "Code District", color: .blue, gridRange: (0, 4, 0, 4)),
            District(name: "Document Quarter", color: .green, gridRange: (5, 8, 0, 4)),
            District(name: "Media Zone", color: .pink, gridRange: (0, 4, 5, 8)),
            District(name: "Data Center", color: .purple, gridRange: (5, 8, 5, 8)),
        ]
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate buildings
        buildings = [
            // Code District
            Building(name: "ContentView.swift", path: "/HIG/ContentView.swift", fileSize: 15000, age: now, category: "Code", gridPosition: (1, 1), floors: 12, color: .blue),
            Building(name: "AIKnowledgeBase.swift", path: "/HIG/Models/AIKnowledgeBase.swift", fileSize: 25000, age: calendar.date(byAdding: .day, value: -5, to: now)!, category: "Code", gridPosition: (2, 1), floors: 18, color: .cyan),
            Building(name: "AnimationSystem.swift", path: "/HIG/Views/AnimationSystem.swift", fileSize: 12000, age: calendar.date(byAdding: .day, value: -10, to: now)!, category: "Code", gridPosition: (1, 2), floors: 10, color: .blue),
            Building(name: "Navigator.swift", path: "/HIG/Views/Navigator.swift", fileSize: 8000, age: calendar.date(byAdding: .day, value: -3, to: now)!, category: "Code", gridPosition: (3, 2), floors: 7, color: .indigo),
            Building(name: "LiquidGlass.swift", path: "/HIG/Views/LiquidGlass.swift", fileSize: 18000, age: calendar.date(byAdding: .day, value: -15, to: now)!, category: "Code", gridPosition: (2, 3), floors: 14, color: .blue),
            
            // Document Quarter
            Building(name: "README.md", path: "/README.md", fileSize: 5000, age: calendar.date(byAdding: .month, value: -2, to: now)!, category: "Document", gridPosition: (6, 1), floors: 5, color: .green),
            Building(name: "ARCHITECTURE.md", path: "/docs/ARCHITECTURE.md", fileSize: 8000, age: calendar.date(byAdding: .month, value: -1, to: now)!, category: "Document", gridPosition: (7, 2), floors: 7, color: .mint),
            Building(name: "API_DOCS.md", path: "/docs/API_DOCS.md", fileSize: 12000, age: calendar.date(byAdding: .day, value: -20, to: now)!, category: "Document", gridPosition: (6, 3), floors: 10, color: .green),
            
            // Media Zone
            Building(name: "AppIcon.png", path: "/Assets/AppIcon.png", fileSize: 50000, age: calendar.date(byAdding: .month, value: -3, to: now)!, category: "Media", gridPosition: (1, 6), floors: 4, color: .pink),
            Building(name: "Screenshots", path: "/Assets/Screenshots", fileSize: 200000, age: calendar.date(byAdding: .day, value: -7, to: now)!, category: "Media", gridPosition: (2, 7), floors: 15, color: .pink),
            
            // Data Center
            Building(name: "hig_combined.json", path: "/HIG/hig_combined.json", fileSize: 500000, age: calendar.date(byAdding: .day, value: -1, to: now)!, category: "Data", gridPosition: (6, 6), floors: 25, color: .purple),
            Building(name: "config.json", path: "/config.json", fileSize: 2000, age: calendar.date(byAdding: .month, value: -1, to: now)!, category: "Data", gridPosition: (7, 7), floors: 3, color: .purple),
        ]
    }
}

// MARK: - Isometric Cityscape View

struct IsometricCityscapeView: View {
    @State private var engine = CityscapeEngine()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: engine.timeOfDay.skyColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // City canvas
                GeometryReader { geo in
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate

                        ZStack {
                            movingClouds(time: time, size: geo.size)

                            Canvas { context, size in
                                drawCity(context: context, size: size, time: time)
                                drawTraffic(context: context, size: size, time: time)
                            }
                            .gesture(dragGesture)
                            .gesture(magnificationGesture)

                            aerialLightSweep(time: time, size: geo.size)
                        }
                    }
                }

                fogOverlay

                // Building info overlay
                if let selected = engine.selectedBuilding {
                    buildingInfoCard(selected)
                        .position(x: 180, y: 150)
                }
            }
            
            Divider()
            legendBar
        }
        .onAppear {
            engine.loadSampleData()
        }
    }
    
    // MARK: - Drawing
    
    private func drawCity(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let driftX = sin(time * 0.05) * 4
        let driftY = cos(time * 0.06) * 6
        let centerX = size.width / 2 + engine.panOffset.width + driftX
        let centerY = size.height / 2 + engine.panOffset.height + driftY
        let tileWidth: CGFloat = 40 * engine.zoom
        let tileHeight: CGFloat = 20 * engine.zoom

        let activeDistricts = engine.districtFilter == nil ? engine.districts : engine.districts.filter { $0.name == engine.districtFilter }
        let activeBuildings = engine.buildings.filter { building in
            guard let districtName = districtName(for: building) else { return engine.districtFilter == nil }
            return engine.districtFilter == nil || districtName == engine.districtFilter
        }

        // Draw ground grid
        if engine.showGrid {
            drawGrid(context: context, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
        }

        // Draw districts
        for district in activeDistricts {
            drawDistrict(district, context: context, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
        }

        // Sort buildings by position for proper depth
        let sortedBuildings = activeBuildings.sorted { b1, b2 in
            let sum1 = b1.gridPosition.x + b1.gridPosition.y
            let sum2 = b2.gridPosition.x + b2.gridPosition.y
            return sum1 < sum2
        }
        
        // Draw buildings
        for building in sortedBuildings {
            drawBuilding(building, context: context, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight, time: time)
        }
    }

    private func drawTraffic(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let driftX = sin(time * 0.05) * 4
        let driftY = cos(time * 0.06) * 6
        let centerX = size.width / 2 + engine.panOffset.width + driftX
        let centerY = size.height / 2 + engine.panOffset.height + driftY
        let tileWidth: CGFloat = 40 * engine.zoom
        let tileHeight: CGFloat = 20 * engine.zoom

        let phase = CGFloat(time.truncatingRemainder(dividingBy: 20)) * 12
        let primaryColor = Color.orange.opacity(0.25)
        let secondaryColor = Color.yellow.opacity(0.18)

        for lane in stride(from: 0, through: 9, by: 2) {
            let start = isoToScreen(x: 0, y: lane, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
            let end = isoToScreen(x: 10, y: lane, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [secondaryColor, primaryColor, .clear]),
                    startPoint: start,
                    endPoint: end
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [12, 28], dashPhase: phase)
            )
        }
    }

    private func movingClouds(time: TimeInterval, size: CGSize) -> some View {
        let offset = CGFloat(sin(time * 0.04) * 40)
        return ZStack {
            ForEach(0..<4, id: \.self) { idx in
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 260, height: 80)
                    .blur(radius: 40)
                    .offset(x: offset + CGFloat(idx * 120) - size.width * 0.5, y: CGFloat(-120 + idx * 30))
            }
        }
    }

    private func aerialLightSweep(time: TimeInterval, size: CGSize) -> some View {
        let sweepX = (sin(time * 0.18) + 1) / 2 * size.width
        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 220)
            .rotationEffect(.degrees(-20))
            .offset(x: sweepX - size.width / 2, y: -80)
            .blendMode(.screen)
    }
    
    private func drawGrid(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, tileWidth: CGFloat, tileHeight: CGFloat) {
        for x in 0..<10 {
            for y in 0..<10 {
                let screenPos = isoToScreen(x: x, y: y, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
                
                var path = Path()
                path.move(to: CGPoint(x: screenPos.x, y: screenPos.y))
                path.addLine(to: CGPoint(x: screenPos.x + tileWidth / 2, y: screenPos.y + tileHeight / 2))
                path.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y + tileHeight))
                path.addLine(to: CGPoint(x: screenPos.x - tileWidth / 2, y: screenPos.y + tileHeight / 2))
                path.closeSubpath()
                
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
            }
        }
    }
    
    private func drawDistrict(_ district: District, context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, tileWidth: CGFloat, tileHeight: CGFloat) {
        let minPos = isoToScreen(x: district.gridRange.xMin, y: district.gridRange.yMin, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
        
        // Draw district label
        let text = Text(district.name)
            .font(.caption2)
            .foregroundColor(district.color.opacity(0.7))
        
        context.draw(text, at: CGPoint(x: minPos.x, y: minPos.y - 20))
    }
    
    private func drawBuilding(_ building: Building, context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, tileWidth: CGFloat, tileHeight: CGFloat, time: TimeInterval) {
        let screenPos = isoToScreen(x: building.gridPosition.x, y: building.gridPosition.y, centerX: centerX, centerY: centerY, tileWidth: tileWidth, tileHeight: tileHeight)
        
        let height = building.height * engine.zoom * engine.heightMultiplier
        let width = tileWidth * 0.8
        let depth = tileHeight * 0.8
        
        let isSelected = engine.selectedBuilding?.id == building.id
        let isHovered = engine.hoveredBuilding?.id == building.id
        
        // Determine color
        let baseColor: Color
        switch engine.colorMode {
        case .category:
            baseColor = building.color
        case .age:
            baseColor = building.ageColor
        case .size:
            let sizeRatio = min(1.0, Double(building.fileSize) / 100000.0)
            baseColor = Color(hue: 0.6 - sizeRatio * 0.4, saturation: 0.7, brightness: 0.8)
        }
        
        let ambient = engine.timeOfDay.ambientLight + 0.05 * sin(time * 0.5 + Double(building.gridPosition.x))
        let highlightMultiplier = isSelected ? 1.3 : (isHovered ? 1.15 : 1.0)

        let facadeSweep = max(0, sin(time * 0.8 + Double(building.gridPosition.y))) * 0.2
        
        // Left face
        var leftPath = Path()
        leftPath.move(to: CGPoint(x: screenPos.x - width / 2, y: screenPos.y + depth / 2))
        leftPath.addLine(to: CGPoint(x: screenPos.x - width / 2, y: screenPos.y + depth / 2 - height))
        leftPath.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y - height))
        leftPath.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y))
        leftPath.closeSubpath()
        
        context.fill(leftPath, with: .color(baseColor.opacity((0.7 + facadeSweep * 0.5) * ambient * highlightMultiplier)))
        
        // Right face
        var rightPath = Path()
        rightPath.move(to: CGPoint(x: screenPos.x + width / 2, y: screenPos.y + depth / 2))
        rightPath.addLine(to: CGPoint(x: screenPos.x + width / 2, y: screenPos.y + depth / 2 - height))
        rightPath.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y - height))
        rightPath.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y))
        rightPath.closeSubpath()
        
        context.fill(rightPath, with: .color(baseColor.opacity((0.5 + facadeSweep * 0.4) * ambient * highlightMultiplier)))
        
        // Top face
        var topPath = Path()
        topPath.move(to: CGPoint(x: screenPos.x, y: screenPos.y - height))
        topPath.addLine(to: CGPoint(x: screenPos.x + width / 2, y: screenPos.y + depth / 2 - height))
        topPath.addLine(to: CGPoint(x: screenPos.x, y: screenPos.y + depth - height))
        topPath.addLine(to: CGPoint(x: screenPos.x - width / 2, y: screenPos.y + depth / 2 - height))
        topPath.closeSubpath()
        
        context.fill(topPath, with: .color(baseColor.opacity((0.9 + facadeSweep * 0.3) * ambient * highlightMultiplier)))
        
        // Windows (night mode)
        if engine.timeOfDay == .night {
            let windowRows = building.floors / 2
            for row in 0..<windowRows {
                let windowY = screenPos.y - CGFloat(row * 2 + 1) * (height / CGFloat(building.floors))
                
                // Left windows
                context.fill(
                    Path(CGRect(x: screenPos.x - width / 4 - 3, y: windowY - 4, width: 6, height: 8)),
                    with: .color(.yellow.opacity(Double.random(in: 0.3...0.9)))
                )
                
                // Right windows
                context.fill(
                    Path(CGRect(x: screenPos.x + width / 4 - 3, y: windowY - 4, width: 6, height: 8)),
                    with: .color(.yellow.opacity(Double.random(in: 0.3...0.9)))
                )
            }
        }

        if engine.showBeacons && building.ageInDays <= 10 {
            let beaconPosition = CGPoint(x: screenPos.x, y: screenPos.y - height - 8)
            context.fill(
                Path(ellipseIn: CGRect(x: beaconPosition.x - 4, y: beaconPosition.y - 4, width: 8, height: 8)),
                with: .color(.yellow.opacity(0.9))
            )

            var beamPath = Path()
            beamPath.move(to: beaconPosition)
            beamPath.addLine(to: CGPoint(x: beaconPosition.x, y: beaconPosition.y - 16))
            context.stroke(beamPath, with: .color(.yellow.opacity(0.6)), lineWidth: 2)
        }
        
        // Label
        if engine.showLabels && (isSelected || isHovered) {
            let text = Text(building.name)
                .font(.caption2)
                .foregroundColor(.white)
            
            context.draw(text, at: CGPoint(x: screenPos.x, y: screenPos.y - height - 15))
        }
        
        // Selection outline
        if isSelected {
            context.stroke(leftPath, with: .color(.white), lineWidth: 2)
            context.stroke(rightPath, with: .color(.white), lineWidth: 2)
            context.stroke(topPath, with: .color(.white), lineWidth: 2)
        }
    }
    
    private func isoToScreen(x: Int, y: Int, centerX: CGFloat, centerY: CGFloat, tileWidth: CGFloat, tileHeight: CGFloat) -> CGPoint {
        CGPoint(
            x: centerX + CGFloat(x - y) * tileWidth / 2,
            y: centerY + CGFloat(x + y) * tileHeight / 2
        )
    }

    private func districtName(for building: Building) -> String? {
        engine.districts.first {
            let range = $0.gridRange
            return building.gridPosition.x >= range.xMin && building.gridPosition.x <= range.xMax &&
            building.gridPosition.y >= range.yMin && building.gridPosition.y <= range.yMax
        }?.name
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                engine.panOffset = value.translation
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                engine.zoom = max(0.5, min(2.0, value))
            }
    }
    
    // MARK: - UI Components

    private var toolbar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.orange)
                Text("Isometric Cityscape")
                    .font(.headline)
            }
            
            Divider().frame(height: 20)
            
            Picker("Color", selection: $engine.colorMode) {
                ForEach(CityscapeEngine.ColorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .frame(width: 100)
            
            Picker("Time", selection: $engine.timeOfDay) {
                ForEach(CityscapeEngine.TimeOfDay.allCases, id: \.self) { time in
                    Text(time.rawValue).tag(time)
                }
            }
            .frame(width: 100)
            
            Toggle(isOn: $engine.showGrid) {
                Label("Grid", systemImage: "grid")
            }
            .toggleStyle(.button)
            
            Toggle(isOn: $engine.showLabels) {
                Label("Labels", systemImage: "textformat")
            }
            .toggleStyle(.button)

            Toggle(isOn: $engine.showBeacons) {
                Label("Beacons", systemImage: "light.max")
            }
            .toggleStyle(.button)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Height x\(String(format: "%.1f", engine.heightMultiplier))")
                    .font(.caption2)
                Slider(value: $engine.heightMultiplier, in: 0.5...2.5)
                    .frame(width: 120)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Fog \(Int(engine.fogDensity * 100))%")
                    .font(.caption2)
                Slider(value: $engine.fogDensity, in: 0...0.6)
                    .frame(width: 120)
            }

            Picker("District", selection: Binding(
                get: { engine.districtFilter ?? "All" },
                set: { newValue in
                    engine.districtFilter = newValue == "All" ? nil : newValue
                }
            )) {
                Text("All").tag("All")
                ForEach(engine.districts.map(\.name), id: \.self) { district in
                    Text(district).tag(district)
                }
            }
            .frame(width: 140)

            Text("\(engine.buildings.count) buildings")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var fogOverlay: some View {
        Color.black
            .opacity(engine.fogDensity * (engine.timeOfDay == .night ? 0.6 : 0.35))
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }
    
    private var legendBar: some View {
        HStack(spacing: 20) {
            Text("Height = File Size")
                .font(.caption)
            Text("•")
                .foregroundStyle(.tertiary)
            
            HStack(spacing: 8) {
                ForEach(["Code", "Document", "Media", "Data"], id: \.self) { cat in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(categoryColor(cat))
                            .frame(width: 8, height: 8)
                        Text(cat)
                            .font(.caption2)
                    }
                }
            }
            
            Spacer()
            
            Text("Drag to pan • Pinch to zoom")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Code": return .blue
        case "Document": return .green
        case "Media": return .pink
        case "Data": return .purple
        default: return .gray
        }
    }
    
    private func buildingInfoCard(_ building: Building) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(building.name)
                    .font(.headline)
                Spacer()
                Button { engine.selectedBuilding = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(building.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Size")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: building.fileSize, countStyle: .file))
                        .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Age")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(building.ageInDays) days")
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    IsometricCityscapeView()
        .frame(width: 1200, height: 800)
}

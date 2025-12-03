//
//  ConstellationView.swift
//  HIG
//
//  Constellation View: 3D star-map where data points are nodes
//  Proximity determined by semantic similarity (vector embeddings)
//  Related files "orbit" a central project sun
//

import SwiftUI
import Combine
// MARK: - Celestial Body

struct CelestialBody: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let bodyType: BodyType
    var position: SIMD3<Float>
    var orbitRadius: Float
    var orbitSpeed: Float
    var orbitPhase: Float
    let size: Float
    let color: Color
    let brightness: Float
    let satellites: [UUID]
    let embedding: [Float]
    
    enum BodyType: String, CaseIterable {
        case sun = "Project Sun"
        case planet = "Major File"
        case moon = "Related File"
        case asteroid = "Small File"
        case comet = "Recent Change"
        
        var icon: String {
            switch self {
            case .sun: return "sun.max.fill"
            case .planet: return "globe"
            case .moon: return "moon.fill"
            case .asteroid: return "sparkle"
            case .comet: return "flame"
            }
        }
        
        var baseSize: Float {
            switch self {
            case .sun: return 40
            case .planet: return 20
            case .moon: return 12
            case .asteroid: return 6
            case .comet: return 10
            }
        }
    }
}

// MARK: - Constellation Engine

@Observable
class ConstellationEngine {
    var bodies: [CelestialBody] = []
    var selectedBody: CelestialBody?
    var hoveredBody: CelestialBody?
    var cameraRotation: SIMD2<Float> = .zero
    var cameraZoom: Float = 1.0
    var showOrbits = true
    var showConnections = true
    var animationSpeed: Float = 1.0
    var time: Float = 0
    
    var centralSun: CelestialBody? {
        bodies.first { $0.bodyType == .sun }
    }
    
    func update(deltaTime: Float) {
        time += deltaTime * animationSpeed
        
        for i in 0..<bodies.count {
            guard bodies[i].bodyType != .sun else { continue }
            
            // Update orbital position
            let phase = bodies[i].orbitPhase + time * bodies[i].orbitSpeed
            let radius = bodies[i].orbitRadius
            
            bodies[i].position = SIMD3<Float>(
                cos(phase) * radius,
                sin(phase * 0.3) * radius * 0.2, // Slight vertical wobble
                sin(phase) * radius
            )
        }
    }
    
    func loadSampleData() {
        // Central project sun
        let sun = CelestialBody(
            name: "HIG Project",
            path: "/HIG",
            bodyType: .sun,
            position: .zero,
            orbitRadius: 0,
            orbitSpeed: 0,
            orbitPhase: 0,
            size: 50,
            color: .yellow,
            brightness: 1.0,
            satellites: [],
            embedding: [0.5, 0.5, 0.5, 0.5]
        )
        bodies.append(sun)
        
        // Major planets (main files)
        let planets: [(String, String, Color, Float, [Float])] = [
            ("ContentView.swift", "/HIG/ContentView.swift", .blue, 3.0, [0.9, 0.2, 0.3, 0.1]),
            ("AIKnowledgeBase.swift", "/HIG/Models/AIKnowledgeBase.swift", .purple, 4.5, [0.2, 0.9, 0.3, 0.2]),
            ("AnimationSystem.swift", "/HIG/Views/AnimationSystem.swift", .orange, 5.5, [0.3, 0.3, 0.9, 0.1]),
            ("LiquidGlassWindow.swift", "/HIG/Views/LiquidGlassWindow.swift", .cyan, 6.5, [0.4, 0.2, 0.8, 0.3]),
            ("Navigator.swift", "/HIG/Views/Navigator.swift", .green, 7.5, [0.8, 0.3, 0.2, 0.4]),
        ]
        
        for (index, planet) in planets.enumerated() {
            let body = CelestialBody(
                name: planet.0,
                path: planet.1,
                bodyType: .planet,
                position: .zero,
                orbitRadius: planet.3,
                orbitSpeed: 0.5 / planet.3,
                orbitPhase: Float(index) * .pi * 2 / Float(planets.count),
                size: 20 + Float.random(in: -5...5),
                color: planet.2,
                brightness: 0.8,
                satellites: [],
                embedding: planet.4
            )
            bodies.append(body)
        }
        
        // Moons (related files)
        let moons: [(String, String, Color, Int)] = [
            ("Models.swift", "/HIG/Views/Models.swift", .gray, 1),
            ("ChatView.swift", "/HIG/Views/ChatView.swift", .pink, 2),
            ("Persistence.swift", "/HIG/Views/Persistence.swift", .brown, 3),
            ("Settings.swift", "/HIG/Views/Settings.swift", .mint, 4),
        ]
        
        for (index, moon) in moons.enumerated() {
            let _ = moon.3 // Parent index for orbital reference
            let body = CelestialBody(
                name: moon.0,
                path: moon.1,
                bodyType: .moon,
                position: .zero,
                orbitRadius: 1.5,
                orbitSpeed: 2.0,
                orbitPhase: Float(index) * .pi / 2,
                size: 10,
                color: moon.2,
                brightness: 0.6,
                satellites: [],
                embedding: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
            bodies.append(body)
        }
        
        // Asteroids (small files)
        for i in 0..<15 {
            let body = CelestialBody(
                name: "file_\(i).swift",
                path: "/HIG/Utils/file_\(i).swift",
                bodyType: .asteroid,
                position: .zero,
                orbitRadius: Float.random(in: 8...12),
                orbitSpeed: Float.random(in: 0.1...0.3),
                orbitPhase: Float.random(in: 0...(.pi * 2)),
                size: Float.random(in: 4...8),
                color: .gray,
                brightness: 0.4,
                satellites: [],
                embedding: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
            bodies.append(body)
        }
        
        // Comets (recent changes)
        let comets: [(String, Color)] = [
            ("NewFeature.swift", .red),
            ("Hotfix.swift", .orange),
        ]
        
        for (index, comet) in comets.enumerated() {
            let body = CelestialBody(
                name: comet.0,
                path: "/HIG/\(comet.0)",
                bodyType: .comet,
                position: .zero,
                orbitRadius: Float.random(in: 5...10),
                orbitSpeed: 1.5,
                orbitPhase: Float(index) * .pi,
                size: 12,
                color: comet.1,
                brightness: 0.9,
                satellites: [],
                embedding: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
            bodies.append(body)
        }
    }
}

// MARK: - Constellation View

struct ConstellationView: View {
    @State private var engine = ConstellationEngine()
    @State private var isDragging = false
    @State private var lastDragPosition: CGPoint = .zero
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Space background
            spaceBackground
            
            // 3D constellation
            GeometryReader { geo in
                Canvas { context, size in
                    drawConstellation(context: context, size: size)
                }
                .gesture(dragGesture)
                .gesture(magnificationGesture)
            }
            
            // UI overlay
            VStack {
                toolbar
                Spacer()
                legendBar
            }
            
            // Selected body detail
            if let selected = engine.selectedBody {
                bodyDetailPanel(selected)
                    .position(x: 180, y: 200)
            }
        }
        .onReceive(timer) { _ in
            engine.update(deltaTime: 1/60)
        }
        .onAppear {
            engine.loadSampleData()
        }
    }
    
    // MARK: - Space Background
    
    private var spaceBackground: some View {
        ZStack {
            // Deep space
            Color.black
            
            // Nebula clouds
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color.purple, Color.blue, Color.cyan][i].opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(
                        x: CGFloat([-150, 200, 50][i]),
                        y: CGFloat([100, -100, 200][i])
                    )
                    .blur(radius: 80)
            }
            
            // Stars
            Canvas { context, size in
                for _ in 0..<200 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let starSize = CGFloat.random(in: 1...3)
                    let opacity = Double.random(in: 0.3...1.0)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Drawing
    
    private func drawConstellation(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let scale = CGFloat(engine.cameraZoom) * min(size.width, size.height) / 25
        
        // Draw orbits
        if engine.showOrbits {
            for body in engine.bodies where body.bodyType != .sun {
                let orbitRadius = CGFloat(body.orbitRadius) * scale
                let orbitRect = CGRect(
                    x: center.x - orbitRadius,
                    y: center.y - orbitRadius,
                    width: orbitRadius * 2,
                    height: orbitRadius * 2
                )
                
                context.stroke(
                    Path(ellipseIn: orbitRect),
                    with: .color(.white.opacity(0.1)),
                    lineWidth: 0.5
                )
            }
        }
        
        // Draw connections
        if engine.showConnections {
            drawConnections(context: context, center: center, scale: scale)
        }
        
        // Draw bodies (sorted by z for depth)
        let sortedBodies = engine.bodies.sorted { $0.position.z > $1.position.z }
        
        for body in sortedBodies {
            drawBody(body, context: context, center: center, scale: scale)
        }
    }
    
    private func drawConnections(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        for body in engine.bodies {
            let pos1 = project3D(body.position, center: center, scale: scale, rotation: engine.cameraRotation)
            
            // Find similar bodies by embedding
            for other in engine.bodies where other.id != body.id {
                let similarity = cosineSimilarity(body.embedding, other.embedding)
                if similarity > 0.7 {
                    let pos2 = project3D(other.position, center: center, scale: scale, rotation: engine.cameraRotation)
                    
                    var path = Path()
                    path.move(to: pos1)
                    path.addLine(to: pos2)
                    
                    context.stroke(
                        path,
                        with: .color(.white.opacity(Double(similarity - 0.7) * 0.5)),
                        lineWidth: 0.5
                    )
                }
            }
        }
    }
    
    private func drawBody(_ body: CelestialBody, context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        let screenPos = project3D(body.position, center: center, scale: scale, rotation: engine.cameraRotation)
        let depth = body.position.z
        let depthScale = max(0.5, min(1.5, 1 - depth / 30))
        let size = CGFloat(body.size) * CGFloat(depthScale)
        
        let isSelected = engine.selectedBody?.id == body.id
        let isHovered = engine.hoveredBody?.id == body.id
        
        // Glow
        let glowRadius = size * (body.bodyType == .sun ? 3 : (isSelected ? 2.5 : 1.5))
        context.fill(
            Path(ellipseIn: CGRect(
                x: screenPos.x - glowRadius,
                y: screenPos.y - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    body.color.opacity(Double(body.brightness) * 0.6),
                    body.color.opacity(0)
                ]),
                center: screenPos,
                startRadius: 0,
                endRadius: glowRadius
            )
        )
        
        // Body
        context.fill(
            Path(ellipseIn: CGRect(
                x: screenPos.x - size / 2,
                y: screenPos.y - size / 2,
                width: size,
                height: size
            )),
            with: .color(body.color)
        )
        
        // Comet tail
        if body.bodyType == .comet {
            var tailPath = Path()
            tailPath.move(to: screenPos)
            tailPath.addLine(to: CGPoint(
                x: screenPos.x + size * 3,
                y: screenPos.y + size * 0.5
            ))
            
            context.stroke(
                tailPath,
                with: .linearGradient(
                    Gradient(colors: [body.color, body.color.opacity(0)]),
                    startPoint: screenPos,
                    endPoint: CGPoint(x: screenPos.x + size * 3, y: screenPos.y)
                ),
                lineWidth: size * 0.5
            )
        }
        
        // Label
        if isHovered || isSelected || body.bodyType == .sun || body.bodyType == .planet {
            let text = Text(body.name)
                .font(.system(size: 10 * CGFloat(depthScale)))
                .foregroundColor(.white.opacity(Double(depthScale)))
            
            context.draw(text, at: CGPoint(x: screenPos.x, y: screenPos.y + size + 10))
        }
    }
    
    private func project3D(_ position: SIMD3<Float>, center: CGPoint, scale: CGFloat, rotation: SIMD2<Float>) -> CGPoint {
        let cosX = cos(rotation.x)
        let sinX = sin(rotation.x)
        let cosY = cos(rotation.y)
        let sinY = sin(rotation.y)
        
        var rotated = SIMD3<Float>(
            position.x * cosY - position.z * sinY,
            position.y,
            position.x * sinY + position.z * cosY
        )
        
        rotated = SIMD3<Float>(
            rotated.x,
            rotated.y * cosX - rotated.z * sinX,
            rotated.y * sinX + rotated.z * cosX
        )
        
        let perspective: Float = 15
        let z = rotated.z + perspective
        let projectionScale = perspective / max(z, 0.1)
        
        return CGPoint(
            x: center.x + CGFloat(rotated.x * projectionScale) * scale,
            y: center.y + CGFloat(rotated.y * projectionScale) * scale
        )
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, normA: Float = 0, normB: Float = 0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isDragging {
                    let delta = CGPoint(
                        x: value.location.x - lastDragPosition.x,
                        y: value.location.y - lastDragPosition.y
                    )
                    engine.cameraRotation.x += Float(delta.y) * 0.01
                    engine.cameraRotation.y += Float(delta.x) * 0.01
                }
                lastDragPosition = value.location
                isDragging = true
            }
            .onEnded { _ in
                isDragging = false
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                engine.cameraZoom = max(0.3, min(3.0, Float(value)))
            }
    }
    
    // MARK: - UI Components
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Constellation View")
                    .font(.headline)
            }
            
            Divider().frame(height: 20)
            
            Toggle(isOn: $engine.showOrbits) {
                Label("Orbits", systemImage: "circle.dashed")
            }
            .toggleStyle(.button)
            
            Toggle(isOn: $engine.showConnections) {
                Label("Links", systemImage: "link")
            }
            .toggleStyle(.button)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("Speed:")
                    .font(.caption)
                Slider(value: $engine.animationSpeed, in: 0...3)
                    .frame(width: 100)
            }
            
            Text("\(engine.bodies.count) bodies")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    private var legendBar: some View {
        HStack(spacing: 20) {
            ForEach(CelestialBody.BodyType.allCases, id: \.self) { type in
                HStack(spacing: 4) {
                    Image(systemName: type.icon)
                        .font(.caption)
                    Text(type.rawValue)
                        .font(.caption2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func bodyDetailPanel(_ body: CelestialBody) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: body.bodyType.icon)
                    .foregroundStyle(body.color)
                Text(body.name)
                    .font(.headline)
                Spacer()
                Button { engine.selectedBody = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(body.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            
            Divider()
            
            HStack {
                Text("Type:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(body.bodyType.rawValue)
                    .font(.caption)
            }
            
            HStack {
                Text("Orbit:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f AU", body.orbitRadius))
                    .font(.caption)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ConstellationView()
        .frame(width: 1200, height: 800)
}

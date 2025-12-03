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
import Algorithms
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
    var connectionThreshold: Float = 0.7
    var autoRotate = true
    var autoRotateSpeed: Float = 0.35
    var focusFilter: CelestialBody.BodyType?
    var showTrails = true
    var animationSpeed: Float = 1.0
    var time: Float = 0

    struct ParallaxStar {
        let position: CGPoint
        let size: CGFloat
        let baseOpacity: Double
        let twinkleSpeed: Double
        let parallaxDepth: CGFloat
    }

    var starfield: [ParallaxStar] = []
    
    var centralSun: CelestialBody? {
        bodies.first { $0.bodyType == .sun }
    }

    func update(deltaTime: Float) {
        time += deltaTime * animationSpeed

        if autoRotate {
            cameraRotation.y += autoRotateSpeed * deltaTime * 0.5
            cameraRotation.x = min(max(cameraRotation.x, -.pi / 2.2), .pi / 2.2)
        }

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
        if starfield.isEmpty {
            generateStarfield()
        }
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

    func generateStarfield(size: CGSize = CGSize(width: 1400, height: 900)) {
        starfield = (0..<240).map { _ in
            ParallaxStar(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...3),
                baseOpacity: Double.random(in: 0.25...0.9),
                twinkleSpeed: Double.random(in: 0.5...1.5),
                parallaxDepth: CGFloat.random(in: 0.3...1.2)
            )
        }
    }
}

// MARK: - Constellation View

struct ConstellationView: View {
    @State private var engine = ConstellationEngine()
    @State private var isDragging = false
    @State private var lastDragPosition: CGPoint = .zero
    @State private var searchQuery: String = ""
    @State private var showSpatialGrid = false
    @State private var emphasizeRecentChanges = true
    @State private var showAuroraCurtains = true
    @State private var showSolarLensFlares = true
    @State private var showHorizonGlows = true

    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Space background
            spaceBackground

            // 3D constellation
            GeometryReader { geo in
                Canvas { context, size in
                    drawConstellation(context: context, size: size)
                    if showSpatialGrid {
                        drawGrid(context: context, size: size)
                    }
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
            LinearGradient(
                colors: [Color.black, Color(red: 0.03, green: 0.02, blue: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )

            if showHorizonGlows {
                Canvas { context, size in
                    let sweep = Path { path in
                        path.move(to: CGPoint(x: 0, y: size.height * 0.78))
                        path.addCurve(
                            to: CGPoint(x: size.width, y: size.height * 0.72),
                            control1: CGPoint(x: size.width * 0.25, y: size.height * 0.6),
                            control2: CGPoint(x: size.width * 0.65, y: size.height * 0.88)
                        )
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        path.addLine(to: CGPoint(x: 0, y: size.height))
                        path.closeSubpath()
                    }

                    context.fill(
                        sweep,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.purple.opacity(0.28),
                                Color.blue.opacity(0.04)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height * 0.55),
                            endPoint: CGPoint(x: 0, y: size.height)
                        )
                    )

                    let horizonGlow = Path(ellipseIn: CGRect(
                        x: -size.width * 0.1,
                        y: size.height * 0.68,
                        width: size.width * 1.2,
                        height: size.height * 0.6
                    ))

                    context.fill(
                        horizonGlow,
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.cyan.opacity(0.18),
                                Color.clear
                            ]),
                            center: CGPoint(x: size.width / 2, y: size.height * 0.9),
                            startRadius: 0,
                            endRadius: size.height * 0.5
                        )
                    )
                }
                .blur(radius: 36)
            }

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
                if engine.starfield.isEmpty { engine.generateStarfield(size: size) }

                let driftX = sin(Double(engine.time) * 0.15) * 8
                let driftY = cos(Double(engine.time) * 0.12) * 6

                for star in engine.starfield {
                    let parallax = 1 + star.parallaxDepth * 0.25
                    let twinkle = star.baseOpacity + sin(Double(engine.time) * star.twinkleSpeed + Double(star.position.x) * 0.01) * 0.25
                    let x = star.position.x + CGFloat(driftX) * star.parallaxDepth
                    let y = star.position.y + CGFloat(driftY) * star.parallaxDepth

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: star.size * parallax, height: star.size * parallax)),
                        with: .color(.white.opacity(max(0.05, min(1.0, twinkle))))
                    )
                }
            }

            if showAuroraCurtains {
                Canvas { context, size in
                    let time = engine.time
                    for band in 0..<3 {
                        var path = Path()
                        let baseY = size.height * (0.15 + CGFloat(band) * 0.08)
                        path.move(to: CGPoint(x: -size.width * 0.1, y: baseY))

                        let segments = 14
                        for i in 0...segments {
                            let progress = CGFloat(i) / CGFloat(segments)
                            let x = size.width * (progress * 1.2 - 0.1)
                            let undulation = sin(progress * 8 + CGFloat(time) * (0.6 + CGFloat(band) * 0.15))
                            let y = baseY + undulation * 30 + cos(CGFloat(time) * 0.4 + progress * 6) * 18
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: size.width * 1.1, y: size.height * 0.05))
                        path.addLine(to: CGPoint(x: -size.width * 0.1, y: size.height * 0.05))
                        path.closeSubpath()

                        let colors: [Color] = band == 0 ? [.cyan, .mint, .blue] : band == 1 ? [.purple, .blue, .mint] : [.pink, .purple, .blue]
                        context.fill(
                            path,
                            with: .linearGradient(
                                Gradient(colors: colors.map { $0.opacity(0.16) } + [Color.clear]),
                                startPoint: CGPoint(x: size.width / 2, y: 0),
                                endPoint: CGPoint(x: size.width / 2, y: size.height * 0.4)
                            )
                        )

                        context.stroke(
                            path.offsetBy(dx: 0, dy: 6),
                            with: .linearGradient(
                                Gradient(colors: colors.map { $0.opacity(0.35) }),
                                startPoint: CGPoint(x: 0, y: 0),
                                endPoint: CGPoint(x: size.width, y: size.height * 0.25)
                            ),
                            lineWidth: 1.2
                        )
                    }
                }
                .blendMode(.screen)
                .opacity(0.75)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Drawing
    
    private func drawConstellation(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let scale = CGFloat(engine.cameraZoom) * min(size.width, size.height) / 25

        let visibleBodies = engine.bodies.filter { body in
            (engine.focusFilter == nil || body.bodyType == engine.focusFilter) &&
            (searchQuery.isEmpty || body.name.lowercased().contains(searchQuery.lowercased()))
        }

        // Draw orbits
        if engine.showOrbits {
            for body in visibleBodies where body.bodyType != .sun {
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
            drawConnections(context: context, center: center, scale: scale, bodies: visibleBodies)
        }

        // Draw bodies (sorted by z for depth)
        let sortedBodies = visibleBodies.sorted { $0.position.z > $1.position.z }
        
        for body in sortedBodies {
            drawBody(body, context: context, center: center, scale: scale)
        }
    }

    private func drawConnections(context: GraphicsContext, center: CGPoint, scale: CGFloat, bodies: [CelestialBody]) {
        for pair in bodies.combinations(ofCount: 2) {
            guard let first = pair.first, let second = pair.last else { continue }
            let similarity = cosineSimilarity(first.embedding, second.embedding)
            guard similarity >= engine.connectionThreshold else { continue }

            let pos1 = project3D(first.position, center: center, scale: scale, rotation: engine.cameraRotation)
            let pos2 = project3D(second.position, center: center, scale: scale, rotation: engine.cameraRotation)

            let cometLinked = first.bodyType == .comet || second.bodyType == .comet
            let pulse = 0.5 + 0.5 * sin(Double(engine.time) * (cometLinked ? 2.2 : 1.4) + Double(similarity * 4))
            let hueColor: Color = cometLinked ? .orange : .white

            var path = Path()
            path.move(to: pos1)
            path.addLine(to: pos2)

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        hueColor.opacity(Double(similarity - engine.connectionThreshold) * 0.3),
                        hueColor.opacity(Double(similarity - engine.connectionThreshold) * (0.5 + pulse * 0.3))
                    ]),
                    startPoint: pos1,
                    endPoint: pos2
                ),
                lineWidth: 0.5 + (cometLinked ? 0.35 : 0)
            )

            if cometLinked {
                context.stroke(
                    path.strokedPath(.init(lineWidth: 0.25, dash: [3, 9], dashPhase: CGFloat(engine.time) * 6)),
                    with: .color(.orange.opacity(0.35))
                )
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

        if body.bodyType == .sun {
            let pulse = 1 + 0.08 * sin(Double(engine.time) * 0.8)
            let coronaRadius = size * 2 * pulse

            for ring in 0..<3 {
                let ringSize = coronaRadius + CGFloat(ring) * size * 0.6
                var ringPath = Path(ellipseIn: CGRect(
                    x: screenPos.x - ringSize / 2,
                    y: screenPos.y - ringSize / 2,
                    width: ringSize,
                    height: ringSize
                ))
                ringPath = ringPath.strokedPath(.init(lineWidth: CGFloat(1 + ring), dash: [6, 10], dashPhase: CGFloat(engine.time) * CGFloat(4 + ring)))
                context.stroke(
                    ringPath,
                    with: .radialGradient(
                        Gradient(colors: [body.color.opacity(0.2), .clear]),
                        center: screenPos,
                        startRadius: 0,
                        endRadius: ringSize / 2
                    ),
                    lineWidth: CGFloat(1 + ring)
                )
            }

            if showSolarLensFlares {
                let flareColors: [Color] = [body.color.opacity(0.32), .white.opacity(0.18), body.color.opacity(0.08)]
                let spokeCount = 12
                for i in 0..<spokeCount {
                    let angle = Double(i) / Double(spokeCount) * .pi * 2 + Double(engine.time) * 0.08
                    let length = size * (2.2 + CGFloat(i % 3) * 0.4)
                    var ray = Path()
                    ray.move(to: screenPos)
                    ray.addLine(to: CGPoint(
                        x: screenPos.x + cos(angle) * length,
                        y: screenPos.y + sin(angle) * length
                    ))
                    context.stroke(
                        ray,
                        with: .linearGradient(
                            Gradient(colors: flareColors),
                            startPoint: screenPos,
                            endPoint: CGPoint(
                                x: screenPos.x + cos(angle) * length,
                                y: screenPos.y + sin(angle) * length
                            )
                        ),
                        lineWidth: 1.2
                    )
                }

                let flareDiamonds = 6
                for i in 0..<flareDiamonds {
                    let radius = size * (1.2 + CGFloat(i) * 0.5)
                    let opacity = 0.28 - Double(i) * 0.04
                    let rotation = CGFloat(engine.time) * 0.3 + CGFloat(i) * 0.5
                    var diamond = Path()
                    diamond.addRoundedRect(in: CGRect(
                        x: screenPos.x - radius,
                        y: screenPos.y - radius * 0.24,
                        width: radius * 2,
                        height: radius * 0.48
                    ), cornerSize: CGSize(width: 12, height: 12))
                    diamond = diamond
                        .applying(.init(translationX: -screenPos.x, y: -screenPos.y))
                        .applying(.init(rotationAngle: rotation))
                        .applying(.init(translationX: screenPos.x, y: screenPos.y))
                    context.stroke(
                        diamond,
                        with: .color(body.color.opacity(opacity)),
                        lineWidth: 0.8
                    )
                }
            }
        }

        // Glow
        let glowRadius = size * (body.bodyType == .sun ? 3 : (isSelected ? 2.5 : 1.5))
        let baseOpacity = engine.focusFilter == nil ? 1.0 : (body.bodyType == engine.focusFilter ? 1.0 : 0.15)
        let nameMatches = searchQuery.isEmpty || body.name.lowercased().contains(searchQuery.lowercased())
        let displayOpacity = nameMatches ? baseOpacity : 0.1
        context.fill(
            Path(ellipseIn: CGRect(
                x: screenPos.x - glowRadius,
                y: screenPos.y - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )),
            with: .radialGradient(
                Gradient(colors: [
                    body.color.opacity(Double(body.brightness) * 0.6 * displayOpacity),
                    body.color.opacity(0)
                ]),
                center: screenPos,
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        // Orbital motion trail
        if engine.showTrails && body.bodyType != .sun {
            let tailPhase = body.orbitPhase + max(0, engine.time - 0.8) * body.orbitSpeed
            let tailRadius = body.orbitRadius
            let tailPosition = SIMD3<Float>(
                cos(tailPhase) * tailRadius,
                sin(tailPhase * 0.3) * tailRadius * 0.2,
                sin(tailPhase) * tailRadius
            )

            let tailScreen = project3D(tailPosition, center: center, scale: scale, rotation: engine.cameraRotation)
            var trailPath = Path()
            trailPath.move(to: tailScreen)
            trailPath.addLine(to: screenPos)

            context.stroke(
                trailPath,
                with: .linearGradient(
                    Gradient(colors: [body.color.opacity(0.05), body.color.opacity(displayOpacity * 0.6)]),
                    startPoint: tailScreen,
                    endPoint: screenPos
                ),
                lineWidth: size * 0.12
            )
        }

        // Body
        context.fill(
            Path(ellipseIn: CGRect(
                x: screenPos.x - size / 2,
                y: screenPos.y - size / 2,
                width: size,
                height: size
            )),
            with: .color(body.color.opacity(displayOpacity))
        )

        // Comet tail
        if body.bodyType == .comet && engine.showTrails {
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

        if emphasizeRecentChanges && body.bodyType == .comet {
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: screenPos.x - size,
                    y: screenPos.y - size,
                    width: size * 2,
                    height: size * 2
                )),
                with: .color(body.color.opacity(0.3)),
                lineWidth: 1.5
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

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 120
        let rows = Int(size.height / spacing)
        let cols = Int(size.width / spacing)

        for row in 0...rows {
            let y = CGFloat(row) * spacing
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.white.opacity(0.05)), lineWidth: 0.5)
        }

        for col in 0...cols {
            let x = CGFloat(col) * spacing
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.white.opacity(0.05)), lineWidth: 0.5)
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

    private func connectedBodies(to body: CelestialBody) -> [CelestialBody] {
        engine.bodies
            .filter { $0.id != body.id }
            .map { ($0, cosineSimilarity($0.embedding, body.embedding)) }
            .filter { $0.1 >= engine.connectionThreshold }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
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

            TextField("Search bodies", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)

            Picker("Type", selection: Binding(
                get: { engine.focusFilter ?? .sun },
                set: { value in
                    engine.focusFilter = value == .sun ? nil : value
                }
            )) {
                Text("All Bodies").tag(CelestialBody.BodyType.sun)
                ForEach(CelestialBody.BodyType.allCases.filter { $0 != .sun }, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 140)

            Toggle(isOn: $engine.showOrbits) {
                Label("Orbits", systemImage: "circle.dashed")
            }
            .toggleStyle(.button)

            Toggle(isOn: $engine.showConnections) {
                Label("Links", systemImage: "link")
            }
            .toggleStyle(.button)

            Toggle(isOn: $showSpatialGrid) {
                Label("Grid", systemImage: "square.grid.3x3")
            }
            .toggleStyle(.button)

            Toggle(isOn: $engine.showTrails) {
                Label("Trails", systemImage: "sparkles")
            }
            .toggleStyle(.button)

            Toggle(isOn: $showAuroraCurtains) {
                Label("Aurora", systemImage: "wind")
            }
            .toggleStyle(.button)

            Toggle(isOn: $showSolarLensFlares) {
                Label("Flares", systemImage: "sun.max")
            }
            .toggleStyle(.button)

            Toggle(isOn: $showHorizonGlows) {
                Label("Horizon", systemImage: "circle.bottomhalf.fill")
            }
            .toggleStyle(.button)

            Spacer()

            HStack(spacing: 8) {
                Text("Speed:")
                    .font(.caption)
                Slider(value: $engine.animationSpeed, in: 0...3)
                    .frame(width: 100)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Connection Threshold")
                    .font(.caption2)
                Slider(value: $engine.connectionThreshold, in: 0.4...0.95)
                    .frame(width: 140)
            }

            VStack(alignment: .leading, spacing: 2) {
                Toggle("Auto Rotate", isOn: $engine.autoRotate)
                    .toggleStyle(.switch)
                    .font(.caption)
                Slider(value: $engine.autoRotateSpeed, in: 0...1.0) {
                    Text("Rotate")
                }
                .frame(width: 140)
            }

            Button {
                withAnimation {
                    engine.cameraRotation = .zero
                    engine.cameraZoom = 1.0
                }
            } label: {
                Label("Reset Camera", systemImage: "scope")
            }
            .buttonStyle(.bordered)

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
                Text("Connections:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(connectedBodies(to: body).count) strong links")
                    .font(.caption)
            }

            if let closest = connectedBodies(to: body).first {
                Text("Closest: \(closest.name)")
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

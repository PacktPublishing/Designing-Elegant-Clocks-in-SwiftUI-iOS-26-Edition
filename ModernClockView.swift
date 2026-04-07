//
//  ModernClockView.swift
//  SwiftUIBootcamp_Beta26_2
//
//  Created by DevTechie on 8/28/25.
//

import SwiftUI

struct ModernClockView: View {
    
    @State private var viewModel = ClockViewModel(timeZone: .current)
    @State private var showNumbers = false
    @Environment(\.colorScheme) private var colorScheme
    
    @ViewBuilder
    private var digitalTimeView: some View {
        VStack {
            Text(DateFormatter.timeFormatter(for: viewModel.timeZone).string(from: viewModel.currentTime.date))
                .font(.system(size: 32, weight: .thin, design: .monospaced))
            Text(DateFormatter.dateFormatter(for: viewModel.timeZone).string(from: viewModel.currentTime.date))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(viewModel.timeZone.description)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var analogClockView: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.primary.opacity(0.5), Color.clear], center: .center, startRadius: 0, endRadius: 200))
            
            ClockFace(showNumbers: showNumbers)
            
            ForEach(ClockHandType.allCases, id: \.self) { handType in
                ClockHand(type: handType, time: viewModel.currentTime)
                    .animation(.linear, value: viewModel.currentTime)
            }
            
            Circle()
                .fill(Color.primary)
                .frame(width: 25, height: 25)
            
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
        }
        //.aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    private var timeZonePickerView: some View {
        Picker("Time Zone", selection: Binding(
            get: { viewModel.timeZone.identifier },
            set: { newValue in
                if let tz = TimeZone(identifier: newValue) {
                    viewModel = ClockViewModel(timeZone: tz)
                    viewModel.startTimer()
                }
            }
        )) {
            ForEach(viewModel.commonTimeZones, id: \.self) { tz in
                Text(tz).tag(tz)
            }
        }
        .pickerStyle(.menu)
    }
    
    @ViewBuilder
    private var controlsView: some View {
        HStack {
            timeZonePickerView
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNumbers.toggle()
                }
            } label: {
                Image(systemName: showNumbers ? "textformat.123" : "textformat")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        //        LinearGradient(colors: [
        //            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground),
        //            colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6),
        //        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        //        .ignoresSafeArea()
        //
        MeshGradient(width: 3, height: 3, points: [
            [0,0], [0.5, 0], [1.0, 0],
            [0,0.5], [0.5, 0.1], [1.0, 0.5],
            [0,1.0], [0.5, 1.0], [1.0, 1.0]
        ], colors: [
            .black, .black, .black,
            .black, .blue.opacity(0.6), .black,
            .black, .black, .black
        ])
        .ignoresSafeArea()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            digitalTimeView
                .padding()
                .glassEffect(.clear)
            analogClockView
            controlsView
        }
        .padding()
        .background(backgroundView)
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .preferredColorScheme(.dark)
    }
}


extension DateFormatter {
    //    static let timeFormatter: DateFormatter = {
    //        let f = DateFormatter()
    //        f.dateStyle = .none
    //        f.timeStyle = .medium
    //        return f
    //    }()
    //
    //    static let dateFormatter: DateFormatter = {
    //        let f = DateFormatter()
    //        f.dateStyle = .full
    //        f.timeStyle = .none
    //        return f
    //    }()
    
    static func timeFormatter(for timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        f.timeZone = timeZone
        return f
    }
    
    static func dateFormatter(for timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        f.timeZone = timeZone
        return f
    }
}

#Preview {
    ModernClockView()
        .preferredColorScheme(.dark)
}

struct TimeModel: Equatable {
    let hours: Int
    let minutes: Int
    let seconds: Int
    let date: Date
    
    init(date: Date = Date(), timeZone: TimeZone = .current) {
        self.date = date
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour24 = calendar.component(.hour, from: date)
        self.hours = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        self.minutes = calendar.component(.minute, from: date)
        self.seconds = calendar.component(.second, from: date)
    }
}

enum ClockHandType: CaseIterable {
    case hour, minute, second
    
    var color: Color {
        switch self {
        case .hour, .minute: return Color.primary
        case .second: return Color.red
        }
    }
    
    var thickness: CGFloat {
        switch self {
        case .hour: return 8
        case .minute: return 4
        case .second: return 2
        }
    }
    
    var length: CGFloat {
        switch self {
        case .hour: return 0.55
        case .minute: return 0.8
        case .second: return 0.9
        }
    }
    
    var capRadius: CGFloat {
        switch self {
        case .hour: return 4
        case .minute: return 3
        case .second: return 2
        }
    }
    
    func angle(for time: TimeModel) -> Angle {
        switch self {
        case .hour:
            return Angle(degrees: (360.0 / 12.0) * (Double(time.hours) + Double(time.minutes) / 60.0))
        case .minute:
            return Angle(degrees: Double(time.minutes) * 6.0)
        case .second:
            return Angle(degrees: Double(time.seconds) * 6.0)
        }
    }
}

import Combine
import Observation

@MainActor
@Observable
final class ClockViewModel {
    private(set) var currentTime = TimeModel()
    private var timerCancellable: AnyCancellable?
    
    var timeZone: TimeZone
    
    let commonTimeZones: [String] = ["America/New_York", "America/Los_Angeles", "Europe/London", "Europe/Paris", "Europe/Berlin", "Asia/Tokyo", "Asia/Shanghai", "Asia/Dubai", "Canada/Eastern"]
    
    init(timeZone: TimeZone = TimeZone(identifier: "Asia/Tokyo")!) {
        self.timeZone = timeZone
    }
    
    private func updateTime() {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        currentTime = TimeModel(date: Date(), timeZone: timeZone)
    }
    
    func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

struct ClockHand: View {
    let type: ClockHandType
    let time: TimeModel
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius: CGFloat = min(geometry.size.width, geometry.size.height) / 2
            
            ZStack {
                Path { path in
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: center.x,y: center.y - (type.length * radius)))
                }
                .stroke(type.color, style: StrokeStyle(lineWidth: type.thickness, lineCap: .round))
                .rotationEffect(type.angle(for: time))
                
                Circle()
                    .fill(type.color)
                    .frame(width: type.capRadius * 2, height: type.capRadius * 2)
            }
        }
    }
}

struct HourMarker: View {
    let hour: Int
    let center: CGPoint
    let radius: CGFloat
    let showNumbers: Bool
    
    var body: some View {
        let angle = Double(hour) * 30 - 90
        let markerLength: CGFloat = 20
        let numberRadius = radius - 35
        
        Group {
            Path { path in
                let startRadius = radius - markerLength
                let endRadius = radius - 5
                
                let startPoint = CGPoint(
                    x: center.x + startRadius * cos(angle * .pi / 180),
                    y: center.y + startRadius * sin(angle * .pi / 180)
                )
                
                let endPoint = CGPoint(
                    x: center.x + endRadius * cos(angle * .pi / 180),
                    y: center.y + endRadius * sin(angle * .pi / 180)
                )
                
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            
            Text(showNumbers ? "\(hour)" : romanNumeral(for: hour))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .background {
                    Circle()
                        .frame(width: 30, height: 30)
                        .glassEffect()
                }
                .position(
                    x: center.x + numberRadius * cos(angle * .pi / 180),
                    y: center.y + numberRadius * sin(angle * .pi / 180)
                )
            
        }
    }
    
    private func romanNumeral(for value: Int) -> String {
        guard value > 0 && value < 4000 else { return "" }
        
        let romanValues: [(Int, String)] = [
            (1000, "M"),
            (900, "CM"),
            (500, "D"),
            (400, "CD"),
            (100, "C"),
            (90, "XC"),
            (50, "L"),
            (40, "XL"),
            (10, "X"),
            (9, "IX"),
            (5, "V"),
            (4, "IV"),
            (1, "I")
        ]
        
        var number = value
        var result = ""
        
        for (num, roman) in romanValues {
            while number >= num {
                result += roman
                number -= num
            }
        }
        
        return result
    }
}

struct MinuteMarker: View {
    let minute: Int
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let angle = Double(minute) * 6 - 90
        let markerLength: CGFloat = 8
        
        Path { path in
            let startRadius = radius - markerLength
            let endRadius = radius - 2
            
            let startPoint = CGPoint(
                x: center.x + startRadius * cos(angle * .pi / 180),
                y: center.y + startRadius * sin(angle * .pi / 180)
            )
            
            let endPoint = CGPoint(
                x: center.x + endRadius * cos(angle * .pi / 180),
                y: center.y + endRadius * sin(angle * .pi / 180)
            )
            
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 1))
    }
}

struct ClockFace: View {
    let showNumbers: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [Color.primary.opacity(0.1), Color.primary], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                
                
                ForEach(1...12, id: \.self) { hour in
                    HourMarker(hour: hour, center: center, radius: radius, showNumbers: showNumbers)
                }
                
                ForEach(1...60, id: \.self) { minute in
                    if minute % 5 != 0 {
                        MinuteMarker(minute: minute, center: center, radius: radius)
                    }
                }
            }
        }
    }
}

#Preview {
    ClockFace(showNumbers: false)
}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PrePregnancyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var cycleData: [Date: CycleDayType] = [:]
    @State private var isLoading = true
    
    // Settings states
    @State private var showSettingsSheet = false
    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var showFertileWindow = true
    
    @State private var showInfoPopover = false
    
    // Dialog states
    @State private var showDateActionDialog = false
    @State private var selectedDate: Date? = nil
    @State private var selectedDay: Int = 0
    @State private var cycleEvents: [CycleEvent] = []
    
    // Calendar constants
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // Title bar
                    titleBar
                    
                    // Menstrual Cycle Tracker
                    cycleTrackerCard
                    
                    // Cycle logs
                    cycleLogs
                    
                    // Pregnancy Test Entries
                    sectionButton(title: "Pregnancy Test Entries", action: {
                        // Navigate to pregnancy test entries
                    })
                    
                    // Conception Attempts
                    sectionButton(title: "Conception Attempts", action: {
                        // Navigate to conception attempts tracking
                    })
                    
                    // Wellness Tips & Advice
                    wellnessTipsCard
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                loadCycleData()
                loadCycleEvents()
                loadCycleSettings()
            }
            // FAB for adding data
            .overlay(
                addButton,
                alignment: .bottomTrailing
            )
            
            // Date action dialog
            if showDateActionDialog, let selectedDate = selectedDate {
                dateActionDialog(date: selectedDate, day: selectedDay)
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            cycleSettingsSheet
        }
    }
    
    // MARK: - View Components
    
    private var titleBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Pre-Pregnancy Tracking")
                .font(AppFont.titleMedium())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // Settings or more options
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(.top, 10)
    }
    
    private var cycleTrackerCard: some View {
        VStack(spacing: 15) {
            // Header with title and settings
            HStack {
                Text("Menstrual Cycle Tracker")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showSettingsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 5)
            
            // Month navigation with animation
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navigateMonth(forward: false)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("\(monthNames[selectedMonth-1]) \(String(selectedYear))")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .id("\(selectedMonth)-\(selectedYear)") // For transition animation
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navigateMonth(forward: true)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 15)
            
            // Weekday headers with refined styling
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppFont.small())
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.top, 5)
            
            // Calendar grid
            calendarGrid
                .padding(.vertical, 5)
            
            // Legend with improved visualization
            HStack(spacing: 30) {
                legendItem(color: .pink, text: "Period", icon: "drop.fill")
                legendItem(color: .green, text: "Ovulation", icon: "sparkles")
                if showFertileWindow {
                    legendItem(color: .yellow, text: "Fertile", icon: "star.fill")
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            
            // Improved instructions
            Text("Tap a date to log period or ovulation")
                .font(AppFont.caption())
                .foregroundColor(.gray)
                .padding(.top, 5)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Cycle settings sheet
    private var cycleSettingsSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") {
                            showSettingsSheet = false
                        }
                        .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Text("Cycle Settings")
                            .font(AppFont.titleSmall())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveCycleSettings()
                            updateFertileDays()
                            showSettingsSheet = false
                        }
                        .foregroundColor(.pink)
                        .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.white)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Cycle Length Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cycle Settings")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    // Average Cycle Length
                                    HStack {
                                        Text("Average Cycle Length")
                                            .font(AppFont.body())
                                        
                                        Spacer()
                                        
                                        Picker("\(cycleLength) days", selection: $cycleLength) {
                                            ForEach(21...35, id: \.self) { days in
                                                Text("\(days) days").tag(days)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.pink)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    
                                    Divider()
                                        .padding(.leading)
                                    
                                    // Average Period Length
                                    HStack {
                                        Text("Average Period Length")
                                            .font(AppFont.body())
                                        
                                        Spacer()
                                        
                                        Picker("\(periodLength) days", selection: $periodLength) {
                                            ForEach(2...10, id: \.self) { days in
                                                Text("\(days) days").tag(days)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .accentColor(.pink)
                                    }
                                    .padding()
                                    .background(Color.white)
                                }
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                            .padding(.top)
                            
                            // Display Options
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Display Options")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack {
                                    Toggle("Show Fertile Window", isOn: $showFertileWindow)
                                        .padding()
                                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                            
                            // Information Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Information")
                                    .font(AppFont.body().bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("How Cycle Predictions Work")
                                        .font(AppFont.body().bold())
                                    
                                    Text("Your cycle begins on the first day of your period. The fertile window is calculated based on your average cycle length and typically occurs 12-16 days before your next period is expected to start.")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Cycle logs section
    private var cycleLogs: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cycle Logs")
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                // Filter menu
                Menu {
                    Button(action: { filterCycleEvents(type: nil) }) {
                        Label("All Events", systemImage: "list.bullet")
                    }
                    Button(action: { filterCycleEvents(type: .period) }) {
                        Label("Period Only", systemImage: "drop.fill")
                    }
                    Button(action: { filterCycleEvents(type: .ovulation) }) {
                        Label("Ovulation Only", systemImage: "sparkles")
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(AppFont.caption())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            // Cycle statistics card
            cycleStatisticsCard
                .padding(.top, 5)
            
            // Logs list
            VStack(spacing: 10) {
                if cycleEvents.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 30))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No events recorded for this month")
                                .font(AppFont.caption())
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap on calendar dates to start tracking")
                                .font(AppFont.caption())
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 30)
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                } else {
                    ForEach(cycleEvents.sorted(by: { $0.date > $1.date }), id: \.id) { event in
                        cycleEventRow(event: event)
                            .contextMenu {
                                Button(action: {
                                    addNote(to: event)
                                }) {
                                    Label("Add Note", systemImage: "square.and.pencil")
                                }
                                Button(role: .destructive, action: {
                                    deleteEvent(event)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // Cycle statistics card showing insights about the cycle
    private var cycleStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Cycle Insights")
                .font(AppFont.body().bold())
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.top, 10)
            
            HStack(spacing: 20) {
                // Average cycle length
                statisticItem(
                    icon: "clock",
                    value: "\(calculateAverageCycleLength()) days",
                    label: "Avg. Cycle"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Fertile window info
                statisticItem(
                    icon: "star.fill",
                    value: "\(calculateFertileWindowDays()) days",
                    label: "Fertile Window"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Next period prediction
                statisticItem(
                    icon: "calendar",
                    value: nextPeriodPrediction(),
                    label: "Next Period"
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
    
    private func statisticItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.pink)
            
            Text(value)
                .font(AppFont.body().bold())
                .foregroundColor(.black)
            
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func cycleEventRow(event: CycleEvent) -> some View {
        HStack {
            // Icon based on event type
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [colorFor(cycleDayType: event.type), colorFor(cycleDayType: event.type).opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: colorFor(cycleDayType: event.type).opacity(0.3), radius: 2, x: 0, y: 1)
                
                Image(systemName: iconFor(cycleDayType: event.type))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titleFor(cycleDayType: event.type))
                    .font(AppFont.body().bold())
                    .foregroundColor(.primary)
                
                Text(formattedDate(event.date))
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                // Show notes if available
                if !event.notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Text(event.notes)
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeAgo(from: event.timestamp))
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                
                // Add indicators for pattern matching
                if isCycleStart(date: event.date) && event.type == .period {
                    Text("Cycle Start")
                        .font(AppFont.caption().italic())
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
    
    private var calendarGrid: some View {
        let days = daysInMonth(month: selectedMonth, year: selectedYear)
        let firstWeekday = firstDayOfMonth(month: selectedMonth, year: selectedYear)
        
        return VStack(spacing: 8) {
            ForEach(0..<6) { row in
                HStack(spacing: 8) {
                    ForEach(0..<7) { column in
                        let day = (row * 7 + column) - firstWeekday + 1
                        if day > 0 && day <= days {
                            calendarDay(day: day)
                                .id("day-\(selectedMonth)-\(selectedYear)-\(day)")
                        } else {
                            Color.clear.frame(width: 38, height: 38)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }
    
    private func calendarDay(day: Int) -> some View {
        let date = dateFor(day: day, month: selectedMonth, year: selectedYear)
        let cycleDayType = cycleData[date] ?? .none
        let isToday = Calendar.current.isDateInToday(date)
        
        return ZStack {
            // Background circle with gradient for marked days
            if cycleDayType != .none {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorFor(cycleDayType: cycleDayType),
                                colorFor(cycleDayType: cycleDayType).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: colorFor(cycleDayType: cycleDayType).opacity(0.3), radius: 2, x: 0, y: 1)
            } else {
                Circle()
                    .fill(isToday ? Color.blue.opacity(0.1) : Color.white)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.blue : Color.gray.opacity(0.3), lineWidth: isToday ? 1.5 : 1)
                    )
            }
            
            // Day number
            Text("\(day)")
                .font(isToday ? AppFont.body().weight(.semibold) : AppFont.body())
                .foregroundColor(cycleDayType != .none ? .white : (isToday ? .blue : .primary))
                .fontWeight(isToday ? .semibold : .regular)
            
            // Small indicator icons for each type
            if cycleDayType == .period {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            } else if cycleDayType == .ovulation {
                Image(systemName: "sparkles")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            } else if cycleDayType == .fertile {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .offset(y: 10)
            }
        }
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .scaleEffect(cycleDayType != .none ? 1.05 : 1.0)
        // Tap gesture with haptic feedback - now shows dialog
        .onTapGesture {
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            
            self.selectedDate = date
            self.selectedDay = day
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDateActionDialog = true
            }
        }
    }
    
    // Custom dialog for date action
    private func dateActionDialog(date: Date, day: Int) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDateActionDialog = false
                    }
                }
            
            // Dialog content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Mark Day \(day)")
                        .font(AppFont.titleMedium())
                        .foregroundColor(.primary)
                    
                    Text("\(monthNames[selectedMonth-1]) \(day), \(selectedYear)")
                        .font(AppFont.body())
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Options
                VStack(spacing: 15) {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation {
                            markDate(date: date, as: .period)
                            addCycleEvent(date: date, type: .period)
                            showDateActionDialog = false
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.pink)
                                .frame(width: 35)
                            
                            Text("Period")
                                .font(AppFont.body())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if cycleData[date] == .period {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation {
                            markDate(date: date, as: .ovulation)
                            addCycleEvent(date: date, type: .ovulation)
                            showDateActionDialog = false
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                                .frame(width: 35)
                            
                            Text("Ovulation")
                                .font(AppFont.body())
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if cycleData[date] == .ovulation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if cycleData[date] != .none {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            withAnimation {
                                cycleData[date] = .none
                                removeCycleEvent(date: date)
                                updateFertileDays()
                                saveCycleData()
                                showDateActionDialog = false
                            }
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22))
                                    .foregroundColor(.red)
                                    .frame(width: 35)
                                
                                Text("Clear Day")
                                    .font(AppFont.body())
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDateActionDialog = false
                    }
                }) {
                    Text("Cancel")
                        .font(AppFont.body().weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 30)
            .transition(.scale)
        }
    }
    
    private func legendItem(color: Color, text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(AppFont.caption())
                .foregroundColor(.gray)
        }
    }
    
    private func sectionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppFont.titleSmall())
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var wellnessTipsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Wellness Tips & Advice")
                .font(AppFont.titleSmall())
                .foregroundColor(.black)
            
            HStack(spacing: 15) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pink)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Take Folic Acid")
                        .font(AppFont.body())
                        .foregroundColor(.black)
                    
                    Text("Start taking a prenatal vitamin with folic acid at least 3 months before conception to help prevent neural tube defects")
                        .font(AppFont.caption())
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(Color.pink.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var addButton: some View {
        Button(action: {
            // Show add options for period, test, etc.
        }) {
            ZStack {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func navigateMonth(forward: Bool) {
        if forward {
            if selectedMonth == 12 {
                selectedMonth = 1
                selectedYear += 1
            } else {
                selectedMonth += 1
            }
        } else {
            if selectedMonth == 1 {
                selectedMonth = 12
                selectedYear -= 1
            } else {
                selectedMonth -= 1
            }
        }
        
        loadCycleData()
        loadCycleEvents()
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func firstDayOfMonth(month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        return calendar.component(.weekday, from: date) - 1 // 0 = Sunday
    }
    
    private func dateFor(day: Int, month: Int, year: Int) -> Date {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: dateComponents)!
    }
    
    private func colorFor(cycleDayType: CycleDayType) -> Color {
        switch cycleDayType {
        case .period:
            return .pink
        case .ovulation:
            return .green
        case .fertile:
            return .yellow
        case .none:
            return .white
        }
    }
    
    private func iconFor(cycleDayType: CycleDayType) -> String {
        switch cycleDayType {
        case .period:
            return "drop.fill"
        case .ovulation:
            return "sparkles"
        case .fertile:
            return "star.fill"
        case .none:
            return "circle"
        }
    }
    
    private func titleFor(cycleDayType: CycleDayType) -> String {
        switch cycleDayType {
        case .period:
            return "Period Day"
        case .ovulation:
            return "Ovulation Day"
        case .fertile:
            return "Fertile Day"
        case .none:
            return "Normal Day"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func markDate(date: Date, as type: CycleDayType) {
        // If already marked as this type, clear it
        if cycleData[date] == type {
            cycleData[date] = .none
        } else {
            cycleData[date] = type
        }
        
        // Save to Firestore
        saveCycleData()
        
        // Update fertile days based on period and ovulation
        withAnimation(.easeInOut(duration: 0.3)) {
            updateFertileDays()
        }
    }
    
    private func addCycleEvent(date: Date, type: CycleDayType) {
        // Add to local events list
        let newEvent = CycleEvent(
            id: UUID().uuidString,
            date: date,
            type: type,
            timestamp: Date(),
            notes: ""
        )
        
        // Check if we already have this event (to avoid duplicates)
        if !cycleEvents.contains(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.type == type 
        }) {
            cycleEvents.append(newEvent)
            saveCycleEvent(event: newEvent)
        }
    }
    
    private func removeCycleEvent(date: Date) {
        // Remove from local events list
        cycleEvents.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        
        // Remove from Firestore
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        if let year = components.year, let month = components.month, let day = components.day {
            db.collection("users").document(user.uid)
                .collection("cycleEvents")
                .whereField("year", isEqualTo: year)
                .whereField("month", isEqualTo: month)
                .whereField("day", isEqualTo: day)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        for doc in documents {
                            doc.reference.delete()
                        }
                    }
                }
        }
    }
    
    private func updateFertileDays() {
        // Logic to calculate fertile window based on period and ovulation dates
        
        // Clear existing fertile days
        for (date, type) in cycleData {
            if type == .fertile {
                cycleData[date] = .none
            }
        }
        
        if !showFertileWindow {
            saveCycleData()
            return
        }
        
        // Find period days
        let periodDays = cycleData.filter { $0.value == .period }.map { $0.key }
        
        // If no period days, we can't calculate
        guard let mostRecentPeriod = periodDays.max() else { return }
        
        // Calculate ovulation day (typically cycle length - 14)
        let ovulationDay = cycleLength - 14
        
        // Mark fertile window (typically 5 days before ovulation and 1-2 days after)
        let calendar = Calendar.current
        for i in (ovulationDay-5)...(ovulationDay+1) {
            if let fertileDay = calendar.date(byAdding: .day, value: i, to: mostRecentPeriod) {
                // Don't override existing markings
                if cycleData[fertileDay] == .none {
                    cycleData[fertileDay] = .fertile
                }
            }
        }
        
        saveCycleData()
    }
    
    // Filter cycle events by type
    private func filterCycleEvents(type: CycleDayType?) {
        loadCycleEvents(filterType: type)
    }
    
    // Check if a date is the start of a menstrual cycle
    private func isCycleStart(date: Date) -> Bool {
        // Get all period days
        let periodDays = cycleEvents.filter { $0.type == .period }.map { $0.date }
        
        // Sort them chronologically
        let sortedDays = periodDays.sorted()
        
        // If this is the first period day after a gap, it's a cycle start
        if let index = sortedDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
            if index == 0 {
                return true
            }
            
            // Check if there's more than 2 days gap with previous period day
            let previousDate = sortedDays[index - 1]
            let days = Calendar.current.dateComponents([.day], from: previousDate, to: date).day ?? 0
            
            return days > 2
        }
        
        return false
    }
    
    // Calculate average cycle length based on recorded data or use user settings
    private func calculateAverageCycleLength() -> Int {
        return cycleLength // Use the user's set value
    }
    
    // Calculate fertile window days
    private func calculateFertileWindowDays() -> Int {
        if !showFertileWindow {
            return 0
        }
        
        return 7 // 5 days before ovulation + ovulation day + 1 day after
    }
    
    // Predict next period date
    private func nextPeriodPrediction() -> String {
        // Get the most recent period start
        let periodEvents = cycleEvents.filter { $0.type == .period }
        let sortedPeriodEvents = periodEvents.sorted(by: { $0.date < $1.date })
        
        if let lastPeriod = sortedPeriodEvents.last?.date {
            // Add average cycle length to predict next period
            let averageCycle = calculateAverageCycleLength()
            if let nextPeriod = Calendar.current.date(byAdding: .day, value: averageCycle, to: lastPeriod) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: nextPeriod)
            }
        }
        
        return "Not enough data"
    }
    
    // Add or edit a note for an event
    private func addNote(to event: CycleEvent) {
        // In a real app, you would show a dialog to edit the note
        // For now we'll just demonstrate updating with a preset note
        
        let updatedEvent = CycleEvent(
            id: event.id,
            date: event.date,
            type: event.type,
            timestamp: event.timestamp,
            notes: "Feeling good today!"
        )
        
        // Update in local array
        if let index = cycleEvents.firstIndex(where: { $0.id == event.id }) {
            cycleEvents[index] = updatedEvent
        }
        
        // Save to Firestore
        saveCycleEvent(event: updatedEvent)
    }
    
    // Delete an event
    private func deleteEvent(_ event: CycleEvent) {
        removeCycleEvent(date: event.date)
        
        // Also clear the calendar marking if needed
        if cycleData[event.date] != nil {
            cycleData[event.date] = .none
            saveCycleData()
        }
    }
    
    // MARK: - Firebase Methods
    
    private func loadCycleData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        isLoading = true
        cycleData.removeAll()
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .collection("cycleData")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading cycle data: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let day = document.data()["day"] as? Int,
                           let typeRaw = document.data()["type"] as? String,
                           let type = CycleDayType(rawValue: typeRaw) {
                            let date = self.dateFor(day: day, month: self.selectedMonth, year: self.selectedYear)
                            self.cycleData[date] = type
                        }
                    }
                    
                    // Apply animation when data is loaded
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                }
            }
    }
    
    private func loadCycleEvents(filterType: CycleDayType? = nil) {
        guard let user = Auth.auth().currentUser else { return }
        
        cycleEvents.removeAll()
        
        let db = Firestore.firestore()
        var query: Query = db.collection("users").document(user.uid)
            .collection("cycleEvents")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
        
        // Add type filter if specified
        if let filterType = filterType {
            query = query.whereField("type", isEqualTo: filterType.rawValue)
        }
        
        query.order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading cycle events: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let year = document.data()["year"] as? Int,
                           let month = document.data()["month"] as? Int,
                           let day = document.data()["day"] as? Int,
                           let typeRaw = document.data()["type"] as? String,
                           let type = CycleDayType(rawValue: typeRaw),
                           let timestamp = document.data()["timestamp"] as? Timestamp,
                           let notes = document.data()["notes"] as? String {
                            
                            let date = self.dateFor(day: day, month: month, year: year)
                            let event = CycleEvent(
                                id: document.documentID,
                                date: date,
                                type: type,
                                timestamp: timestamp.dateValue(),
                                notes: notes
                            )
                            
                            cycleEvents.append(event)
                        }
                    }
                }
            }
    }
    
    private func saveCycleData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete existing data for this month
        db.collection("users").document(user.uid)
            .collection("cycleData")
            .whereField("year", isEqualTo: selectedYear)
            .whereField("month", isEqualTo: selectedMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents to delete: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    // Delete all existing documents for this month
                    for document in snapshot.documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Add new documents for each marked day
                    for (date, type) in self.cycleData {
                        if type != .none {
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.year, .month, .day], from: date)
                            
                            if components.year == self.selectedYear && components.month == self.selectedMonth {
                                let docRef = db.collection("users").document(user.uid)
                                    .collection("cycleData")
                                    .document()
                                
                                let data: [String: Any] = [
                                    "year": self.selectedYear,
                                    "month": self.selectedMonth,
                                    "day": components.day!,
                                    "type": type.rawValue,
                                    "date": date
                                ]
                                
                                batch.setData(data, forDocument: docRef)
                            }
                        }
                    }
                    
                    // Commit the batch
                    batch.commit { error in
                        if let error = error {
                            print("Error saving cycle data: \(error.localizedDescription)")
                        }
                    }
                }
            }
    }
    
    private func saveCycleEvent(event: CycleEvent) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: event.date)
        
        if let year = components.year, let month = components.month, let day = components.day {
            let data: [String: Any] = [
                "year": year,
                "month": month,
                "day": day,
                "type": event.type.rawValue,
                "timestamp": Timestamp(date: event.timestamp),
                "notes": event.notes
            ]
            
            db.collection("users").document(user.uid)
                .collection("cycleEvents")
                .document(event.id)
                .setData(data) { error in
                    if let error = error {
                        print("Error saving cycle event: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    // Load cycle settings from Firestore
    private func loadCycleSettings() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        // First check the user profile for cycle length
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                if let cycleLengthInDays = document.data()?["cycleLengthInDays"] as? Int {
                    // Use the cycle length from user profile
                    self.cycleLength = cycleLengthInDays
                }
                
                // Now load other settings from settings document
                self.loadSettingsDocument()
            } else {
                // If profile document doesn't exist or has error, fall back to settings document
                self.loadSettingsDocument()
            }
        }
    }
    
    // Helper method to load settings from the settings document
    private func loadSettingsDocument() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .collection("settings")
            .document("cycleSettings")
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data() {
                        // Only update cycle length if it wasn't already set from profile
                        if data["cycleLength"] as? Int != nil {
                            // Don't override the profile value if we already have it
                            if self.cycleLength == 28 {
                                self.cycleLength = data["cycleLength"] as? Int ?? 28
                            }
                        }
                        
                        self.periodLength = data["periodLength"] as? Int ?? 5
                        self.showFertileWindow = data["showFertileWindow"] as? Bool ?? true
                    }
                }
            }
    }
    
    // Save cycle settings to Firestore
    private func saveCycleSettings() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        // 1. Update settings document
        let settingsData: [String: Any] = [
            "cycleLength": cycleLength,
            "periodLength": periodLength,
            "showFertileWindow": showFertileWindow,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(user.uid)
            .collection("settings")
            .document("cycleSettings")
            .setData(settingsData) { error in
                if let error = error {
                    print("Error saving cycle settings: \(error.localizedDescription)")
                }
            }
        
        // 2. Update user profile document with the cycle length
        db.collection("users").document(user.uid).updateData([
            "cycleLengthInDays": cycleLength,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating user profile cycle length: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Types

enum CycleDayType: String {
    case period = "period"
    case ovulation = "ovulation"
    case fertile = "fertile"
    case none = "none"
}

struct CycleEvent: Identifiable {
    let id: String
    let date: Date
    let type: CycleDayType
    let timestamp: Date
    let notes: String
}

#Preview {
    PrePregnancyView()
} 
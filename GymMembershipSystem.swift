// Importing
import Foundation

// Define a class GymMembershipSystem
class GymMembershipSystem {
    // Declare private variables to store members, classes, and bookings
    private var members: [Member]
    private var classes: [GymClass]
    private var bookings: [Booking]

    // Initialize the GymMembershipSystem
    init() {
        members = []
        classes = []
        bookings = []
    }

    // Function to register a new member
    func registerMember(name: String, memberId: Int) {
        // Create a new Member instance with the provided name and memberId
        let newMember = Member(name: name, memberId: memberId)
        // Append the new member to the members array
        members.append(newMember)
    }

    // Function to schedule a new gym class
    func scheduleClass(className: String, startTime: Date, endTime: Date, maxCapacity: Int) {
        // Create a new GymClass instance with the provided className, startTime, endTime, and maxCapacity
        let newClass = GymClass(className: className, startTime: startTime, endTime: endTime, maxCapacity: maxCapacity)
        // Append the new class to the classes array
        classes.append(newClass)
    }

    // Function to book a gym class for a member
    func bookClass(member: Member, gymClass: GymClass, bookingTime: Date) -> String {
        // Create a DateFormatter to format the bookingTime as a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        dateFormatter.timeZone = TimeZone.current
        let bookingTimeString = dateFormatter.string(from: bookingTime)

        // Check if the gym class can be booked at the provided bookingTime
        if gymClass.canBook(bookingTime: bookingTime) {
            // Try to book the class
            if gymClass.bookClass() {
                // Create a new Booking instance with the member, gymClass, and bookingTime
                let newBooking = Booking(member: member, gymClass: gymClass, bookingTime: bookingTime)
                // Append the new booking to the bookings array
                bookings.append(newBooking)
                // Return a success message with the member's name, class name, and booking time
                return "\(member.name) booked \(gymClass.className) at \(bookingTimeString)"
            } else {
                // Return a message indicating that the class is already full
                return "The class \(gymClass.className) is already full."
            }
        } else if !gymClass.canBookAnytime() {
            // Return a message indicating that the class is full and cannot be booked at any time
            return "The class \(gymClass.className) is full."
        } else {
            // Return a message indicating an invalid booking time for the class
            return "Invalid booking time: \(bookingTimeString). The class \(gymClass.className) is scheduled from \(dateFormatter.string(from: gymClass.startTime)) to \(dateFormatter.string(from: gymClass.endTime))."
        }
    }

    // Function to process input file and generate output file
    func processInputFile(inputFile: String, outputFile: String) {
        do {
            // Read the contents of the input file
            let inputText = try String(contentsOfFile: inputFile)
            // Split the input text into lines
            let lines = inputText.components(separatedBy: .newlines)
            var outputLines: [String] = []

            // Writing header
            outputLines.append("Output:")
            outputLines.append("------")
            outputLines.append("Format: <Member Name> booked <Class Name> at <Booking Time>")
            outputLines.append("")

            // Create a DateFormatter to parse the date and time strings in the input file
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

            // Process each line in the input file
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmedLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                if parts.isEmpty {
                    continue
                }

                let command = parts[0]

                if command == "register" {
                    // Handle the "register" command
                    if parts.count >= 3 {
                        let name = parts[1]
                        if let memberId = Int(parts[2]) {
                            registerMember(name: name, memberId: memberId)
                        } else {
                            outputLines.append("Invalid member ID: \(trimmedLine)")
                        }
                    } else {
                        outputLines.append("Invalid register command: \(trimmedLine)")
                    }
                } else if command == "schedule" {
                    // Handle the "schedule" command
                    if parts.count >= 5 {
                        let className = parts[1]
                        if let maxCapacity = Int(parts[4]) {
                            if let startTime = dateFormatter.date(from: parts[2]),
                               let endTime = dateFormatter.date(from: parts[3]) {
                                scheduleClass(className: className, startTime: startTime, endTime: endTime, maxCapacity: maxCapacity)
                            } else {
                                outputLines.append("Invalid schedule time format: \(trimmedLine)")
                            }
                        } else {
                            outputLines.append("Invalid max capacity: \(trimmedLine)")
                        }
                    } else {
                        outputLines.append("Invalid schedule command: \(trimmedLine)")
                    }
                } else if command == "book" {
                    // Handle the "book" command
                    if parts.count >= 4 {
                        if let memberId = Int(parts[1]) {
                            let className = parts[2]
                            let bookingTimeString = parts[3]

                            if let bookingTime = dateFormatter.date(from: bookingTimeString) {
                                if let member = findMemberById(memberId: memberId), let gymClass = findClassByName(className: className) {
                                    let bookingResult = bookClass(member: member, gymClass: gymClass, bookingTime: bookingTime)
                                    outputLines.append(bookingResult)
                                } else {
                                    outputLines.append("Invalid member ID or class name: \(trimmedLine)")
                                }
                            } else {
                                outputLines.append("Invalid booking time format: \(trimmedLine)")
                            }
                        } else {
                            outputLines.append("Invalid member ID: \(trimmedLine)")
                        }
                    } else {
                        outputLines.append("Invalid book command: \(trimmedLine)")
                    }
                } else {
                    // Handle invalid commands
                    outputLines.append("Invalid command: \(trimmedLine)")
                }
            }

            // Writing output to file
            let outputText = outputLines.joined(separator: "\n")
            try outputText.write(toFile: outputFile, atomically: true, encoding: .utf8)
        } catch {
            print("Error processing input file: \(error)")
        }
    }

    // Function to find a member by their ID
    private func findMemberById(memberId: Int) -> Member? {
        return members.first { $0.memberId == memberId }
    }

    // Function to find a class by its name
    private func findClassByName(className: String) -> GymClass? {
        return classes.first { $0.className == className }
    }
}

// Define a struct Member to represent a gym member
struct Member {
    let name: String
    let memberId: Int
}

// Define a class GymClass to represent a gym class
class GymClass {
    let className: String
    let startTime: Date
    let endTime: Date
    let maxCapacity: Int
    private var bookedSlots: Int

    // Initialize the GymClass
    init(className: String, startTime: Date, endTime: Date, maxCapacity: Int) {
        self.className = className
        self.startTime = startTime
        self.endTime = endTime
        self.maxCapacity = maxCapacity
        bookedSlots = 0
    }

    // Check if the class can be booked at the provided bookingTime
    func canBook(bookingTime: Date) -> Bool {
        return bookedSlots < maxCapacity && bookingTime >= startTime && bookingTime < endTime
    }

    // Check if the class can be booked at any time
    func canBookAnytime() -> Bool {
        return bookedSlots < maxCapacity
    }

    // Book the class if there are available slots
    func bookClass() -> Bool {
        if bookedSlots < maxCapacity {
            bookedSlots += 1
            return true
        } else {
            return false
        }
    }
}

// Define a struct Booking to represent a booking made by a member for a gym class
struct Booking {
    let member: Member
    let gymClass: GymClass
    let bookingTime: Date
}

// Create an instance of GymMembershipSystem
let membershipSystem = GymMembershipSystem()
// Process the input file and generate the output file
membershipSystem.processInputFile(inputFile: "input.txt", outputFile: "output.txt")

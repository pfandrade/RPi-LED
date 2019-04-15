import Foundation
import SwiftyGPIO
import Basic
import Utility

enum Errors: Error {
    case unknownCommand
    case failedGPIOInit
}

enum Command: String,  ArgumentKind {
    static var completion: ShellCompletion = .unspecified
    init(argument: String) throws {
        guard let _ = Command(rawValue: argument) else {
            throw Errors.unknownCommand
        }
        self.init(rawValue: argument)!
    }
    
    case on = "on"
    case off = "off"
    case state = "state"
}


struct LED {
    enum State {
        case on
        case off
    }
    
    private let gpio: GPIO
    
    init(GPIOName: GPIOName) throws {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPiRev2)
        
        guard let ledGpio = gpios[GPIOName] else {
            throw Errors.failedGPIOInit
        }
        ledGpio.direction = .OUT
        gpio = ledGpio
    }
    
    func on() {
        gpio.value = 1
    }
    
    func off() {
        gpio.value = 0
    }
    
    var state: State {
        return gpio.value == 1 ? State.on : State.off
    }
}

let exitCode: Int32

do {
    let parser = ArgumentParser(usage: "[on | off | state]",
                                overview: "Control the LED using the on off commands")
    
    let command = parser.add(positional: "command", kind: Command.self)
    
    let args = Array(CommandLine.arguments.dropFirst())
    let result = try parser.parse(args)
    
    let led = try LED(GPIOName: .P18)
    switch result.get(command)! {
    case .on:
        led.on()
        print("Turned On")
        exitCode = 0
    case .off:
        led.off()
        print("Turned Off")
        exitCode = 0
    case .state:
        switch led.state {
        case .on:
            print("On")
            exitCode = 0
        case .off:
            print("Off")
            exitCode = 1
        }
    }
} catch ArgumentParserError.expectedValue(let value) {
    print("Missing value for argument \(value).")
    exitCode = 2
} catch ArgumentParserError.expectedArguments(let parser, let stringArray) {
    print("Missing arguments: \(stringArray.joined()).")
    parser.printUsage(on: stdoutStream)
    exitCode = 2
} catch {
    print(error)
    exitCode = 3
}

exit(exitCode)

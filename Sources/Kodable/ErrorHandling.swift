import Foundation

// MARK: - Error Handling

public enum Error: Swift.Error {
    /// Wrapper for errors thrown by the decoder
    case wrappedError(Swift.Error)
    /// Thrown whenever the string cannot be parsed into a date
    case failedToParseDate(source: String)
    /// Thrown whenever there is at least one validation modifier that fails the validation of the value parsed
    case validationFailed(type: Any, property: String, parsedValue: Any)
    /// Thrown whenever a property cannot be decoded
    indirect case failedDecodingProperty(property: String, key: String, type: Any, underlyingError: Error)
    /// Thrown whenever a Type cannot be decoded
    indirect case failedDecodingType(type: Any, underlyingError: Error)
}

// MARK: Helper extensions

extension Error: CustomStringConvertible {
    public var description: String {
        iterateOverErrors(nextError: self)
    }

    internal var nextIteration: (Node, Error)? {
        switch self {
        case .wrappedError(let error):
            guard let dekodingError = error as? Error else { return nil }
            return dekodingError.nextIteration
        case .failedDecodingType(_, let underlyingError):
            return underlyingError.nextIteration
        case .failedDecodingProperty(let property, let key, let type, let underlyingError):
            return (Node(type: type, propertyName: property, key: key), underlyingError)
        case .failedToParseDate, .validationFailed:
            return nil
        }
    }

    internal func iterateOverErrors(initial nodes: [Node] = [], nextError: Error) -> String {
        let initialString = nodes.isEmpty ? "\(nextError.errorDescription)" : "" // Nodes being empty means it is the root error
        guard let next = nextError.nextIteration else { return initialString + buildErrorMessage(nodes: nodes, error: nextError) }
        return initialString + iterateOverErrors(initial: nodes + [next.0], nextError: next.1)
    }

    internal func buildErrorMessage(nodes: [Node], error: Error) -> String {
        let spacing = "  "
        var string = ""
        for i in 0...nodes.count {
            let spaces = Array(repeating: spacing, count: i+1).joined(separator: "")
            if i == nodes.count {
                string += "\n\(error.errorDescription)\n\n"
            } else {
                string += "\(spaces)\(nodes[i])\n"
            }
        }
        return string
    }

    internal var errorDescription: String {
        switch self {
        case let .wrappedError(error):
            return "Cause: \(error)"
        case let .failedToParseDate(source):
            return "Could not parse Date from this value: \(source)"
        case let .validationFailed(type, property, parsedValue):
            return "Could not decode type \(type). Validation for the property \(property) failed. The parsed value was \(parsedValue)"
        case let .failedDecodingProperty(property, key, type, _):
            return "Could not decode type \(type). Failed to decode property \(property) for key \(key)"
        case let .failedDecodingType(type, _):
            return "Could not decode an intance of \(type):\n"
        }
    }

    internal struct Node: CustomStringConvertible {
        let type: Any
        let propertyName: String
        let key: String

        var description: String {
            if propertyName == key {
                return "* failing property: \"\(propertyName)\" of type \(type)"
            } else {
                return "* failing property: \"\(propertyName)\"(key: \"\(key)\") of type \(type)"
            }
        }
    }
}

// MARK: - Conformance to Equatable for testing purposes

extension Error: Equatable {
    public static func == (lhs: Error, rhs: Error) -> Bool {
        switch (lhs, rhs) {
        case (.wrappedError, .wrappedError): return false
        case (let .failedToParseDate(lhsSource), let .failedToParseDate(rhsSource)): return lhsSource == rhsSource
        case (let .validationFailed(_, lhsProperty, _), let .validationFailed(_, rhsProperty, _)): return lhsProperty == rhsProperty
        case (let .failedDecodingProperty(lhsProperty, _, lhsType, lhsUnderlyingError), let .failedDecodingProperty(rhsProperty, _, rhsType, rhsUnderlyingError)):
            return "\(lhsType)" == "\(rhsType)" && lhsProperty == rhsProperty && lhsUnderlyingError == rhsUnderlyingError
        case (let .failedDecodingType(lhsType, _), let .failedDecodingType(rhsType, _)): return "\(lhsType)" == "\(rhsType)"
        default: return false
        }
    }
}

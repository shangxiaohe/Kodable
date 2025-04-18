import Foundation

// MARK: - AnyCodingKey

/// Enables using a string as key when decoding/encoding an instance of `Codable`
public struct AnyCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init(_ key: String) { stringValue = key }
    public init?(stringValue: String) { self.stringValue = stringValue }
    public init?(intValue: Int) { (self.intValue, stringValue) = (intValue, String(intValue)) }
}

// MARK: Typealiases

// A container used for decoding keyedBy `AnyCodingKey
public typealias DecodeContainer = KeyedDecodingContainer<AnyCodingKey>
// A container used for encoding keyedBy `AnyCodingKey
typealias EncodeContainer = KeyedEncodingContainer<AnyCodingKey>

// MARK: Helper Extensions

// A set of helper functions to hide away the API consumer the `AnyCodingKey` usage

extension DecodeContainer {
    func decode<T>(_ type: T.Type, with stringKey: String) throws -> T where T: Decodable {
        try decode(type, forKey: AnyCodingKey(stringKey))
    }

    func decodeIfPresent<T>(_ type: T.Type, with stringKey: String) throws -> T? where T: Decodable {
        try decodeIfPresent(type, forKey: AnyCodingKey(stringKey))
    }

    mutating func nestedContainer(forKey stringKey: String) throws -> DecodeContainer {
        try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(stringKey))
    }
}

extension EncodeContainer {
    mutating func encode<T>(_ value: T, with stringKey: String) throws where T: Encodable {
        try encode(value, forKey: AnyCodingKey(stringKey))
    }

    mutating func nestedContainer(forKey stringKey: String) -> EncodeContainer {
        nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(stringKey))
    }
}

extension Decoder {
    func anyDecodingContainer() throws -> DecodeContainer {
        try container(keyedBy: AnyCodingKey.self)
    }
}

extension Encoder {
    func anyEncodingContainer() -> EncodeContainer {
        container(keyedBy: AnyCodingKey.self)
    }
}

public extension Decodable {
    static func decodeIfPresent(from container: DecodeContainer, with stringKey: String) throws -> Self? {
        try container.decodeIfPresent(Self.self, forKey: AnyCodingKey(stringKey))
    }
}

extension Encodable {
    func encodeIfPresent(to container: inout EncodeContainer, with stringKey: String) throws {
        try container.encodeIfPresent(self, forKey: AnyCodingKey(stringKey))
    }
}

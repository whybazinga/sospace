//
//  Bundle-Decoding.swift
//  SoSpace
//

import Foundation

extension Bundle {
    func decode<T:Decodable>(_ type:T.Type, from file:String)->T {
        guard let fileDataUrl = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle")
        }
        
        guard let encodedFileData = try? Data(contentsOf: fileDataUrl) else {
            fatalError("Failed to load \(file) from bundle")
        }
        
        guard let decodedFileData = try? JSONDecoder().decode(T.self, from: encodedFileData) else {
            fatalError("Failed to decode \(file) from bundle")
        }
        
        return decodedFileData
    }
}

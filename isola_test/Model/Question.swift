//
//  Question.swift
//  isola_test
//
//  Created by Biu on 2026/4/7.
//

import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let type: String
    let content: String
}

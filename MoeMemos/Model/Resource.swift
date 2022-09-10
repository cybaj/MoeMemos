//
//  Resource.swift
//  MoeMemos
//
//  Created by Mudkip on 2022/9/10.
//

import Foundation

struct Resource: Decodable, Identifiable {
    let id: Int
    let createdTs: Date
    let creatorId: Int
    let filename: String
    let size: Int
    let type: String
    let updatedTs: Date
}
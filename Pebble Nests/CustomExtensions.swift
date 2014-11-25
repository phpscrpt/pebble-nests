//
//  CustomExtensions.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/4/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import Foundation

extension Array {
    func indexOf<T : Equatable>(object:T) -> Int? {
        var result: [Int] = []
        for (index,obj) in enumerate(self) {
            if obj as T == object {
                return index
            }
        }
        return nil
    }
}

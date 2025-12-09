//
//  WeatherWidgetBundle.swift
//  WeatherWidget
//
//  Created by YuYu 1015 on 11/19/R7.
//

import WidgetKit
import SwiftUI

@main
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        WeatherWidgetControl()
        WeatherWidgetLiveActivity()
    }
}

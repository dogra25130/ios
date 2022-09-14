//
//  DashboardWidgetProvider.swift
//  Widget
//
//  Created by Marino Faggiana on 25/08/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import WidgetKit
import SwiftUI
import Intents

struct DashboardWidgetProvider: IntentTimelineProvider {

    typealias Intent = DashboardIntent
    typealias Entry = DashboardDataEntry

    func placeholder(in context: Context) -> Entry {
        let datasPlaceholder = Array(dashboardDatasTest[0...dashboaardItems - 1])
        let title = "Dashboard"
        let titleImage = UIImage(named: "widget")!
        return Entry(date: Date(), datas: datasPlaceholder, tableDashboard: nil, tableButton: nil, isPlaceholder: true, titleImage: titleImage, title: title, footerImage: "checkmark.icloud", footerText: NCBrandOptions.shared.brand + " widget")
    }

    func getSnapshot(for configuration: DashboardIntent, in context: Context, completion: @escaping (DashboardDataEntry) -> Void) {
        getDashboardDataEntry(intent: configuration.Applications, isPreview: false, displaySize: context.displaySize) { entry in
            completion(entry)
        }
    }

    func getTimeline(for configuration: DashboardIntent, in context: Context, completion: @escaping (Timeline<DashboardDataEntry>) -> Void) {
        getDashboardDataEntry(intent: configuration.Applications, isPreview: context.isPreview, displaySize: context.displaySize) { entry in
            let timeLine = Timeline(entries: [entry], policy: .atEnd)
            completion(timeLine)
        }
    }
}
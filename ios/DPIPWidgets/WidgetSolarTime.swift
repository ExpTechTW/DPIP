import Foundation

enum WidgetSolarTime {
    private static let millisecondsPerDay = 86_400_000.0
    private static let j2000UnixDayOffset = 10_957.5
    private static let degreesToRadians = Double.pi / 180

    static func positiveModulo(
        _ value: Double,
        modulus: Double
    ) -> Double {
        let remainder = value.truncatingRemainder(
            dividingBy: modulus
        )

        if remainder == 0 {
            return 0
        }

        return remainder > 0
            ? remainder
            : remainder + modulus
    }

    static func julianDays(
        unixMilliseconds: Int64
    ) -> Double {
        Double(unixMilliseconds) / Self.millisecondsPerDay
            - Self.j2000UnixDayOffset
    }

    static func solarTerms(
        unixMilliseconds: Int64
    ) -> SolarTerms {
        let n = julianDays(
            unixMilliseconds: unixMilliseconds
        )

        let meanLongitudeDegrees = positiveModulo(
            280.460 + 0.9856474 * n,
            modulus: 360
        )

        let meanAnomalyRadians = positiveModulo(
            357.528 + 0.9856003 * n,
            modulus: 360
        ) * Self.degreesToRadians

        let eclipticLongitudeRadians = (
            meanLongitudeDegrees
                + 1.915 * sin(meanAnomalyRadians)
                + 0.020 * sin(2 * meanAnomalyRadians)
        ) * Self.degreesToRadians

        let obliquityRadians = (
            23.439 - 0.0000004 * n
        ) * Self.degreesToRadians

        let rightAscensionRadians = atan2(
            cos(obliquityRadians)
                * sin(eclipticLongitudeRadians),
            cos(eclipticLongitudeRadians)
        )

        let declinationRadians = asin(
            sin(obliquityRadians)
                * sin(eclipticLongitudeRadians)
        )

        return SolarTerms(
            meanLongitudeDegrees: meanLongitudeDegrees,
            rightAscensionRadians: rightAscensionRadians,
            declinationRadians: declinationRadians
        )
    }

    static func sunTimes(
        unixMilliseconds: Int64,
        latitude: Double,
        longitude: Double,
        utcOffsetHours: Double = 8
    ) -> SunTimes {
        let terms = solarTerms(
            unixMilliseconds: unixMilliseconds
        )

        let latitudeRadians =
            latitude * Self.degreesToRadians

        let altitudeRadians =
            -0.833 * Self.degreesToRadians

        let cosHourAngle = (
            sin(altitudeRadians)
                - sin(latitudeRadians)
                * sin(terms.declinationRadians)
        ) / (
            cos(latitudeRadians)
                * cos(terms.declinationRadians)
        )

        if cosHourAngle <= -1 {
            return SunTimes(
                sunriseLocalHours: 0,
                sunsetLocalHours: 24
            )
        }

        if cosHourAngle >= 1 {
            return SunTimes(
                sunriseLocalHours: 12,
                sunsetLocalHours: 12
            )
        }

        let hourAngleHours =
            acos(cosHourAngle)
            / Self.degreesToRadians
            / 15

        var equationOfTimeHours = (
            terms.meanLongitudeDegrees
                * Self.degreesToRadians
                - terms.rightAscensionRadians
        ) / Self.degreesToRadians / 15

        equationOfTimeHours = positiveModulo(
            equationOfTimeHours + 12,
            modulus: 24
        ) - 12

        let solarNoon =
            12
            - longitude / 15
            + utcOffsetHours
            - equationOfTimeHours

        return SunTimes(
            sunriseLocalHours:
                solarNoon - hourAngleHours,
            sunsetLocalHours:
                solarNoon + hourAngleHours
        )
    }

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func localDayContext(
        unixMilliseconds: Int64,
        utcOffsetHours: Double
    ) -> LocalDayContext {
        let offsetMinutes = Int(
            (utcOffsetHours * 60)
                .rounded(.toNearestOrAwayFromZero)
        )

        let offsetMilliseconds =
            Int64(offsetMinutes) * 60 * 1_000

        let shiftedUnixMilliseconds =
            unixMilliseconds + offsetMilliseconds

        let shiftedDate = Date(
            timeIntervalSince1970:
                Double(shiftedUnixMilliseconds) / 1_000
        )

        let components = Self.utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: shiftedDate
        )

        let year = components.year!
        let month = components.month!
        let day = components.day!
        let hour = components.hour!
        let minute = components.minute!
        let second = components.second!

        let localNoon = Self.utcCalendar.date(
            from: DateComponents(
                timeZone: TimeZone(secondsFromGMT: 0),
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!

        let localNoonMilliseconds = Int64(
            (
                localNoon.timeIntervalSince1970 * 1_000
            ).rounded(.toNearestOrAwayFromZero)
        )

        return LocalDayContext(
            anchorUnixMilliseconds:
                localNoonMilliseconds - offsetMilliseconds,
            localSecond:
                hour * 3_600
                + minute * 60
                + second
        )
    }

    static func isNight(
        unixMilliseconds: Int64,
        latitude: Double,
        longitude: Double,
        utcOffsetHours: Double = 8
    ) -> Bool {
        let context = localDayContext(
            unixMilliseconds: unixMilliseconds,
            utcOffsetHours: utcOffsetHours
        )

        let times = sunTimes(
            unixMilliseconds:
                context.anchorUnixMilliseconds,
            latitude: latitude,
            longitude: longitude,
            utcOffsetHours: utcOffsetHours
        )

        let sunSeconds = roundedSunSeconds(times)

        return context.localSecond < sunSeconds.sunrise
            || context.localSecond >= sunSeconds.sunset
    }

    static func nextDayNightTransition(
        unixMilliseconds: Int64,
        latitude: Double,
        longitude: Double,
        utcOffsetHours: Double = 8
    ) -> Int64 {
        let context = localDayContext(
            unixMilliseconds: unixMilliseconds,
            utcOffsetHours: utcOffsetHours
        )

        let todayTimes = sunTimes(
            unixMilliseconds:
                context.anchorUnixMilliseconds,
            latitude: latitude,
            longitude: longitude,
            utcOffsetHours: utcOffsetHours
        )

        let today = roundedSunSeconds(todayTimes)

        let todayLocalMidnightMilliseconds =
            context.anchorUnixMilliseconds
            - 12 * 60 * 60 * 1_000

        if context.localSecond < today.sunrise {
            return (
                todayLocalMidnightMilliseconds
                + Int64(today.sunrise) * 1_000
            ) / 1_000
        }

        if context.localSecond < today.sunset {
            return (
                todayLocalMidnightMilliseconds
                + Int64(today.sunset) * 1_000
            ) / 1_000
        }

        let tomorrowAnchorMilliseconds =
            context.anchorUnixMilliseconds
            + 86_400_000

        let tomorrowTimes = sunTimes(
            unixMilliseconds:
                tomorrowAnchorMilliseconds,
            latitude: latitude,
            longitude: longitude,
            utcOffsetHours: utcOffsetHours
        )

        let tomorrow = roundedSunSeconds(tomorrowTimes)

        let tomorrowLocalMidnightMilliseconds =
            tomorrowAnchorMilliseconds
            - 12 * 60 * 60 * 1_000

        return (
            tomorrowLocalMidnightMilliseconds
            + Int64(tomorrow.sunrise) * 1_000
        ) / 1_000
    }

    private static func roundedSunSeconds(
        _ times: SunTimes
    ) -> (sunrise: Int, sunset: Int) {
        let sunrise = Int(
            (times.sunriseLocalHours * 3_600)
                .rounded(.toNearestOrAwayFromZero)
        )

        let sunset = Int(
            (times.sunsetLocalHours * 3_600)
                .rounded(.toNearestOrAwayFromZero)
        )

        return (sunrise, sunset)
    }
}

struct SolarTerms {
    let meanLongitudeDegrees: Double
    let rightAscensionRadians: Double
    let declinationRadians: Double
}

struct SunTimes {
    let sunriseLocalHours: Double
    let sunsetLocalHours: Double
}

private struct LocalDayContext {
    let anchorUnixMilliseconds: Int64
    let localSecond: Int
}

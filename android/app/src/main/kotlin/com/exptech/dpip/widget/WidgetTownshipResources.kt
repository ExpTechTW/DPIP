package com.exptech.dpip.widget

import android.content.Context
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin

/** One degree of latitude, in metres: the scale every distance here is measured on. */
private const val METRES_PER_DEGREE = 111_320.0

/** One township, as published by the Dart assets through the generator. */
data class WidgetTownship(
    val regionCode: String,
    val displayName: String,
    val administrativeAreaName: String,
    val latitude: Double,
    val longitude: Double,
)

/** The township directory: every township the generated resources describe. */
class TownshipDirectory private constructor(private val townships: List<WidgetTownship>) {
    private val byCode: Map<String, WidgetTownship> = townships.associateBy { it.regionCode }

    fun township(regionCode: String): WidgetTownship? = byCode[regionCode]

    val regionCodes: Set<String> get() = byCode.keys

    companion object {
        const val supportedSchemaVersion = 1

        /** Builds a directory, refusing an empty or duplicated code set. */
        fun of(townships: List<WidgetTownship>): TownshipDirectory? {
            if (townships.isEmpty()) return null
            if (townships.map { it.regionCode }.toSet().size != townships.size) return null
            if (townships.any { !isValidRegionCode(it.regionCode) }) return null
            return TownshipDirectory(townships)
        }

        fun decode(json: String): TownshipDirectory? {
            val root = WidgetJsonParser.parse(json)?.objOrNull() ?: return null
            if (root["schemaVersion"]?.intOrNull() != supportedSchemaVersion) return null
            val raw = root["townships"]?.arrOrNull()?.values ?: return null
            if (raw.isEmpty()) return null

            val townships = ArrayList<WidgetTownship>(raw.size)
            for (element in raw) {
                val entry = element.objOrNull() ?: return null
                val township = WidgetTownship(
                    regionCode = entry["regionCode"]?.strOrNull() ?: return null,
                    displayName = entry["displayName"]?.strOrNull() ?: return null,
                    administrativeAreaName = entry["administrativeAreaName"]?.strOrNull() ?: return null,
                    latitude = entry["latitude"].finiteDoubleOrNull() ?: return null,
                    longitude = entry["longitude"].finiteDoubleOrNull() ?: return null,
                )
                if (!isValidRegionCode(township.regionCode)) return null
                if (township.displayName.isEmpty() || township.administrativeAreaName.isEmpty()) return null
                if (township.latitude !in -90.0..90.0 || township.longitude !in -180.0..180.0) return null
                townships.add(township)
            }
            return of(townships)
        }
    }
}

private data class TownshipCoordinate(val longitude: Double, val latitude: Double)

private class TownshipPolygon(val rings: List<List<TownshipCoordinate>>)

private class TownshipShape(
    val regionCode: String,
    val polygons: List<TownshipPolygon>,
) {
    val minLongitude: Double
    val minLatitude: Double
    val maxLongitude: Double
    val maxLatitude: Double

    init {
        var minLongitude = Double.MAX_VALUE
        var minLatitude = Double.MAX_VALUE
        var maxLongitude = -Double.MAX_VALUE
        var maxLatitude = -Double.MAX_VALUE
        for (polygon in polygons) {
            for (ring in polygon.rings) {
                for (point in ring) {
                    if (point.longitude < minLongitude) minLongitude = point.longitude
                    if (point.latitude < minLatitude) minLatitude = point.latitude
                    if (point.longitude > maxLongitude) maxLongitude = point.longitude
                    if (point.latitude > maxLatitude) maxLatitude = point.latitude
                }
            }
        }
        this.minLongitude = minLongitude
        this.minLatitude = minLatitude
        this.maxLongitude = maxLongitude
        this.maxLatitude = maxLatitude
    }

    fun contains(latitude: Double, longitude: Double): Boolean {
        if (longitude < minLongitude || longitude > maxLongitude) return false
        if (latitude < minLatitude || latitude > maxLatitude) return false

        for (polygon in polygons) {
            if (!isInside(polygon.rings[0], latitude, longitude)) continue
            val insideHole = polygon.rings.drop(1).any { isInside(it, latitude, longitude) }
            if (!insideHole) return true
        }
        return false
    }

    /**
     * The shortest distance from a point to any of this shape's rings, in metres.
     *
     * Every ring counts, holes included: a point inside a township but close to
     * one of its holes is as uncertain as one close to the coast, and a fix whose
     * accuracy reaches the hole could belong to whatever the hole is.
     *
     * Metres are computed in the same equirectangular metric the nearest-centroid
     * search uses — longitude scaled by the cosine of the latitude — so two
     * functions cannot disagree about which township is nearer.
     */
    fun minimumDistanceMeters(latitude: Double, longitude: Double): Double {
        // Inside, the nearest ring is the distance out; outside, it is the
        // distance in. Either way the answer is the nearest ring, and every ring
        // counts, so the two cases share one formula.
        return minimumRingDistanceMeters(latitude, longitude)
    }

    private fun minimumRingDistanceMeters(latitude: Double, longitude: Double): Double {
        var best = Double.MAX_VALUE
        for (polygon in polygons) {
            for (ring in polygon.rings) {
                best = minOf(best, ringDistanceMeters(ring, latitude, longitude))
            }
        }
        return best
    }

    /**
     * Point-to-segment distance, in metres near [latitude].
     *
     * The whole ring is walked rather than stopping at a bounding-box test: a
     * vertex can be far while the segment between two vertices passes close by,
     * which is exactly the case a sampled check misses.
     */
    private fun ringDistanceMeters(
        ring: List<TownshipCoordinate>,
        latitude: Double,
        longitude: Double,
    ): Double {
        val cosine = cos(latitude * Math.PI / 180.0).coerceAtLeast(0.01)
        // Local metres: origin at the query point, so the numbers stay small.
        fun x(coordinate: TownshipCoordinate): Double =
            (coordinate.longitude - longitude) * METRES_PER_DEGREE * cosine
        fun y(coordinate: TownshipCoordinate): Double =
            (coordinate.latitude - latitude) * METRES_PER_DEGREE

        var best = Double.MAX_VALUE
        var previous = ring[ring.size - 1]
        for (current in ring) {
            val ax = x(previous)
            val ay = y(previous)
            val bx = x(current)
            val by = y(current)
            val dx = bx - ax
            val dy = by - ay
            val lengthSquared = dx * dx + dy * dy
            val t = if (lengthSquared <= 0.0) {
                0.0
            } else {
                ((-ax * dx) + (-ay * dy)) / lengthSquared
            }.coerceIn(0.0, 1.0)
            val px = ax + t * dx
            val py = ay + t * dy
            best = minOf(best, Math.sqrt(px * px + py * py))
            previous = current
        }
        return best
    }

    /**
     * Ray casting with the same comparisons and axis order as Dart and Swift.
     *
     * Identical arithmetic matters here: a point on a boundary must resolve to
     * the same township on both platforms, and two different tie rules would
     * disagree exactly at the edge, which is where a user standing on a town
     * line notices.
     */
    private fun isInside(ring: List<TownshipCoordinate>, latitude: Double, longitude: Double): Boolean {
        var inside = false
        var previous = ring[ring.size - 1]
        for (current in ring) {
            if ((current.latitude > latitude) != (previous.latitude > latitude) &&
                longitude < (previous.longitude - current.longitude) *
                (latitude - current.latitude) / (previous.latitude - current.latitude) +
                current.longitude
            ) {
                inside = !inside
            }
            previous = current
        }
        return inside
    }
}

/** Township polygons with a coarse grid so a query tests a handful, not all. */
class TownshipBoundaryTable private constructor(private val shapes: List<TownshipShape>) {
    private val byCode: Map<String, TownshipShape> = shapes.associateBy { it.regionCode }
    private val grid: TownshipGrid = TownshipGrid(shapes)

    val regionCodes: Set<String> get() = byCode.keys

    /**
     * The code whose polygon contains the point, or null outside every polygon.
     *
     * Null is a real answer — a point off Taiwan has no township, and the plan
     * forbids inventing one by snapping to the nearest centroid.
     */
    fun codeAt(latitude: Double, longitude: Double): String? {
        for (regionCode in grid.candidates(latitude, longitude)) {
            if (byCode[regionCode]?.contains(latitude, longitude) == true) return regionCode
        }
        return null
    }

    /**
     * The shortest distance from a point to any township boundary near it, in
     * metres.
     *
     * "Near" is the 3×3 block of grid cells around the point. One cell is 0.05°
     * (about 5.5 km) and a fix's accuracy is bounded by
     * `WidgetLocationFix.maximumAccuracyMeters` (500 m), so a boundary the
     * uncertainty circle could reach is always inside that block — a wider search
     * would only cost time.
     */
    fun minimumDistanceMeters(latitude: Double, longitude: Double): Double {
        var best = Double.MAX_VALUE
        for (regionCode in grid.candidatesNear(latitude, longitude)) {
            val shape = byCode[regionCode] ?: continue
            best = minOf(best, shape.minimumDistanceMeters(latitude, longitude))
        }
        return best
    }

    companion object {
        private const val maximumTownCount = 10_000
        private const val maximumPolygonCount = 100_000
        private const val maximumRingCount = 100_000
        private const val maximumPointCount = 2_000_000

        fun decode(bytes: ByteArray): TownshipBoundaryTable? {
            return try {
                val reader = TownshipBinaryReader(bytes)
                val townCount = reader.readCount(maximumTownCount)
                if (townCount <= 0) return null

                val shapes = ArrayList<TownshipShape>(townCount)
                repeat(townCount) {
                    val codeLength = reader.readCount(16)
                    val codeBytes = reader.readBytes(codeLength)
                    val regionCode = String(codeBytes, Charsets.US_ASCII)
                    if (!isValidRegionCode(regionCode)) return null

                    val polygonCount = reader.readCount(maximumPolygonCount)
                    if (polygonCount <= 0) return null
                    val polygons = ArrayList<TownshipPolygon>(polygonCount)

                    repeat(polygonCount) {
                        val ringCount = reader.readCount(maximumRingCount)
                        if (ringCount <= 0) return null
                        val rings = ArrayList<List<TownshipCoordinate>>(ringCount)

                        repeat(ringCount) {
                            val pointCount = reader.readCount(maximumPointCount)
                            if (pointCount < 3) return null
                            val points = ArrayList<TownshipCoordinate>(pointCount)
                            var longitudeInteger = 0
                            var latitudeInteger = 0
                            repeat(pointCount) {
                                longitudeInteger = add(longitudeInteger, unzigzag(reader.readVarint()))
                                latitudeInteger = add(latitudeInteger, unzigzag(reader.readVarint()))
                                points.add(
                                    TownshipCoordinate(
                                        longitude = longitudeInteger / 10_000.0,
                                        latitude = latitudeInteger / 10_000.0,
                                    ),
                                )
                            }
                            rings.add(points)
                        }
                        polygons.add(TownshipPolygon(rings))
                    }
                    shapes.add(TownshipShape(regionCode, polygons))
                }

                if (!reader.isAtEnd) return null
                if (shapes.map { it.regionCode }.toSet().size != shapes.size) return null
                TownshipBoundaryTable(shapes)
            } catch (_: Exception) {
                null
            }
        }

        private fun unzigzag(value: Long): Int {
            // The wire format is a zigzag-encoded varint, so the magnitude must
            // fit a signed Int before it is negated.
            if (value ushr 1 > Int.MAX_VALUE.toLong()) throw IllegalArgumentException("overflow")
            val magnitude = (value ushr 1).toInt()
            return if (value and 1L == 0L) magnitude else -magnitude - 1
        }

        private fun add(value: Int, delta: Int): Int {
            val sum = value.toLong() + delta
            if (sum < Int.MIN_VALUE || sum > Int.MAX_VALUE) throw IllegalArgumentException("overflow")
            return sum.toInt()
        }
    }
}

private class TownshipGrid(shapes: List<TownshipShape>) {
    private val minLongitude = shapes.minOf { it.minLongitude }
    private val minLatitude = shapes.minOf { it.minLatitude }
    private val columnCount = ceil((shapes.maxOf { it.maxLongitude } - minLongitude) / cellSize).toInt() + 1
    private val rowCount = ceil((shapes.maxOf { it.maxLatitude } - minLatitude) / cellSize).toInt() + 1
    private val cells = arrayOfNulls<MutableList<String>>(columnCount * rowCount)

    init {
        for (shape in shapes) {
            val firstColumn = floor((shape.minLongitude - minLongitude) / cellSize).toInt()
            val lastColumn = floor((shape.maxLongitude - minLongitude) / cellSize).toInt()
            val firstRow = floor((shape.minLatitude - minLatitude) / cellSize).toInt()
            val lastRow = floor((shape.maxLatitude - minLatitude) / cellSize).toInt()
            for (row in firstRow..lastRow) {
                for (column in firstColumn..lastColumn) {
                    val index = row * columnCount + column
                    if (index < 0 || index >= cells.size) continue
                    val cell = cells[index] ?: ArrayList<String>().also { cells[index] = it }
                    cell.add(shape.regionCode)
                }
            }
        }
    }

    fun candidates(latitude: Double, longitude: Double): List<String> {
        val column = floor((longitude - minLongitude) / cellSize).toInt()
        val row = floor((latitude - minLatitude) / cellSize).toInt()
        if (column < 0 || column >= columnCount || row < 0 || row >= rowCount) return emptyList()
        return cells[row * columnCount + column] ?: emptyList()
    }

    /**
     * Every shape in the cell containing the point and in the eight around it.
     *
     * A shape whose bounding box is just outside the point's own cell still has a
     * boundary that can be within a fix's accuracy of it, so the neighbour cells
     * are what make a distance test sound.
     */
    fun candidatesNear(latitude: Double, longitude: Double): List<String> {
        val column = floor((longitude - minLongitude) / cellSize).toInt()
        val row = floor((latitude - minLatitude) / cellSize).toInt()
        val found = LinkedHashSet<String>()
        for (rowOffset in -1..1) {
            for (columnOffset in -1..1) {
                val c = column + columnOffset
                val r = row + rowOffset
                if (c < 0 || c >= columnCount || r < 0 || r >= rowCount) continue
                cells[r * columnCount + c]?.let { found.addAll(it) }
            }
        }
        return found.toList()
    }

    companion object {
        private const val cellSize = 0.05
    }
}

private class TownshipBinaryReader(bytes: ByteArray) {
    private val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
    private var position = 0

    val isAtEnd: Boolean get() = position == buffer.capacity()

    fun readBytes(count: Int): ByteArray {
        if (count < 0 || position > buffer.capacity() - count) {
            throw IllegalArgumentException("truncated")
        }
        val result = ByteArray(count)
        System.arraycopy(buffer.array(), position, result, 0, count)
        position += count
        return result
    }

    fun readCount(maximum: Int): Int {
        val value = readVarint()
        if (value < 0 || value > maximum) throw IllegalArgumentException("count out of range")
        return value.toInt()
    }

    fun readVarint(): Long {
        var value = 0L
        var shift = 0
        for (index in 0 until 10) {
            if (position >= buffer.capacity()) throw IllegalArgumentException("truncated varint")
            val byte = buffer.get(position).toInt() and 0xFF
            position++
            if (shift >= 64) throw IllegalArgumentException("varint overflow")
            value = value or ((byte and 0x7F).toLong() shl shift)
            if (byte and 0x80 == 0) return value
            shift += 7
        }
        throw IllegalArgumentException("varint too long")
    }
}

/**
 * Point → township, by polygon containment alone, with the fix's accuracy
 * measured against the nearest boundary. There is deliberately no centroid
 * fallback: see [WidgetTownshipResolver.resolve].
 *
 * The two resource sets must describe the same townships; a mismatch is
 * refused so a half-updated pair cannot resolve a point to a township whose
 * boundary data belongs to a different code set.
 */
class WidgetTownshipResolver private constructor(
    private val boundaries: TownshipBoundaryTable,
    private val directory: TownshipDirectory,
) {
    /**
     * The township the fix is in, or null when that cannot be established.
     *
     * A fix is a point with an uncertainty radius, not a certainty. The test is
     * the **shortest distance to the nearest boundary** — every ring of every
     * nearby township, holes included — against the fix's accuracy: if the
     * uncertainty circle could reach a boundary, the township on the other side
     * is equally plausible and neither is claimed.
     *
     * A sampled circle was tried first and is not sound: with eight directions,
     * a boundary 470 m away whose normal sits 22.5° between two samples projects
     * onto them at 461.94 m, so a 500 m fix looks entirely inside a township it
     * is 30 m from leaving. The distance test has no such gap.
     *
     * A point in **no** township resolves to nothing. The nearest centroid was
     * tried as a fallback, bounded to 0.5°, and it is not a township: Xiamen
     * (24.4798, 118.0894) sits 0.1499° from Lieyu's centroid, well inside that
     * bound, so the Widget would have named 烈嶼 for a city in another country.
     * A distance bound cannot express "in Taiwan"; the polygons can, and when
     * they say no, the honest screen keeps the previous observation and says the
     * position could not be resolved.
     */
    fun resolve(fix: WidgetFix): ResolvedWeatherLocation? {
        val distanceToBoundary = boundaries.minimumDistanceMeters(fix.latitude, fix.longitude)
        if (distanceToBoundary <= fix.accuracyMeters) return null

        val code = boundaries.codeAt(fix.latitude, fix.longitude) ?: return null
        val township = directory.township(code) ?: return null

        return ResolvedWeatherLocation.create(
            address = WidgetAddress.CurrentLocation,
            regionCode = township.regionCode,
            regionName = township.displayName,
            latitude = township.latitude,
            longitude = township.longitude,
        )
    }

    fun township(regionCode: String): WidgetTownship? = directory.township(regionCode)

    companion object {
        /** One degree of latitude, in metres — the scale the fix is measured on. */
        const val metresPerDegree = METRES_PER_DEGREE

        /**
         * Pairs a directory with a boundary table, refusing a mismatched pair.
         *
         * A half-updated pair would resolve a point to a township whose boundary
         * data belongs to a different code set, which is worse than resolving
         * nothing. Mirrors `WidgetTownshipResolver.init(boundaries:directory:)`.
         */
        fun of(
            boundaries: TownshipBoundaryTable,
            directory: TownshipDirectory,
        ): WidgetTownshipResolver? {
            if (boundaries.regionCodes != directory.regionCodes) return null
            return WidgetTownshipResolver(boundaries, directory)
        }

        fun load(context: Context): WidgetTownshipResolver? {
            return try {
                val directoryJson = context.assets
                    .open("widget_township_directory.json")
                    .use { it.readBytes().toString(Charsets.UTF_8) }
                val boundaryBytes = context.assets
                    .open("widget_township_boundaries.bin")
                    .use { it.readBytes() }

                val directory = TownshipDirectory.decode(directoryJson) ?: return null
                val boundaries = TownshipBoundaryTable.decode(boundaryBytes) ?: return null
                of(boundaries, directory)
            } catch (_: Exception) {
                null
            }
        }
    }
}

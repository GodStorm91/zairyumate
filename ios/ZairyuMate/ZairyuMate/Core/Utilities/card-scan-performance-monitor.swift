//
//  card-scan-performance-monitor.swift
//  ZairyuMate
//
//  Performance monitoring for card scanning operations
//  Tracks processing times, memory usage, and success rates
//

import Foundation
import UIKit

/// Performance monitoring for card scanning
final class CardScanPerformanceMonitor {

    // MARK: - Singleton

    static let shared = CardScanPerformanceMonitor()
    private init() {}

    // MARK: - Performance Metrics

    struct ScanMetrics {
        let cardType: CardType
        let scanMethod: CardScanMethod
        let startTime: Date
        let endTime: Date
        let duration: TimeInterval
        let memoryUsed: UInt64 // bytes
        let success: Bool
        let errorType: String?
        let confidence: Float? // OCR only

        var durationMs: Int {
            Int(duration * 1000)
        }

        var memoryUsedMB: Double {
            Double(memoryUsed) / 1_048_576.0 // bytes to MB
        }
    }

    // MARK: - Active Sessions

    private var activeSessions: [String: Date] = [:]
    private var metrics: [ScanMetrics] = []
    private let queue = DispatchQueue(label: "com.zairyumate.performance", qos: .utility)

    // MARK: - Session Tracking

    /// Start tracking a scan session
    func startSession(id: String = UUID().uuidString) -> String {
        queue.sync {
            activeSessions[id] = Date()
        }
        return id
    }

    /// End tracking a scan session
    func endSession(
        id: String,
        cardType: CardType,
        scanMethod: CardScanMethod,
        success: Bool,
        errorType: String? = nil,
        confidence: Float? = nil
    ) {
        queue.async { [weak self] in
            guard let self = self,
                  let startTime = self.activeSessions[id] else {
                return
            }

            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            let memoryUsed = self.getCurrentMemoryUsage()

            let metric = ScanMetrics(
                cardType: cardType,
                scanMethod: scanMethod,
                startTime: startTime,
                endTime: endTime,
                duration: duration,
                memoryUsed: memoryUsed,
                success: success,
                errorType: errorType,
                confidence: confidence
            )

            self.metrics.append(metric)
            self.activeSessions.removeValue(forKey: id)

            #if DEBUG
            self.logMetric(metric)
            #endif

            // Keep only last 100 metrics
            if self.metrics.count > 100 {
                self.metrics.removeFirst(self.metrics.count - 100)
            }
        }
    }

    // MARK: - Memory Monitoring

    /// Get current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    // MARK: - Analytics

    /// Get average processing time for a card type and method
    func averageProcessingTime(cardType: CardType, method: CardScanMethod) -> TimeInterval? {
        queue.sync {
            let filtered = metrics.filter {
                $0.cardType == cardType && $0.scanMethod == method
            }

            guard !filtered.isEmpty else { return nil }

            let total = filtered.reduce(0.0) { $0 + $1.duration }
            return total / Double(filtered.count)
        }
    }

    /// Get success rate for a card type and method
    func successRate(cardType: CardType, method: CardScanMethod) -> Double? {
        queue.sync {
            let filtered = metrics.filter {
                $0.cardType == cardType && $0.scanMethod == method
            }

            guard !filtered.isEmpty else { return nil }

            let successCount = filtered.filter { $0.success }.count
            return Double(successCount) / Double(filtered.count)
        }
    }

    /// Get average OCR confidence for successful scans
    func averageConfidence(cardType: CardType) -> Float? {
        queue.sync {
            let filtered = metrics.filter {
                $0.cardType == cardType &&
                $0.scanMethod == .camera &&
                $0.success &&
                $0.confidence != nil
            }

            guard !filtered.isEmpty else { return nil }

            let total = filtered.reduce(0.0) { $0 + ($1.confidence ?? 0) }
            return total / Float(filtered.count)
        }
    }

    /// Get performance summary
    func getPerformanceSummary() -> [CardType: [CardScanMethod: (avgTime: TimeInterval, successRate: Double)]] {
        queue.sync {
            var summary: [CardType: [CardScanMethod: (avgTime: TimeInterval, successRate: Double)]] = [:]

            for cardType in CardType.allCases {
                summary[cardType] = [:]

                for method in CardScanMethod.allCases {
                    if let avgTime = averageProcessingTime(cardType: cardType, method: method),
                       let successRate = successRate(cardType: cardType, method: method) {
                        summary[cardType]?[method] = (avgTime, successRate)
                    }
                }
            }

            return summary
        }
    }

    // MARK: - Logging

    private func logMetric(_ metric: ScanMetrics) {
        let successIcon = metric.success ? "✅" : "❌"
        let methodIcon = metric.scanMethod == .nfc ? "📡" : "📷"

        print("⏱️ [Performance] \(successIcon) \(methodIcon) \(metric.cardType.displayName)")
        print("   Duration: \(metric.durationMs)ms")
        print("   Memory: \(String(format: "%.1f", metric.memoryUsedMB))MB")

        if let confidence = metric.confidence {
            print("   Confidence: \(String(format: "%.1f%%", confidence * 100))")
        }

        if let error = metric.errorType {
            print("   Error: \(error)")
        }

        // Performance warnings
        if metric.duration > 3.0 {
            print("   ⚠️ Slow processing (>3s)")
        }

        if metric.memoryUsedMB > 150 {
            print("   ⚠️ High memory usage (>150MB)")
        }
    }

    // MARK: - Clear Data

    /// Clear all metrics (for testing)
    func clearMetrics() {
        queue.sync {
            metrics.removeAll()
            activeSessions.removeAll()
        }
    }
}

// MARK: - Convenience Extensions

extension CardScanPerformanceMonitor {

    /// Track a scan operation with automatic timing
    func track<T>(
        cardType: CardType,
        scanMethod: CardScanMethod,
        operation: () async throws -> T
    ) async -> Result<T, Error> {
        let sessionId = startSession()

        do {
            let result = try await operation()
            endSession(
                id: sessionId,
                cardType: cardType,
                scanMethod: scanMethod,
                success: true
            )
            return .success(result)
        } catch {
            endSession(
                id: sessionId,
                cardType: cardType,
                scanMethod: scanMethod,
                success: false,
                errorType: String(describing: type(of: error))
            )
            return .failure(error)
        }
    }

    /// Track OCR operation with confidence
    func trackOCR<T>(
        cardType: CardType,
        operation: () async throws -> (result: T, confidence: Float)
    ) async -> Result<T, Error> {
        let sessionId = startSession()

        do {
            let (result, confidence) = try await operation()
            endSession(
                id: sessionId,
                cardType: cardType,
                scanMethod: .camera,
                success: true,
                confidence: confidence
            )
            return .success(result)
        } catch {
            endSession(
                id: sessionId,
                cardType: cardType,
                scanMethod: .camera,
                success: false,
                errorType: String(describing: type(of: error))
            )
            return .failure(error)
        }
    }
}

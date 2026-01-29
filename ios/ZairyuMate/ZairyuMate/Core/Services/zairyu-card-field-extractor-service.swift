//
//  zairyu-card-field-extractor-service.swift
//  ZairyuMate
//
//  Extracts structured fields from OCR text observations
//

import Foundation
import Vision

/// Extracts structured fields from OCR text observations
class ZairyuCardFieldExtractorService {

    /// Extract fields from front card OCR results
    func extractFrontCardFields(
        from rawFields: [OCRField]
    ) -> [OCRField] {
        var fields: [OCRField] = []

        // Convert OCRField to text lines format
        let textLines = rawFields.map { field -> (text: String, box: CGRect, confidence: Float) in
            (field.value, field.boundingBox, field.confidence)
        }
        
        #if DEBUG
        print("📄 [OCR] Found \(textLines.count) text lines on front card:")
        for (index, line) in textLines.enumerated() {
            print("  [\(index)] '\(line.text)' at y:\(String(format: "%.2f", line.box.minY)) (confidence: \(String(format: "%.2f", line.confidence)))")
        }
        #endif

        // Extract card number (12 alphanumeric chars)
        if let cardNumber = extractCardNumber(from: textLines) {
            fields.append(cardNumber)
            #if DEBUG
            print("✅ [OCR] Extracted card number: \(cardNumber.value)")
            #endif
        }

        // Extract name (uppercase alphabetic)
        if let name = extractName(from: textLines) {
            fields.append(name)
            #if DEBUG
            print("✅ [OCR] Extracted name: \(name.value)")
            #endif
        }

        // Extract dates (expiry, birth date)
        let dates = extractDates(from: textLines)
        fields.append(contentsOf: dates)
        #if DEBUG
        for date in dates {
            print("✅ [OCR] Extracted \(date.fieldName): \(date.value)")
        }
        #endif

        // Extract nationality (3-letter code)
        if let nationality = extractNationality(from: textLines) {
            fields.append(nationality)
            #if DEBUG
            print("✅ [OCR] Extracted nationality: \(nationality.value)")
            #endif
        }

        // Extract visa type
        if let visaType = extractVisaType(from: textLines) {
            fields.append(visaType)
            #if DEBUG
            print("✅ [OCR] Extracted visa type: \(visaType.value)")
            #endif
        }

        return fields
    }

    /// Extract fields from back card OCR results (address mainly)
    func extractBackCardFields(
        from rawFields: [OCRField]
    ) -> [OCRField] {
        var fields: [OCRField] = []

        // Convert OCRField to text lines format
        let textLines = rawFields.map { field -> (text: String, box: CGRect, confidence: Float) in
            (field.value, field.boundingBox, field.confidence)
        }

        // Extract address (multi-line Japanese text in upper section)
        if let address = extractAddress(from: textLines) {
            fields.append(address)
        }

        return fields
    }

    // MARK: - Field Extraction Helpers

    private func extractCardNumber(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> OCRField? {
        let pattern = #"[A-Z0-9]{12}"#

        for line in lines {
            if let match = line.text.range(of: pattern, options: .regularExpression) {
                let cardNumber = String(line.text[match])
                return OCRField(
                    fieldName: "cardNumber",
                    value: cardNumber,
                    confidence: line.confidence,
                    boundingBox: line.box
                )
            }
        }

        return nil
    }

    private func extractName(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> OCRField? {
        // Look for "氏名" label and get the text below/after it
        // Name is typically in upper portion, all caps, 2-4 words
        
        // First, try to find "氏名" label
        if let nameIndex = lines.firstIndex(where: { $0.text.contains("氏名") || $0.text.contains("Name") }) {
            let nameLabelBox = lines[nameIndex].box
            
            // Look for text near the label (below or to the right)
            // The name should be within reasonable proximity
            let nearbyLines = lines.filter { line in
                let verticalDistance = abs(line.box.minY - nameLabelBox.minY)
                let horizontalDistance = abs(line.box.minX - nameLabelBox.maxX)
                
                // Check if line is below the label (within 0.1 units) or to the right
                let isBelow = line.box.minY < nameLabelBox.minY && verticalDistance < 0.15
                let isRight = line.box.minX > nameLabelBox.maxX && verticalDistance < 0.05
                
                return (isBelow || isRight) && line.text != lines[nameIndex].text
            }
            
            // Find the line with all caps Latin text (actual name)
            let namePattern = #"^[A-Z\s]{3,50}$"#
            for line in nearbyLines {
                let cleaned = line.text.trimmingCharacters(in: .whitespaces)
                if cleaned.range(of: namePattern, options: .regularExpression) != nil,
                   !cleaned.contains("GOVERNMENT"),
                   !cleaned.contains("JAPAN") {
                    return OCRField(
                        fieldName: "name",
                        value: cleaned,
                        confidence: line.confidence,
                        boundingBox: line.box
                    )
                }
            }
        }
        
        // Fallback: Find name in upper portion, excluding government text
        let pattern = #"^[A-Z\s]{3,50}$"#
        let upperLines = lines.filter { $0.box.minY > 0.6 }

        for line in upperLines {
            let cleaned = line.text.trimmingCharacters(in: .whitespaces)
            if cleaned.range(of: pattern, options: .regularExpression) != nil,
               !cleaned.contains("GOVERNMENT"),
               !cleaned.contains("JAPAN"),
               !cleaned.contains("MINISTRY") {
                return OCRField(
                    fieldName: "name",
                    value: cleaned,
                    confidence: line.confidence,
                    boundingBox: line.box
                )
            }
        }

        return nil
    }

    private func extractDates(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> [OCRField] {
        var fields: [OCRField] = []

        // Date format: YYYY.MM.DD or Japanese era format
        let westernPattern = #"\d{4}\.\d{2}\.\d{2}"#
        
        // First pass: Look for expiry date with contextual keywords
        for (index, line) in lines.enumerated() {
            let text = line.text
            
            // Check if this line contains the expiry date context
            if text.contains("このカードは") || text.contains("まで有効") || text.contains("有効期限") || text.contains("有効") {
                // Try to find date on this line
                if let match = text.range(of: westernPattern, options: .regularExpression) {
                    let dateString = String(text[match])
                    fields.append(OCRField(
                        fieldName: "cardExpiry",
                        value: dateString,
                        confidence: line.confidence,
                        boundingBox: line.box
                    ))
                    #if DEBUG
                    print("📅 [OCR] Found expiry date with context keyword on line \(index): \(dateString)")
                    #endif
                    break
                } else {
                    // Check the next line after the keyword
                    if index + 1 < lines.count {
                        let nextLine = lines[index + 1]
                        if let match = nextLine.text.range(of: westernPattern, options: .regularExpression) {
                            let dateString = String(nextLine.text[match])
                            fields.append(OCRField(
                                fieldName: "cardExpiry",
                                value: dateString,
                                confidence: nextLine.confidence,
                                boundingBox: nextLine.box
                            ))
                            #if DEBUG
                            print("📅 [OCR] Found expiry date on next line after context: \(dateString)")
                            #endif
                            break
                        }
                    }
                }
            }
        }
        
        // Collect all dates with their positions for further analysis
        var allDatesWithPosition: [(date: String, confidence: Float, box: CGRect, isExpiry: Bool)] = []
        
        for line in lines {
            if let match = line.text.range(of: westernPattern, options: .regularExpression) {
                let dateString = String(line.text[match])
                
                // Skip if this is already extracted as expiry
                if fields.contains(where: { $0.fieldName == "cardExpiry" && $0.value == dateString }) {
                    continue
                }
                
                // Expiry date is typically at the bottom (lower y value in normalized coords)
                // Birth date is typically in the middle-upper portion
                let isLikelyExpiry = line.box.minY < 0.3 // Bottom portion of card
                
                allDatesWithPosition.append((
                    date: dateString,
                    confidence: line.confidence,
                    box: line.box,
                    isExpiry: isLikelyExpiry
                ))
                
                #if DEBUG
                print("📅 [OCR] Found date '\(dateString)' at y:\(String(format: "%.2f", line.box.minY)) (isLikelyExpiry: \(isLikelyExpiry))")
                #endif
            }
        }
        
        // Sort by position (bottom to top)
        allDatesWithPosition.sort { $0.box.minY < $1.box.minY }
        
        // If we didn't find expiry date with context, assign dates based on position
        if !fields.contains(where: { $0.fieldName == "cardExpiry" }) {
            // Look for the date at the bottom first (most likely expiry)
            if let firstDate = allDatesWithPosition.first, firstDate.isExpiry {
                fields.append(OCRField(
                    fieldName: "cardExpiry",
                    value: firstDate.date,
                    confidence: firstDate.confidence,
                    boundingBox: firstDate.box
                ))
                #if DEBUG
                print("📅 [OCR] Assigned bottom date as expiry: \(firstDate.date)")
                #endif
                
                // Remove from array so we don't process it again
                allDatesWithPosition.removeFirst()
            }
        }
        
        // Remaining dates are likely birth dates
        for dateInfo in allDatesWithPosition {
            if !fields.contains(where: { $0.fieldName == "dateOfBirth" }) {
                fields.append(OCRField(
                    fieldName: "dateOfBirth",
                    value: dateInfo.date,
                    confidence: dateInfo.confidence,
                    boundingBox: dateInfo.box
                ))
                #if DEBUG
                print("📅 [OCR] Assigned date as birth date: \(dateInfo.date)")
                #endif
            }
        }

        return fields
    }

    private func extractNationality(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> OCRField? {
        // ISO 3166-1 alpha-3 codes (e.g., VNM, USA, JPN)
        let pattern = #"\b[A-Z]{3}\b"#

        for line in lines {
            if let match = line.text.range(of: pattern, options: .regularExpression) {
                let code = String(line.text[match])

                // Validate it's a known country code (optional)
                if isValidCountryCode(code) {
                    return OCRField(
                        fieldName: "nationality",
                        value: code,
                        confidence: line.confidence,
                        boundingBox: line.box
                    )
                }
            }
        }

        return nil
    }

    private func extractVisaType(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> OCRField? {
        // Look for "在留資格" label and extract the text after/below it
        
        // First, try to find "在留資格" label
        if let visaLabelIndex = lines.firstIndex(where: { 
            $0.text.contains("在留資格") || $0.text.contains("Status of Residence")
        }) {
            let visaLabelBox = lines[visaLabelIndex].box
            
            // Check if visa type is on the same line (after the label)
            let labelText = lines[visaLabelIndex].text
            if let range = labelText.range(of: "在留資格") {
                let afterLabel = labelText[range.upperBound...].trimmingCharacters(in: .whitespaces)
                if !afterLabel.isEmpty {
                    return OCRField(
                        fieldName: "visaType",
                        value: afterLabel,
                        confidence: lines[visaLabelIndex].confidence,
                        boundingBox: visaLabelBox
                    )
                }
            }
            
            // Look for text near the label (below or to the right)
            let nearbyLines = lines.filter { line in
                let verticalDistance = abs(line.box.minY - visaLabelBox.minY)
                let horizontalDistance = abs(line.box.minX - visaLabelBox.maxX)
                
                // Check if line is below the label or to the right
                let isBelow = line.box.minY < visaLabelBox.minY && verticalDistance < 0.1
                let isRight = line.box.minX > visaLabelBox.maxX && verticalDistance < 0.05
                
                return (isBelow || isRight) && line.text != lines[visaLabelIndex].text
            }
            
            // Return the first nearby line as visa type
            if let nearestLine = nearbyLines.first {
                let cleaned = nearestLine.text.trimmingCharacters(in: .whitespaces)
                return OCRField(
                    fieldName: "visaType",
                    value: cleaned,
                    confidence: nearestLine.confidence,
                    boundingBox: nearestLine.box
                )
            }
        }
        
        // Fallback: Look for common visa types in English
        let knownTypes = [
            "Engineer", "Specialist in Humanities",
            "Designated Activities", "Student",
            "Permanent Resident", "Spouse", "Technical Intern",
            "Instructor", "Professor", "Researcher",
            "Business Manager", "Entertainer",
            "Dependent", "Long-Term Resident"
        ]

        for line in lines {
            for type in knownTypes {
                if line.text.localizedCaseInsensitiveContains(type) {
                    return OCRField(
                        fieldName: "visaType",
                        value: type,
                        confidence: line.confidence,
                        boundingBox: line.box
                    )
                }
            }
        }

        return nil
    }

    private func extractAddress(
        from lines: [(text: String, box: CGRect, confidence: Float)]
    ) -> OCRField? {
        // Address is multi-line Japanese text in upper portion of back card
        let addressLines = lines
            .filter { $0.box.minY > 0.5 } // Upper half of back card
            .sorted { $0.box.minY > $1.box.minY } // Top to bottom
            .prefix(3) // Typically 2-3 lines

        guard !addressLines.isEmpty else { return nil }

        let fullAddress = addressLines.map { $0.text }.joined(separator: " ")
        let avgConfidence = addressLines.map { $0.confidence }.reduce(0, +) / Float(addressLines.count)
        let combinedBox = addressLines.reduce(CGRect.zero) { $0.union($1.box) }

        return OCRField(
            fieldName: "address",
            value: fullAddress,
            confidence: avgConfidence,
            boundingBox: combinedBox
        )
    }

    private func isValidCountryCode(_ code: String) -> Bool {
        // Simplified validation - in production, use full ISO 3166-1 list
        let commonCodes = ["VNM", "USA", "JPN", "CHN", "KOR", "PHL", "THA", "IND"]
        return commonCodes.contains(code)
    }
}

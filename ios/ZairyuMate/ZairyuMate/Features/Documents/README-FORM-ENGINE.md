# Form Engine & PDF Generation

## Overview

The Form Engine automatically fills MOJ (Ministry of Justice) visa application forms with user profile data. It uses PDFKit to populate AcroForm fields and supports exporting flattened (non-editable) PDFs.

## Architecture

```
User Profile Data
       ↓
FormTemplateManager → Load PDF Template
       ↓
FormFieldMapping → Extract & Transform Data
       ↓
PDFFormFiller → Fill AcroForm Fields
       ↓
PDFExporter → Flatten & Export
       ↓
Share Sheet / Files App
```

## Components

### Models
- **FormType**: Enum of available forms (extension, change)
- **FormTemplate**: Template metadata and mappings
- **FormFieldMapping**: Profile property → PDF field mapping

### Services
- **FormTemplateManager**: Template loading and mapping cache
- **PDFFormFiller**: Fill PDF fields with PDFKit
- **PDFExporter**: Export and flatten PDFs
- **PDFFormIntegrationHelper**: One-stop convenience methods

### ViewModels
- **FormFillViewModel**: @Observable VM for PDF generation

### Views
- **FormSelectionView**: Choose form type
- **PDFPreviewView**: Preview filled PDF with toolbar
- **PDFKitView**: UIViewRepresentable for PDFView
- **ShareSheet**: UIActivityViewController wrapper

## Usage

### Basic Flow

```swift
// 1. User selects form type
NavigationLink {
    PDFPreviewView(profile: selectedProfile, formType: .extensionForm)
}

// 2. View model generates PDF automatically
@State private var viewModel = FormFillViewModel(profile: profile, formType: formType)

// On appear
.task {
    await viewModel.generatePDF()
}

// 3. User exports via toolbar
Menu {
    Button("Share") {
        await viewModel.exportForSharing()
        showShareSheet = true
    }
    Button("Save to Files") {
        await viewModel.saveToFiles()
    }
    Button("Print at 7-Eleven") {
        viewModel.openNetprint()
    }
}
```

### Advanced Usage

```swift
// One-stop generation and export
let helper = PDFFormIntegrationHelper.shared
let url = try await helper.generateAndExportPDF(
    profile: profile,
    formType: .extensionForm,
    flatten: true
)

// Check form availability
let available = helper.validateFormAvailability(.extensionForm)

// Get list of available forms
let forms = helper.availableFormTypes()
```

### Debug Tools

```swift
#if DEBUG
// List all fields in PDF
let fields = try helper.debugListFields(formType: .extensionForm)
print("PDF Fields: \(fields)")

// Validate mappings
let missing = try helper.debugValidateMappings(formType: .extensionForm)
if !missing.isEmpty {
    print("Missing fields: \(missing)")
}
#endif
```

## Adding New Forms

### 1. Add to FormType Enum

```swift
enum FormType: String {
    case extensionForm = "extension"
    case changeForm = "change"
    case permanentForm = "permanent"  // NEW

    var displayName: String {
        case .permanentForm: return "永住許可申請書\nPermanent Residence"
    }
}
```

### 2. Create Field Mapping

```swift
struct PermanentFormMapping {
    static let mappings: [FormFieldMapping] = [
        FormFieldMapping(pdfFieldName: "name_romaji") { $0.name },
        FormFieldMapping(pdfFieldName: "dob_year") { profile in
            guard let dob = profile.dateOfBirth else { return nil }
            return DateFormatters.year(from: dob)
        },
        // ... more fields
    ]
}
```

### 3. Update Template Manager

```swift
func getFieldMappings(for type: FormType) -> [FormFieldMapping] {
    switch type {
    case .extensionForm:
        return ExtensionFormMapping.mappings
    case .changeForm:
        return ChangeFormMapping.mappings
    case .permanentForm:
        return PermanentFormMapping.mappings  // NEW
    }
}
```

### 4. Add PDF to Bundle

- Place `permanent-form.pdf` in `Resources/Forms/`
- Add to Xcode project target

## Field Mapping Guide

### Basic Mapping

```swift
FormFieldMapping(pdfFieldName: "field_name") { profile in
    return profile.propertyName
}
```

### Date Extraction

```swift
FormFieldMapping(pdfFieldName: "dob_year") { profile in
    guard let date = profile.dateOfBirth else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter.string(from: date)
}
```

### Value Transformation

```swift
FormFieldMapping(
    pdfFieldName: "nationality",
    valueExtractor: { $0.nationality },
    transformer: { code in
        // Convert country code to name
        return countryNameMap[code] ?? code
    }
)
```

### Encrypted Fields

```swift
FormFieldMapping(pdfFieldName: "card_number") { profile in
    return profile.decryptedCardNumber
}
```

## Performance Optimization

### Current Performance
- Target: < 2 seconds
- Field caching enabled
- Async/await for background processing

### Tips
1. Cache field mappings (already implemented)
2. Use background queue for heavy operations
3. Lazy load PDF templates
4. Clean up temp files regularly

```swift
// Cleanup temp files
PDFExporter().cleanupTempFiles()
```

## Testing

### Unit Test Example

```swift
func testFormFieldMapping() async throws {
    let profile = createTestProfile()
    let mapping = ExtensionFormMapping.mappings.first!

    let value = mapping.extractValue(from: profile)
    XCTAssertEqual(value, "John Doe")
}

func testPDFGeneration() async throws {
    let helper = PDFFormIntegrationHelper.shared
    let profile = createTestProfile()

    let url = try await helper.generateAndExportPDF(
        profile: profile,
        formType: .extensionForm
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
}
```

### Manual Testing Checklist

- [ ] Generate PDF for extension form
- [ ] Generate PDF for change form
- [ ] Verify Japanese text renders correctly
- [ ] Check all fields populated
- [ ] Test share to Files app
- [ ] Test share to Mail
- [ ] Test 7-Eleven netprint app
- [ ] Measure generation time < 2s
- [ ] Verify PDF size < 2MB
- [ ] Test with profile missing optional fields
- [ ] Test with profile containing special characters

## Troubleshooting

### PDF Not Generating

1. Check template exists in bundle
2. Verify PDF has AcroForm fields
3. Check console for error messages
4. Use `debugListFields()` to inspect PDF

### Fields Not Filled

1. List actual PDF field names
2. Compare with mapping definitions
3. Update mappings if names differ
4. Check value extractors return non-nil

### Performance Issues

1. Profile query optimization
2. Reduce field mappings
3. Disable debug logging in release
4. Test on device, not simulator

### Japanese Text Issues

1. Verify PDF supports UTF-8
2. Check font embedding in PDF
3. Test with actual MOJ forms
4. Validate katakana encoding

## API Reference

### FormFillViewModel

```swift
@Observable
class FormFillViewModel {
    var filledDocument: PDFDocument?
    var exportedURL: URL?
    var isLoading: Bool
    var errorMessage: String?

    func generatePDF() async
    func exportForSharing() async
    func saveToFiles() async
    func openNetprint()
}
```

### PDFFormIntegrationHelper

```swift
class PDFFormIntegrationHelper {
    func generateAndExportPDF(profile:formType:flatten:) async throws -> URL
    func validateFormAvailability(_:) -> Bool
    func availableFormTypes() -> [FormType]
    func cleanupTempFiles()
}
```

## Security

- Sensitive fields use Keychain (decryptedCardNumber, decryptedPassportNumber)
- PDFs stored in temporary directory only
- No data sent to external services
- Share sheet uses iOS native APIs
- Temp files cleaned up automatically

## Future Enhancements

1. **Manual Field Editing**: Allow user corrections before export
2. **Form Validation**: Check required fields before generation
3. **Digital Signature**: Sign PDFs with user certificate
4. **Cloud Sync**: Backup filled forms to iCloud
5. **Form History**: Track previously generated forms
6. **Batch Export**: Generate multiple forms at once
7. **Remote Updates**: Download form templates from server
8. **OCR Integration**: Scan existing forms to prefill data

## Support

For issues or questions:
1. Check debug logs in console
2. Use debug helper methods
3. Verify PDF field names
4. Test with sample data first

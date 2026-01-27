# PDF Form Templates

This directory contains official MOJ (Ministry of Justice) visa form templates.

## Forms Required

1. **extension-form.pdf** - 在留期間更新許可申請書 (Visa Extension Application)
2. **change-form.pdf** - 在留資格変更許可申請書 (Status Change Application)

## How to Add Forms

1. Download official PDF forms from MOJ website:
   - https://www.moj.go.jp/isa/applications/procedures/index.html

2. Verify forms have AcroForm fields (fillable fields)
   - Open in Adobe Acrobat or Preview
   - Check that fields can be filled

3. Rename files to match:
   - `extension-form.pdf`
   - `change-form.pdf`

4. Place in this directory

5. Add to Xcode project:
   - Drag files into this folder in Xcode
   - Ensure "Copy items if needed" is checked
   - Target: ZairyuMate

## Field Mapping

Field names in PDF must match those defined in:
- `Core/Models/form-field-mapping.swift`

If field names differ, update the mappings accordingly.

## Testing

Use the debug `listFormFields()` method in `PDFFormFiller` to discover actual field names in the PDF.

## Notes

- Forms should be in Japanese/English bilingual format
- File size should be < 2MB each
- Forms must support Japanese text encoding (UTF-8)

## MODIFIED Requirements

### Requirement: OOB media included in messages
When an XMPP message includes an OOB (XEP-0066) media URL pointing to a supported image format, the channel SHALL download the image and include it in the message content using the `[IMAGE:/path]` marker format so it enters ZeroClaw's multimodal pipeline.

#### Scenario: Image received via OOB
- **WHEN** an XMPP message includes an OOB URL pointing to a JPEG, PNG, GIF, or WebP image
- **THEN** the image is downloaded to `/tmp/xmpp_media_<timestamp>.<ext>` and the message content includes `[IMAGE:/tmp/xmpp_media_<timestamp>.<ext>]`

#### Scenario: OOB download failure
- **WHEN** an OOB image download fails
- **THEN** the message content includes `[Attached media: <url> — download failed: <error>]` (unchanged)

#### Scenario: Non-image OOB media
- **WHEN** an OOB URL points to a PDF or unsupported format
- **THEN** the file is downloaded and included as `[Attached file: /path]` (unchanged, not routed through vision)

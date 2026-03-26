## ADDED Requirements

### Requirement: BM25 keyword search mode for memory
The memory subsystem SHALL support a BM25 keyword search mode that ranks memory entries by term frequency relevance, in addition to the default search mode.

#### Scenario: BM25 search returns relevant memories
- **WHEN** `search_mode = "bm25"` is configured in `[memory]` and a query contains specific keywords
- **THEN** memory entries containing those keywords are ranked by BM25 score and returned in descending relevance order

#### Scenario: BM25 config option in NixOS module
- **WHEN** the NixOS module generates config.toml
- **THEN** the `[memory]` section includes `search_mode` with the configured value

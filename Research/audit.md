# Audit: swift-plist

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/modularization-audit-foundations-batch-A.md (2026-03-20)

**Modularization compliance — MOD-001 through MOD-014**

**Targets**: Plist Primitives (15), Plist XML (4), Plist Binary (6), Plist (4 -- umbrella with implementation)

| Rule | Verdict | Notes |
|------|---------|-------|
| MOD-001 Core | **FAIL** | `Plist Primitives` (15 files) serves as Core but uses L1 naming (`Primitives`). At L3, should be `Plist Core`. Not published as internal-only -- it is a product. |
| MOD-002 Ext Dep Central | PASS | Plist Primitives has no external deps. Plist XML brings in XML, RFC 4648, ISO 8601 (specific to XML parsing). Plist Binary has no external deps. External deps are where they need to be. |
| MOD-003 Variant Decomp | PASS | XML and Binary are independent format variants, both depending on Plist Primitives. |
| MOD-004 Constraint Iso | N/A | No ~Copyable types. |
| MOD-005 Umbrella | **FAIL** | `Plist` (4 files) contains implementation code: `Plist.Parse.swift`, `Plist.Stream.swift`, `Plist.Parse.Accessor.swift` in addition to `exports.swift`. Auto-detection/routing logic lives here. Should be re-export-only with routing logic in a separate target. |
| MOD-006 Dep Min | PASS | Deps are minimal and justified. |
| MOD-007 Graph Shape | PASS | Max depth = 2 (Plist Primitives -> Plist XML/Binary -> Plist). |
| MOD-008 Split Decision | PASS | All targets have reasonable file counts (4-15). |
| MOD-009 Inline Variant | N/A | No inline variants. |
| MOD-010 StdLib Integration | N/A | No stdlib extensions observed. |
| MOD-011 Test Support | N/A | No test support product. Acceptable -- plist types are simple enough to construct in tests without fixtures. |
| MOD-012 Naming | **FAIL** | `Plist Primitives` uses L1 naming. At L3, should be `Plist Core`. |
| MOD-013 MARK | N/A | Only 4 source targets (below 5 threshold). |
| MOD-014 Cross-Pkg Traits | N/A | No cross-package optional integrations. |

**Detailed Findings**:

1. **F-PLIST-001** (MOD-005): The `Plist` umbrella has 3 implementation files. `Plist.Parse.swift` contains format auto-detection and routing to XML/Binary parsers. `Plist.Stream.swift` and `Plist.Parse.Accessor.swift` add streaming and accessor APIs. These should either: (a) move into Plist Primitives (if format-agnostic), or (b) become a new `Plist Routing` target.
2. **F-PLIST-002** (MOD-012): `Plist Primitives` should be `Plist Core` at L3.

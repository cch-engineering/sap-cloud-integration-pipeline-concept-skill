# Secondary Internal Study Notes

Authority: secondary. The user's original pipeline PDF and current SAP standard sources take precedence.

Available study coverage:
- Fully decoupled Step01 through Step07 responsibilities.
- Integrated async and sync architecture.
- Step01 header population and pipeline allowed headers.
- String/Binary/Alternative/Authorized User Partner Directory examples.
- Bypass receiver determination, bypass interface determination, and P2P.
- Receiver-specific queues.
- Custom pre/receiver-determination extensions.
- JMS retry and optional restart-via-data-store extension.
- Virtual Landscape through `tenantStage` and `Landscape_Stage~<Stage>`.
- Custom MPL headers and `_dc_*` dynamic-configuration headers.

Guardrails:
- Do not copy real hostnames, ports, credential aliases, client IDs, or business payloads into recommendations.
- Treat tenant-specific names as examples.
- Label study-only behavior and version-sensitive observations.
- If the actual generic iFlow ZIP is supplied, prefer observed script/router behavior over these notes, while reporting differences.

## Source-code verified facts (from deployed generic iFlow package inspection)

### Step05 — Interface Determination (PIP_05_Generic_InterfaceDetermination)

Source: Step05 IFLW Iterating Splitter and Content Modifier, verified from iFlow ZIP.

- The Binary Parameter for interface determination is read using: `pd:${header.partnerID}:interfaceDetermination_${header.SAP_ReceiverAlias}:Binary`
- Each `<Interface>` node is processed by an Iterating Splitter with XPath `/ns0:Interfaces/Interface`
- `ParallelProcessing = false` — interfaces are called **sequentially**
- `StopOnExecution = true` — a failure on one interface **stops all remaining interfaces** in the split
- Iteration order is **document order** (the sequence `<Interface>` nodes appear in the XML); `<Index>` does NOT control sort order
- After the split, a Content Modifier extracts:
  - `/Interface/Index` → header `SAP_ReceiverInterfaceIndex` (MPL monitoring only; not used for ordering)
  - `/Interface/Service` → header `SAP_OutboundProcessingEndpoint` (the ProcessDirect call target for Step07)
  - `/Interface/Name` → header `SAP_ReceiverInterface` (MPL monitoring; optional in XSLT but recommended for traceability)
- `<Index>` can technically be omitted without breaking routing, but `SAP_ReceiverInterfaceIndex` will be empty in MPL; always include it for monitoring completeness
- Always include `<Index>` starting at 1 in document order to match intended sequence

### Step02 — Alternative Partner Lookup (PIP_02_Generic_InboundProcessing)

Source: `determinePartnerID.groovy`, verified from iFlow ZIP.

- Without namespace: calls `getPartnerId(agency, "SenderInterface", iface)` → PD entry: Agency=Sender, Scheme=`SenderInterface`, Id=Interface
- With namespace: calls `getPartnerId(agency, iface, ns)` → PD entry: Agency=Sender, Scheme=Interface, Id=namespace
- Fallback (no PD entry found): Tilde PID = `agency~interface` (used when no Alternative Partner exists)

### Step02 — InboundConversionEndpoint lookup order

Source: `readInboundConversionFromPD.groovy`, verified from iFlow ZIP.

1. Checks header `customXInboundConversionEndpoint` first
2. Then checks String Parameter `InboundConversionEndpoint_<SenderAlias>` (sender-specific variant)
3. Then checks String Parameter `InboundConversionEndpoint` (general)

The sender-specific variant `InboundConversionEndpoint_<SenderAlias>` allows different Step03 endpoints per sender on the same configuration scenario PID.

### Step04 — Receiver Not Determined behavior

Source: `readReceiverNotDeterminedFromPD.groovy`, verified from iFlow ZIP.

- Reads String Parameter `ReceiverNotDeterminedType` from PD. Default if absent: `Error`
- If type is `Default`, also reads `ReceiverNotDeterminedDefault` for the fallback receiver alias
- The `<ReceiverNotDetermined><Type>` node in the receiver determination XSLT output and the PD parameter `ReceiverNotDeterminedType` may interact — validate against your deployed Step04 to confirm which takes precedence
- All three runtimes (Fully Decoupled Step04, Integrated Async, Integrated Sync) have this logic

### Bypass option — `bypassOption` property

Source: `readBypassOptionFromPD.groovy` (Step02 / integrated inbound iflow), verified from all three runtime IFLWs.

The inbound iflow reads the Partner Directory and sets an internal `bypassOption` property **before** writing to JMS (for async) or routing (for sync). This property controls whether later determination steps run. All three runtimes set it the same way.

| `bypassOption` value | Set by | Trigger condition | Effect |
|---|---|---|---|
| `p2p` | `readBypassOptionFromPD.groovy` | Both `receiverDetermination` String Parameter and `interfaceDetermination_<alias>` String Parameter found in PD | Both receiver and interface determination fully bypassed |
| `skipRcvDet` | `readBypassOptionFromPD.groovy` | Only `receiverDetermination` String Parameter found; no matching `interfaceDetermination_<alias>` String Parameter | Receiver determination bypassed; interface determination still executes (XSLT Binary Parameter or separate String Parameter) |
| `skipIfDet` | Step04 / integrated receiver determination step | Receiver alias resolved by XSLT (Binary Parameter); the determination step then sets this value internally | Receiver resolved; interface determination bypassed by the determination step itself |

### JMS header filter — headers that survive the JMS boundary

Source: JMS header filter expression in Step02 IFLW and Integrated Async IFLW, verified from ZIP. Applies to Fully Decoupled and Integrated Async only (Integrated Sync has no JMS).

Fixed system headers always preserved:
`SAP_Sender(.*)`, `SAP_Receiver(.*)`, `maxJMSRetries`, `SAP_ApplicationID`, `customX(.*)`, `testMode`, `partnerID`, `customHeaderProperties`, `dc(.*)`, `auditLogHeader`, `tenant(.*)` or `tenantStage`/`tenantStageVirtual`, `SapQualityOfService`, `SapQueueId` (async only), `SapAuthenticatedUserName`, `SAP_CreatedTime`

Custom headers beyond this list are preserved only if their names are listed in the `customHeaderProperties` header value set in Step01.

### Integrated Sync — header cleanup on response

Source: Step02_Sync IFLW DELETE Content Modifier, verified from ZIP. Applies to Integrated Sync only.

Before returning the synchronous response, the integrated sync iFlow explicitly deletes pipeline-internal headers:
`sap_receiveralias`, `partnerid`, `auditlogheader`, `sap_senderinterface`, `tenantstage`, `sap_sender`, `sap_outboundprocessingendpoint`, `dc(.*)`, `customheaderproperties`, `xsltmapping`, `sap_receiverinterfaceindex`

These headers are not visible to the synchronous caller. Generic Pipelines 1.0.6 removes the deletion of `SAP_Receiver`; do not claim that header is stripped in this version.

### Step07 — Interface split with maintained order at runtime (Sequential Multicast + Idempotent Process Call)

Source: `PIPSamplesScenario3_Step07_RCV1_InOrder` IFLW, verified from Scenario 3 sample ZIP. Applies to Fully Decoupled only.

**Why the generic Step05 iterating splitter is not sufficient:**
Step05 processes `<Interface>` nodes sequentially in document order and stops on failure. On JMS retry, Step05 replays from the first `<Interface>` node, potentially re-delivering to interfaces that already received the message in the previous attempt.

**The maintained-order pattern in Step07:**
- A **Sequential Multicast** flow step (`activityType = SequentialMulticast`) fans the message to N branches. The execution order is defined by `routingSequenceTable` (e.g., `<cell>1</cell><cell>SequenceFlow_A</cell>`, `<cell>2</cell><cell>SequenceFlow_B</cell>`).
- Each branch contains:
  1. A Local Integration Process for mapping to that interface's target format.
  2. A Content Modifier setting property `SplitMessageID` = `${header.UniqueID}_Branch<N>` (a unique per-branch, per-message ID).
  3. An **Idempotent Process Call** (`activityType = IdempotentProcessCall`, `skipOnDuplicate = true`, `sourceMessageID = ${property.SplitMessageID}`) wrapping a Local Integration Process that performs the outbound ProcessDirect call to the receiver adapter.
- On retry, the Idempotent Process Call checks whether the branch already delivered; if so, it skips it (`skipOnDuplicate = true`).
- The exception subprocess sets `SAP_MessageProcessingLogCustomStatus = RetryViaParentFlow` so the parent JMS flow triggers re-delivery.

**Step01 requirement for this pattern:**
The `UniqueID` header must be available in Step07. It is included in Step07's allowed header list. Verify that `UniqueID` is either a pipeline-standard header or added to `customHeaderProperties` in Step01.

**Step01 `customHeaderProperties` value format:**
The Scenario 3 sample uses a pipe-separated `key:value` string, for example `productId:${property.productId}|category:${property.category}|purchaseOrder:${property.purchaseOrder}`. The reviewed `addCustomHeaderProperties.groovy` also accepts a Base64-encoded JSON map, normalizes the entries, and Base64-encodes the JSON result in the header for propagation across JMS. Do not describe the format as a comma-separated list of names. In Generic Inbound 1.0.9, the IDoc Step01 custom exit runs before the add-custom-header-properties script, so the exit can set values for this map.

## Package release verification (2026-10-20)

Artifacts inspected from `Additional Reference/latest framework file/`:

| Package | Reviewed version | Changelog date |
| --- | ---: | --- |
| Generic Inbound | 1.0.9 | 13/10/2026 |
| Generic Pipelines | 1.0.7 | 20/10/2026 |
| Generic Outbound | 1.1.1 | 20/10/2026 |
| Templates | 1.2.1 | 13/10/2026 |

These are the versions in the provided 20261026 exports, not a claim that later versions are unavailable. Recheck deployed package versions before applying this guidance. Generic Pipelines 1.0.7 and Generic Outbound 1.1.1 fix a `toLowerCase()` condition issue when checking the `testMode` header.

### Generic Inbound 1.0.9

- XI and IDoc Step01 support routing messages with Exactly Once In Order to an exclusive queue or ProcessDirect endpoint. Configure String Parameter `InOrderRouteOption` on the Configuration Scenario partner ID with `ExclusiveQueue:UseSenderContextAsQueue`, `ExclusiveQueue:<queue name>`, or `ProcessDirect:<endpoint>`. Missing or invalid configuration fails with custom status `ConfigurationOptionNotSupported`; there is no default EOIO route.
- XI sender EOIO uses `SapQualityOfService=ExactlyOnceInOrder` and `SapQueueId`. IDoc sender EOIO uses `SapPlainSoapQoS` and `SapPlainSoapQueueId` derived from `ARCKEY`; the generic IDoc flow maps these to `SapQualityOfService` and `SapQueueId` for downstream handling.
- Sender-context queue routing requires a downstream exclusive queue named to match the incoming queue ID; a single consumer preserves order and JMS can retry delivery. Configured-name queue routing uses the chosen exclusive queue. ProcessDirect invokes the target synchronously, and the target flow must implement in-order processing. The receiver can optionally be specified using `receiverDetermination` or downstream header `SAP_Receiver` because normal receiver determination is bypassed.
- XI-to-XI route-through can point ProcessDirect to the generic XI Step08 outbound flow. The XI QoS and queue ID headers pass through to the receiver adapter, including dynamic queue IDs; the sender system handles restart after failure. This does not establish end-to-end EOIO support across the whole pipeline.
- XI Alternative Partner lookup using sender, interface, and namespace normalizes `/` in the interface scheme to `_`; the fixed `SenderInterface` scheme lookup already supports slash in the interface.
- Custom error pre-processing is supported before standard error handling. Step-specific custom-pre endpoints use `CustomXPreEndpoint_<Step>` before the generic endpoint.
- IDoc Step01 runs its custom exit before `addCustomHeaderProperties.groovy`, enabling values created by the custom exit to enter the custom-header map.
- Step01 receiver queue names are added to custom header attributes. The system tenant name lookup no longer relies on the unsupported Groovy environment class.

### Generic Pipelines 1.0.6

- Sender-party-specific inbound conversion lookup order: `customXInboundConversionEndpoint` header; `InboundConversionEndpoint_<SenderParty>.<SenderAlias>`; `InboundConversionEndpoint_<SenderAlias>`; general `InboundConversionEndpoint`.
- `CustomXPreEndpoint_<Step>` is checked before a header-provided generic endpoint and the generic Partner Directory `CustomXPreEndpoint` value.
- Standard error handling supports an optional custom pre-processing exit. Retry-limit comparisons use `>=` in Step02.
- Integrated Sync no longer deletes header `SAP_Receiver` before returning the response.
- `restoreMessage.groovy` fixes a type-conversion error when restoring original XML from the DLQ after conversion to a non-XML payload.

### Generic Pipelines 1.0.7

- Fixes a `toLowerCase()` condition issue while checking the `testMode` header in all flows.

### Generic Outbound 1.1.0

- Step08 XI and IDoc flows support receiver-party adapter configuration. `/` in receiver interface names must be represented as `_` in Partner Directory parameter suffixes.
- Step08 XI/IDoc supports pre-transmission custom exits with headers `customXPipelineStep=08` and `customXProtocol=xi|idoc`.
- Step06 supports global and scenario-specific post-processing; scenario-specific settings are `CustomXPostEnabled` and `CustomXPostEndpoint`. `CustomXPostEnabled` is supported for Step06 only.
- IDoc `EnableControlRecordCheck` defaults to `true`; `false` disables mandatory EDIDC-field validation in Cloud Integration.
- IDoc override field list precedence: `SAP_IDoc_EDIDC_overrideControlRecordParameters` header; interface-specific Partner Directory String Parameter `OverrideControlRecordParameters_<InterfaceSuffix>` (lowercase initial form is also read); externalized `OverrideControlRecordParameters` fallback. Field values prefer `SAP_IDoc_EDIDC_<Field>` headers, then corresponding configured defaults. Interface suffixes normalize `/` to `_`.
- Dedicated XI and IDoc Step08 Edge flows are available. Their current proxy type is Internet; OnPremise is unsupported and Manual is not yet available.
- Step06 retry-limit comparison uses `>=`; `restoreMessage.groovy` includes the XML-to-non-XML DLQ restore fix. XI/IDoc adapter routing conditions were replaced with Groovy logic.

### Generic Outbound 1.1.1

- Fixes a `toLowerCase()` condition issue while checking the `testMode` header in Step06.

### Templates 1.2.1 and related package lineage

- Custom Exit template supports Step08; Custom Error Handling template adds `customX(.*)` to its allowed headers.
- Templates 1.2.0 added an IDoc one-to-many outbound template and skip-retry Value Mapping/Partner Directory helper flows; these are included in the supplied 1.2.1 package.
- Generic Inbound 1.0.8 added flexible landscape stages for XI point-to-point bypass. Treat this as a prior-version addition included in the 1.0.9 flow lineage, not a new 1.0.9 feature.

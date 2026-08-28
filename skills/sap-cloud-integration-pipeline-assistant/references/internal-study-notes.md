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
`sap_receiveralias`, `partnerid`, `auditlogheader`, `sap_senderinterface`, `tenantstage`, `sap_sender`, `sap_receiver`, `sap_outboundprocessingendpoint`, `dc(.*)`, `customheaderproperties`, `xsltmapping`, `sap_receiverinterfaceindex`

These headers are not visible to the synchronous caller.

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

**Step01 `customHeaderProperties` value format (from Scenario 3 sample):**
The Step01 IFLW sets `customHeaderProperties` as a pipe-separated `key:value` string:
`productId:${property.productId}|category:${property.category}|purchaseOrder:${property.purchaseOrder}`
The generic `addCustomHeaderProperties.groovy` reads this and sets each key as a separate header, making them available beyond the JMS boundary.

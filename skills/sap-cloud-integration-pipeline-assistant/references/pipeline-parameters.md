# Pipeline Parameter Catalog

Always validate names against the deployed package version. The same ID may be a String Parameter in bypass mode or a Binary Parameter carrying XSLT. Never infer type from ID alone.

## Configuration scenario parameters

| ID or Pattern | Entry Type | Fully Decoupled | Integrated Async | Integrated Sync | Purpose |
|---|---|---:|---:|---:|---|
| `InboundConversionEndpoint` | String Parameter | Yes | Yes | **No** | ProcessDirect address for scenario-specific inbound conversion |
| `MaxJMSRetries` | String Parameter | Yes | Yes | No | Maximum JMS retries. PD parameter ID is `MaxJMSRetries` (PascalCase); the generic inbound iflow sets runtime header `maxJMSRetries` (camelCase). Default when absent: **5**. Read by Step02/integrated inbound only — not re-read by Step04/Step05. |
| `receiverDetermination` | String Parameter | Yes | Bypass/P2P when supported | P2P when supported | Direct receiver alias; bypasses receiver determination. Only valid as a pair with `interfaceDetermination_<alias>` String Parameters. |
| `interfaceDetermination_<ReceiverAlias>` | String Parameter | Yes, ONLY when `receiverDetermination` is also a String Parameter | Bypass/P2P when supported | P2P when supported | Direct Step07 ProcessDirect endpoint. NOT valid when `receiverDetermination` is a Binary Parameter XSLT — in that case embed interface addresses inside the receiver XSLT. |
| `receiverDetermination` | Binary Parameter, content type XSL | Yes, receiver mapping | Yes, combined receiver/interface mapping | Package-dependent | XSLT determination artifact. When used, interface information must be embedded as `<Interfaces>` within each `<Receiver>` node; no separate `interfaceDetermination_<alias>` entries exist. |
| `interfaceDetermination_<ReceiverAlias>` | Binary Parameter, content type XSL | Yes, ONLY when `receiverDetermination` is also a String Parameter | Normally combined mapping instead | No | Separate interface-determination XSLT. NOT valid alongside a Binary Parameter `receiverDetermination`. |
| `CustomXPreEnabled` | String Parameter | Yes | Yes | Verify | Enables custom pre-processing; expected boolean text |
| `CustomXPreEndpoint` | String Parameter | Yes | Yes | Verify | Custom pre-processing ProcessDirect endpoint |
| `CustomXRDEndpoint` | String Parameter | Yes | Yes | Verify | Custom receiver-determination extension endpoint |
| `ReuseXRDEndpoint` | String Parameter | Yes | Yes | Verify | Reusable receiver-determination endpoint fallback |
| `ReceiverSpecificQueue` | String Parameter, usually receiver partner | Yes | Yes | No | Receiver-specific outbound JMS queue |
| `ReceiverNotDeterminedType` | String Parameter | Yes | Yes | Yes | Controls behavior when no receiver is determined. Values: `Error` (default), `Ignore`, `Default`. Read by receiver determination logic in all runtimes. |
| `ReceiverNotDeterminedDefault` | String Parameter | Yes | Yes | Yes | Fallback receiver alias used when `ReceiverNotDeterminedType` = `Default`. Only required if that type is chosen. |
| `stageRule_<StageOrTenant>[~<ReceiverAlias>]` | String Parameter | Yes | Yes | Verify | Stage-routing rule; validate exact syntax/version |
| `landscapeStage` | String Parameter on business-system partner | Yes | Yes | Verify | Maps business system to virtual stage |

## iFlow parameters (not Partner Directory)
These are configured on the deployed generic iFlow artifacts, not in Partner Directory.

| iFlow Parameter | Present in | Purpose |
|---|---|---|
| `PipelineJMSQueuePrefix` | FD Step02, Step04, Step05; IA inbound | Prefix for all JMS queue names. Fixed suffixes: Q01 (inbound), Q02 (receiver-specific path), Q03 (Step04 input), Q04 (Step05 input), Q01_DLQ (dead letter). |
| `CustomXPreGlobal_Enabled` | All five generic iFlows | Enables global-level custom pre-processing before scenario-specific logic. |
| `CustomXPreGlobal_Endpoint` | All five generic iFlows | ProcessDirect address for global custom pre-processing. |

## Landscape entries

| Object | Entry Type | Location | Purpose |
|---|---|---|---|
| `SAP_Integration_Suite_Landscape` | Partner ID containing String Parameters | Partner Directory > String Parameters | Tenant name to landscape-stage mapping |
| `Landscape_Stage~<Stage>` | Partner ID containing Authorized User(s) | Partner Directory > Authorized Users | Authenticated client/user to virtual stage |
| Sender/interface to scenario PID | Alternative Partner | Partner Directory > Alternative Partners | Determines configuration scenario |
| Business-system actual name to alias | Alternative Partner | Partner Directory > Alternative Partners | Stage-aware sender/receiver abstraction |

## Simple point-to-point configuration scenario

Use one PID when business-component abstraction is not needed:
1. Alternative Partner: Agency=`<Sender>`, Scheme=`SenderInterface`, ID=`<SenderInterface>`.
2. String Parameter: `MaxJMSRetries`.
3. String Parameter: `receiverDetermination` = `<ReceiverAlias>`.
4. String Parameter: `interfaceDetermination_<ReceiverAlias>` = `<Step07ProcessDirectAddress>`.

## Headers set by Step01 that generic flows consume

| Header | Survives JMS | Consumed by | Notes |
|---|---|---|---|
| `customHeaderProperties` | Yes (FD + IA) | Step02 `addCustomHeaderProperties.groovy` | Comma-separated list of custom header names to preserve across JMS in addition to the fixed system header filter |
| `testMode` | Yes (FD + IA) | All generic iFlows | When `'true'`, MPL custom status is set to `ErrorInTestMode`; no outbound call is made |
| `_dc_*` | Yes (FD + IA) | Step07 and outbound adapters | Dynamic configuration headers; always in the JMS filter |
| `partnerID` | Yes (FD + IA) | All generic iFlows for PD lookups | Survives JMS; do not set unless deliberately overriding the Alternative Partner lookup |

## Output rule
For every parameter, print Partner ID, entry type, location, ID, value, purpose, optionality, architecture applicability, and consumer.

# Pipeline Parameter Catalog

Always validate names against the deployed package version. The same ID may be a String Parameter in bypass mode or a Binary Parameter carrying XSLT. Never infer type from ID alone.

## Configuration scenario parameters

| ID or Pattern | Entry Type | Fully Decoupled | Integrated Async | Integrated Sync | Purpose |
|---|---|---:|---:|---:|---|
| `InboundConversionEndpoint` | String Parameter | Yes | Yes | **No** | ProcessDirect address for scenario-specific inbound conversion |
| `InboundConversionEndpoint_<SenderParty>.<SenderAlias>` | String Parameter | Yes | Yes | Verify | Sender-party-specific inbound conversion endpoint. Checked before `InboundConversionEndpoint_<SenderAlias>` and the general `InboundConversionEndpoint` in Generic Pipelines 1.0.6. |
| `MaxJMSRetries` | String Parameter | Yes | Yes | No | Maximum JMS retries. PD parameter ID is `MaxJMSRetries` (PascalCase); the generic inbound iflow sets runtime header `maxJMSRetries` (camelCase). Default when absent: **5**. Read by Step02/integrated inbound only — not re-read by Step04/Step05. |
| `receiverDetermination` | String Parameter | Yes | Bypass/P2P when supported | P2P when supported | Direct receiver alias; bypasses receiver determination. Only valid as a pair with `interfaceDetermination_<alias>` String Parameters. |
| `interfaceDetermination_<ReceiverAlias>` | String Parameter | Yes, ONLY when `receiverDetermination` is also a String Parameter | Bypass/P2P when supported | P2P when supported | Direct Step07 ProcessDirect endpoint. NOT valid when `receiverDetermination` is a Binary Parameter XSLT — in that case embed interface addresses inside the receiver XSLT. |
| `receiverDetermination` | Binary Parameter, content type XSL | Yes, receiver mapping | Yes, combined receiver/interface mapping | Package-dependent | XSLT determination artifact. When used, interface information must be embedded as `<Interfaces>` within each `<Receiver>` node; no separate `interfaceDetermination_<alias>` entries exist. |
| `interfaceDetermination_<ReceiverAlias>` | Binary Parameter, content type XSL | Yes, ONLY when `receiverDetermination` is also a String Parameter | Normally combined mapping instead | No | Separate interface-determination XSLT. NOT valid alongside a Binary Parameter `receiverDetermination`. |
| `CustomXPreEnabled` | String Parameter | Yes | Yes | Verify | Enables custom pre-processing; expected boolean text |
| `CustomXPreEndpoint` / `CustomXPreEndpoint_<Step>` | String Parameter | Yes | Yes | Verify | Custom pre-processing endpoint. The step-specific PD parameter is checked before the generic endpoint; e.g. `CustomXPreEndpoint_08` for Step08. |
| `CustomXPostEnabled`, `CustomXPostEndpoint` | String Parameters | Yes | Yes | No | Scenario-specific custom post-processing after Step06 outbound dispatch in Generic Outbound 1.1.0. This release supports post-processing only at Step06. |
| `InOrderRouteOption` | String Parameter | XI/IDoc Step01 only | No | No | EOIO route for Generic Inbound 1.0.9: `exclusivequeue:<queue>`, `exclusivequeue:senderContext`, or `processdirect:<endpoint>`. Missing/invalid values use the default EOIO route. |
| `OverrideControlRecordParameters_<InterfaceSuffix>` | String Parameter | IDoc Step08 | IDoc Step08 | No | Comma-separated EDIDC fields to override for the selected interface. Use `/` as `_` in the suffix. A scenario header can override this list. |
| `CustomXIDEndpoint` | String Parameter | Yes | No | No | ProcessDirect address for custom interface-determination extension. When present, Step05 calls this endpoint as the interface-determination extension point. Read by `readCustomInterfaceDeterminationFromPD.groovy` in Step05. |
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
| `PipelineJMSQueueSuffix` | Generic Outbound Step06 | Appended after fixed `Q04` to build the receiver-specific outbound queue; Step06 DLQ appends `_DLQ`. This is an externalized iFlow parameter, not a Partner Directory entry. |
| `CustomXPreGlobal_Enabled` | All five generic iFlows | Enables global-level custom pre-processing before scenario-specific logic. |
| `CustomXPreGlobal_Endpoint` | All five generic iFlows | ProcessDirect address for global custom pre-processing. |
| `CustomXErrorPre_Enabled` | Generic flows with custom error pre-processing | Enables a custom error pre-processing flow before standard error handling. This is an externalized iFlow parameter, not a Partner Directory parameter. |
| `CustomXErrorPre_Endpoint` | Generic flows with custom error pre-processing | ProcessDirect address for custom error pre-processing; externalized iFlow parameter, not a Partner Directory parameter. |
| `EnableControlRecordCheck` | Generic Outbound Step08 IDoc | Default `true`; set `false` to disable the flow's mandatory EDIDC-field check and defer validation to the backend. |
| `OverrideControlRecordParameters` | Generic Outbound Step08 IDoc | Fallback comma-separated list of EDIDC fields to override. Scenario-specific header or Partner Directory values take precedence. |
| `CustomXPostGlobal_Enabled`, `CustomXPostGlobal_Endpoint` | Generic Outbound Step06 | Global post-processing after outbound dispatch. Scenario-specific post-processing uses Partner Directory `CustomXPostEnabled` and `CustomXPostEndpoint`; Step06 only in Generic Outbound 1.1.0. |

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
| `customHeaderProperties` | Yes (FD + IA) | Step02 `addCustomHeaderProperties.groovy` | Reviewed helper accepts pipe-delimited `name:value` pairs or a Base64-encoded JSON map; it normalizes and Base64-encodes the result for JMS propagation. Not a comma-separated list of names. |
| `testMode` | Yes (FD + IA) | All generic iFlows | When `'true'`, MPL custom status is set to `ErrorInTestMode`; no outbound call is made |
| `_dc_*` | Yes (FD + IA) | Step07 and outbound adapters | Dynamic configuration headers; always in the JMS filter |
| `partnerID` | Yes (FD + IA) | All generic iFlows for PD lookups | Survives JMS; do not set unless deliberately overriding the Alternative Partner lookup |

## Parameter presentation fields

Each parameter record includes Partner ID, entry type, location, ID, value, purpose, optionality, architecture applicability, and consumer.

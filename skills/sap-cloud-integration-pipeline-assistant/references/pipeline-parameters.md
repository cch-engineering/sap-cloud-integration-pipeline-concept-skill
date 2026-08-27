# Pipeline Parameter Catalog

Always validate names against the deployed package version. The same ID may be a String Parameter in bypass mode or a Binary Parameter carrying XSLT. Never infer type from ID alone.

## Configuration scenario parameters

| ID or Pattern | Entry Type | Fully Decoupled | Integrated Async | Integrated Sync | Purpose |
|---|---|---:|---:|---:|---|
| `InboundConversionEndpoint` | String Parameter | Yes | Yes | Package-dependent | ProcessDirect address for scenario-specific inbound conversion |
| `MaxJMSRetries` | String Parameter | Yes | Yes | No async JMS assumption | Maximum JMS retries when supported |
| `receiverDetermination` | String Parameter | Yes | Bypass/P2P when supported | P2P when supported | Direct receiver alias; bypasses receiver determination. Only valid as a pair with `interfaceDetermination_<alias>` String Parameters. |
| `interfaceDetermination_<ReceiverAlias>` | String Parameter | Yes, ONLY when `receiverDetermination` is also a String Parameter | Bypass/P2P when supported | P2P when supported | Direct Step07 ProcessDirect endpoint. NOT valid when `receiverDetermination` is a Binary Parameter XSLT — in that case embed interface addresses inside the receiver XSLT. |
| `receiverDetermination` | Binary Parameter, content type XSL | Yes, receiver mapping | Yes, combined receiver/interface mapping | Package-dependent | XSLT determination artifact. When used, interface information must be embedded as `<Interfaces>` within each `<Receiver>` node; no separate `interfaceDetermination_<alias>` entries exist. |
| `interfaceDetermination_<ReceiverAlias>` | Binary Parameter, content type XSL | Yes, ONLY when `receiverDetermination` is also a String Parameter | Normally combined mapping instead | No | Separate interface-determination XSLT. NOT valid alongside a Binary Parameter `receiverDetermination`. |
| `CustomXPreEnabled` | String Parameter | Yes | Yes | Verify | Enables custom pre-processing; expected boolean text |
| `CustomXPreEndpoint` | String Parameter | Yes | Yes | Verify | Custom pre-processing ProcessDirect endpoint |
| `CustomXRDEndpoint` | String Parameter | Yes | Yes | Verify | Custom receiver-determination extension endpoint |
| `ReuseXRDEndpoint` | String Parameter | Yes | Yes | Verify | Reusable receiver-determination endpoint fallback |
| `ReceiverSpecificQueue` | String Parameter, usually receiver partner | Yes | Yes | No | Receiver-specific outbound JMS queue |
| `stageRule_<StageOrTenant>[~<ReceiverAlias>]` | String Parameter | Yes | Yes | Verify | Stage-routing rule; validate exact syntax/version |
| `landscapeStage` | String Parameter on business-system partner | Yes | Yes | Verify | Maps business system to virtual stage |

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

## Output rule
For every parameter, print Partner ID, entry type, location, ID, value, purpose, optionality, architecture applicability, and consumer.

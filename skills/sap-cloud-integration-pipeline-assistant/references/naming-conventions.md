# Pipeline Naming, Parties, and Character Recommendations

Sources: [SAP Community: Naming Conventions](https://community.sap.com/t5/integration-blog-posts/best-practices-pipeline-for-cloud-integration-naming-conventions/ba-p/14389443), [SAP Community: How to Deal with Slash in the Interface Name](https://community.sap.com/t5/integration-blog-posts/best-practices-pipeline-for-cloud-integration-how-to-deal-with-slash-in-the/ba-p/14504769), and [SAP Community: Working with Parties](https://community.sap.com/t5/integration-blog-posts/best-practices-pipeline-for-cloud-integration-working-with-parties/ba-p/14508402). These articles provide recommendations, not binding SAP requirements. Adapt them to local policies and validate package names, parameters, queue behavior, and endpoints against the deployed Pipeline version.

## Partner IDs

Partner Directory partner IDs can represent different roles:

| Role | Meaning | Suggested prefix |
| --- | --- | --- |
| Configuration Scenario | Scenario-level configuration and message behavior | `CS_` |
| System Alias or Business Component | Landscape-independent communication component | `BC_` |
| Business System | Landscape-dependent system name; use the actual system name where required | Existing system convention, or `BS_` |
| Party Alias | IDoc partner identity for partner types other than `LS` | `PRTY_` |

Treat system aliases and business components consistently when a component may later become a landscape-specific business system. A business system can map to a system alias through an Alternative Partner entry on the system-alias partner. Do not rename actual landscape system identifiers solely to match a suggested prefix.

## Party-aware Scenarios

For generic sender/receiver party scenarios, represent the party and system together as `<Party>.<SystemName>` (period separator), for example `BuyerA.BC_Sender1`. Use the combined value consistently; do not treat the party as a replacement for the system or alias.

### Sender and Configuration Scenario

- Set scenario-specific `SAP_Sender` to `<SenderParty>.<SenderSystem>` when the sender has a party. Generic XI inbound derives this combination from adapter headers `SapSenderParty` and `SapSenderService`; other sender flows must provide the combined sender value as appropriate.
- The Alternative Partner Agency that resolves the Configuration Scenario uses `<SenderParty>.<SenderSystemAlias>`. In a staged landscape, first map the actual sender business-system name to the stable system alias for that stage; then use the party plus alias to resolve the scenario.
- Keep the normal Alternative Partner Scheme/Id rules for the interface. Without namespace, use Scheme `SenderInterface` and the actual interface name as Id. With namespace, use the interface name as Scheme and namespace as Id, subject to slash normalization below.
- Sender-specific inbound conversion can use `InboundConversionEndpoint_<SenderParty>.<SenderSystemAlias>` as the String Parameter ID suffix. The deployed `readInboundConversionFromPD` lookup also accepts `customXInboundConversionEndpoint` as a higher-priority header override; see `SKILL.md` and `pipeline-parameters.md` for the full precedence.

### Receiver Determination and Adapter Parameters

- In receiver-determination XSLT, represent a party receiver's Service as `<ReceiverParty>.<ReceiverSystemAlias>`. Prefer the alias in the XSLT when stages map that alias to different actual system names, so the mapping can be reused across stages.
- For point-to-point bypass, the `receiverDetermination` String Parameter value is the combined receiver party and system/alias, not just the system name.
- For Partner Directory settings on the Configuration Scenario partner, suffix parameter IDs with the combined party and system alias; append the receiver interface too when that parameter is interface-specific. For example: `InterfaceNameDetermination_<ReceiverParty>.<ReceiverSystemAlias>` and `XIAuthenticationType_<ReceiverParty>.<ReceiverSystemAlias>_<ReceiverInterface>`.
- If maintaining party-specific settings under a separate party partner ID, use the party name for that partner ID (a `PRTY_` prefix is a naming recommendation). For these entries, suffix system-specific parameters with the actual receiver business-system name, not the alias, for example `XIEndpoint_<ActualBusinessSystem>`.
- Without landscape staging, a business component can be used directly as the receiver system component; apply the corresponding party/system suffix rules using that business component name.

When parties are present, generic flows can derive `SAP_SenderParty` and `SAP_ReceiverParty` from the combined sender/receiver values and expose `SenderParty`, `SenderSystem`, `ReceiverParty`, and `ReceiverSystem` in MPL custom-header properties. Treat these as derived monitoring values unless the deployed flow confirms otherwise; do not incorrectly require Step01 to set all of them.

This generic party convention does not replace IDoc-specific partner-type handling. For IDoc inbound parties where partner type is not `LS`, consult the dedicated enhanced IDoc inbound guidance and verify the current generic inbound flow behavior.

## Restricted Characters in Interface Names

Partner Directory has field-specific character restrictions. Do not replace every slash indiscriminately:

- For an inbound XI sender with a namespace, Generic Inbound 1.0.9 normalizes every `&`, `%`, and `/` in the interface name to `_` when it builds the Alternative Partner Scheme or fallback partner ID. Configure the Alternative Partner Scheme with the same `[&%/]` normalization.
- For outbound XI/IDoc interface-specific Partner Directory String Parameter IDs, the reviewed Step08 scripts normalize `/` to `_` in the interface suffix. Do not assume the same `&` or `%` normalization for those outbound suffixes without verifying the deployed script.
- Alternative Partner Id and String Parameter Value preserve the original interface name where that field supports it; do not normalize it merely because a different lookup key is restricted.
- Inbound without a namespace uses constant Scheme `SenderInterface` and the interface name in Alternative Partner Id, so preserve `/` in the Id.
- Inbound with a namespace uses the interface name as Scheme and namespace as Id; replace `&`, `%`, and `/` with `_` in the Scheme only.
- For outbound configuration, normalize `/` only when the receiver interface is part of a Partner Directory String Parameter ID suffix. Keep the actual interface name in runtime headers and in fields/values that support `/`; message-header and externalized-parameter configuration does not need the Partner Directory ID substitution.

The sender interface may therefore remain slash-containing at runtime and in Partner Directory Id/value fields even when a lookup key uses the underscore-normalized form. Confirm the exact lookup construction in the deployed package version.

## Scenario Flow Names and Endpoints

The migration-tool convention is a useful starting point for scenario-specific flows:

```text
Flow:     <scenario>_PIP<step>_<description>[_<party>][_<system>][_IFIndex_<index>]
Endpoint: /<scenario>/pip<step>[/<party>][/<system>][/IFIndex<index>]
```

`<scenario>` is the Configuration Scenario partner ID. `PIP` may be omitted, and the step number identifies the pipeline step; not every message traverses every step. Include party/system identifiers when useful for the flow's role and receiver interface index only for scenario-specific outbound flows.

| Flow purpose | Suggested flow name | Suggested ProcessDirect endpoint |
| --- | --- | --- |
| Inbound processing | `<scenario>_PIP01_InboundProcessing` | Adapter entry point; no general endpoint template specified here |
| Wildcard-sender inbound processing | `<scenario>_PIP01_InboundProcessing[_<party>]_<system>` | Adapter entry point |
| Inbound conversion | `<scenario>_PIP03_InboundConversion` | `/<scenario>/pip03` |
| Sender-specific inbound conversion | `<scenario>_PIP03_InboundConversion[_<party>]_<system>` | `/<scenario>/pip03[/<party>]/<system>` |
| Outbound processing | `<scenario>_PIP07_OutboundProcessing[_<party>]_<system>_IFIndex_<index>` | `/<scenario>/pip07[/<party>]/<system>/IFIndex<index>` |
| Custom receiver determination | `<scenario>_PIP04_ReceiverDetermination` | `/<scenario>/pip04/customXRD` |

Use a distinct outbound flow and `IFIndex` for each receiver interface. The interface name is not a reliable discriminator when the same interface name can select different mappings. Number indexes consistently, normally starting at 1. The index identifies the outbound interface/endpoint; it does not sort Step05's iterating splitter, whose execution follows the `<Interface>` nodes' document order.

When copying scenario-specific template flows, retain their allowed-header list and exception subprocess unless the deployed template/version requires otherwise. Update copied flow metadata descriptions so they describe the scenario flow rather than the template.

## Generic Packages and Pipeline Prefixes

For another pipeline, the cited guidance recommends copying the Generic Inbound, Generic Pipelines, and Generic Outbound packages from the tenant's Discovery area into Design, then configuring the pipeline prefix on the copied generic flows. A suffix distinguishes copied package and flow IDs; copying rather than overwriting the delivered package is intended to keep the original package eligible for SAP updates. Confirm the package split and available flows for the installed version before applying this recipe.

Use the same or a similar value for the package suffix and pipeline prefix where character constraints permit. In the cited guidance:

- Package suffix characters: `[A-Za-z0-9.]`
- JMS queue characters: `[A-Za-z0-9_]`
- Total JMS queue name: at most 80 characters
- Async pipeline prefix: contributes to JMS queue names.
- Sync pipeline prefix: determines the synchronous pipeline step's ProcessDirect endpoint.

For example, package suffix `ORG.ABC` may pair with queue-compatible prefix `ORG_ABC`. Count the complete queue name, including its fixed portion and any configured suffix, against the 80-character limit.

Dedicated inbound or outbound channels can use copied Generic Inbound or Generic Outbound packages. A business-system alias may be used in the package suffix, optionally with a `BC` marker and a pipeline identifier. For the receiver-specific queue option described for Pipeline v2 Generic Step06, the queue is built from the pipeline prefix, fixed `Q04`, and configured suffix (for example, a sanitized receiver alias). This is version/flow-specific: the generic queue table and queue ownership can differ by package version, so verify the deployed Step06 parameter and actual queue construction before configuring it. Do not assume that a suffix applies to every queue or generic step.

## Source and Applicability

These are non-binding SAP Community recommendations. They complement, but do not replace, SAP Help, deployed package documentation, and the existing Partner Directory, queue, and routing rules. When guidance conflicts with an inspected package or higher-priority current SAP documentation, report the conflict and follow the applicable source precedence in `SKILL.md`.

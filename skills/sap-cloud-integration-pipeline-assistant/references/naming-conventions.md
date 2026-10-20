# Pipeline Naming and Package Setup Recommendations

Source: [SAP Community: Best Practices Pipeline for Cloud Integration: Naming Conventions](https://community.sap.com/t5/integration-blog-posts/best-practices-pipeline-for-cloud-integration-naming-conventions/ba-p/14389443). The article presents recommendations, not binding SAP requirements. Adapt them to local policies and validate package names, parameters, queue behavior, and endpoints against the deployed Pipeline version.

## Partner IDs

Partner Directory partner IDs can represent different roles:

| Role | Meaning | Suggested prefix |
| --- | --- | --- |
| Configuration Scenario | Scenario-level configuration and message behavior | `CS_` |
| System Alias or Business Component | Landscape-independent communication component | `BC_` |
| Business System | Landscape-dependent system name; use the actual system name where required | Existing system convention, or `BS_` |
| Party Alias | IDoc partner identity for partner types other than `LS` | `PRTY_` |

Treat system aliases and business components consistently when a component may later become a landscape-specific business system. A business system can map to a system alias through an Alternative Partner entry on the system-alias partner. Do not rename actual landscape system identifiers solely to match a suggested prefix.

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

This is non-binding naming guidance based on the SAP Community article cited above. It complements, but does not replace, the deployed package documentation and the existing Partner Directory, queue, and routing rules. When guidance conflicts with an inspected package or higher-priority current SAP documentation, report the conflict and follow the applicable source precedence in `SKILL.md`.

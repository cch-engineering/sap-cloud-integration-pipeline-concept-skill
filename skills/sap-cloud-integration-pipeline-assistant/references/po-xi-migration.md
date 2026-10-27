# Migrating a PO XI Scenario to the Pipeline Approach

This is an optional migration reference for users migrating an SAP Process Orchestration XI Integrated Configuration Object to Cloud Integration using the Pipeline approach. The skill's primary purpose remains designing and configuring new Pipeline scenarios. This example is specific to a point-to-point XI sender/receiver scenario; do not apply its manual steps unchanged to IDoc, non-XI, or different routing patterns.

Source: [SAP Community: Migrating an SAP Process Orchestration XI Scenario to Cloud Integration Using the Pipeline Approach](https://community.sap.com/t5/integration-blog-posts/migrating-an-sap-process-orchestration-xi-scenario-to-cloud-integration/ba-p/14452326). The article's exact migration-tool behavior and flow/template versions are time-sensitive; inspect current generated artifacts and deployed package versions before applying the procedure.

## Prerequisites

The article's example uses the Integrated Messaging Runtime Asynchronous. Copy the Pipeline packages into the tenant's Design area and deploy the relevant generic artifacts:

- Generic Inbound: `Pipeline v2 Generic Step01 - Inbound Processing for XI`
- Generic Pipelines: `Pipeline v2 Generic Step02 - Integrated Messaging Runtime Async`
- Generic Outbound: `Pipeline v2 Generic Step06 - Outbound Processing` and `Pipeline v2 Generic Step08 - Outbound Processing for XI`
- Templates: `Pipeline v2 - Script Collection`

Use the Cloud Integration migration wizard on the PO integration package, select the source Integrated Configuration Object, choose the Pipeline approach, review/confirm mappings, set the Configuration Scenario name and sender component, then run migration. Review the success report and generated flow/Partner Directory inventory; generated artifacts are a starting point and may need manual changes.

## XI Sender Refinement

For the article's XI sender scenario, the generated scenario-specific inbound-processing flow is not needed when the generic XI inbound flow is used as the common entry point. The generic XI inbound flow supports both asynchronous and synchronous XI inbound scenarios and provides idempotent-process-call handling for duplicate messages.

Before removing the generated inbound flow, verify that no other scenario or artifact references it. Route the sender to the deployed generic XI inbound entry point and preserve any scenario-specific behavior that is not covered by the generic flow.

## XI Receiver Refinement

The migration tool does not automatically connect the generated scenario-specific outbound flow to the reusable generic XI Step08 flow. Use the matching `Pipeline v2 Template Step07 - Outbound Processing Point-to-Point to Generic XI Outbound` as the reference. In the generated Step07 flow:

1. Keep scenario-specific mapping/transformation logic.
2. Replace the XI receiver adapter with a Request Reply call through a ProcessDirect receiver adapter to the deployed generic XI Step08 endpoint (the package default is `/generic/step08/xi`; verify the deployed value).
3. If using reusable scripts from the template, add the `Pipeline v2 - Script Collection` reference.
4. Check the generated flow's Allowed Headers. Add `SapQualityOfService` only if it is missing and the header must reach the generic XI outbound flow.
5. Optional template steps can add XI message IDs to MPL custom header properties; delivery does not depend on those optional logging steps.

## Partner Directory Review

The migration tool creates the initial Configuration Scenario partner and Alternative Partner from the selected sender component and source interface/namespace. Verify the agency, scheme, identifier, and namespace against the Step01 lookup form in the deployed package.

For the article's point-to-point case, generated String Parameters include `receiverDetermination` and `interfaceDetermination_<ReceiverAlias>`. Verify that the endpoint value matches the adjusted scenario-specific Step07 ProcessDirect endpoint.

For generic XI outbound interface determination, add the scenario-level String Parameters required by the receiver adapter, such as `InterfaceNameDetermination_<ReceiverAlias>` and `InterfaceNamespaceDetermination_<ReceiverInterface>`, when applicable. Create or configure the receiver partner (or receiver business-system alias for landscape staging) with the required XI connection settings, for example `XIEndpoint`, `XICredentialName`, `XIAuthenticationType`, and `XIProxyType`. Exact keys, suffixes, and partner ownership depend on the deployed Generic Outbound version and landscape; consult SAP Help and `references/pipeline-parameters.md` rather than copying illustrative names blindly.

## Verification

- Confirm the generic XI Step01 flow receives the XI message and determines the expected Configuration Scenario PID.
- Verify `receiverDetermination` and `interfaceDetermination_<ReceiverAlias>` resolve the intended receiver and adjusted Step07 endpoint.
- Confirm the adjusted Step07 flow calls the generic XI Step08 endpoint and retains required headers, including `SapQualityOfService` when relevant.
- Check that interface name/namespace determination and receiver connection settings resolve from the intended Partner Directory partners.
- Send a representative test message and verify inbound processing, Step07-to-Step08 forwarding, receiver delivery, message status, and MPL details.

For other migration sources, protocols, runtimes, or patterns, use this as a verification checklist only. Re-derive the architecture and Partner Directory design from the actual source scenario and deployed Pipeline package.

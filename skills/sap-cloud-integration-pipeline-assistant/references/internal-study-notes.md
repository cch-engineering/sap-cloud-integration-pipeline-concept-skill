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

# Virtual Landscape Guidance

## Discovery
Virtual Landscape is relevant when one Cloud Integration tenant serves multiple backend stages or tenant and backend-stage topologies do not map 1:1.

## Option 1: `tenantStage` header
- Step01 sets header `tenantStage` explicitly, preferably from an externalized setting or trustworthy runtime context.
- Generic flows must allow and propagate `tenantStage`.
- Explain which Alternative Partner lookups use stage as Agency.
- The supplied primary/study material says explicit `tenantStage` takes precedence.
- Validate adapter/package limitations before recommending it for generic XI or IDoc inbound.

## Option 2: Authorized user
For each stage:
- Partner ID: `Landscape_Stage~DEV`, `Landscape_Stage~QAS`, etc.
- Entry type: Authorized User.
- Location: Partner Directory > Authorized Users.
- Value: unique OAuth client ID/authenticated user for that stage.
- Step01/runtime: preserve `SapAuthenticatedUserName` where needed.
- Use separate service instances/identities when unique client IDs are required.
- Not suitable where no authenticated caller context exists, such as some polling/pull scenarios.

## Tenant-name mapping
- Partner ID: `SAP_Integration_Suite_Landscape`.
- Entry type: String Parameter.
- Parameter ID: actual tenant name.
- Value: landscape-stage ID.

## Alias mapping
Use Alternative Partners to map actual business-system names to stable aliases per stage. State Agency, Scheme, Identifier, and resulting partner explicitly.

## Cross-stage recipient lists
A sender in DEV routing simultaneously to DEV and QAS receivers is not ordinary one-stage alias resolution. Treat it as explicit recipient-list/cross-stage routing. Explain how the combined XSLT names each target and how the target endpoints are resolved. Do not pretend one `tenantStage` value represents two target stages.
